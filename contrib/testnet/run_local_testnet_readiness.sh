#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 ]]; then
  cat >&2 <<'USAGE'
Usage: run_local_testnet_readiness.sh <testnet_wallet_address> [threads] [bin_dir] [data_root]

Example:
  bash run_local_testnet_readiness.sh Qkk... 2 ~/Testnet-Vesper-Network/source/build/release/bin ~/tvesper-localnet
USAGE
  exit 1
fi

MINER_ADDRESS="$1"
THREADS="${2:-2}"
BIN_DIR="${3:-$HOME/Testnet-Vesper-Network/source/build/release/bin}"
DATA_ROOT="${4:-$HOME/tvesper-localnet}"
RPC_PORT_NODE1="${RPC_PORT_NODE1:-38181}"
HEALTH_TIMEOUT_SEC="${HEALTH_TIMEOUT_SEC:-90}"
MINING_TIMEOUT_SEC="${MINING_TIMEOUT_SEC:-120}"
CLEAN_START="${CLEAN_START:-1}"

for cmd in curl node bash; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

json_field() {
  local key="$1"
  node -e '
    let input = "";
    const key = process.argv[1];
    process.stdin.on("data", c => input += c);
    process.stdin.on("end", () => {
      const obj = JSON.parse(input);
      const val = obj[key];
      if (val === undefined || val === null) return;
      if (typeof val === "object") process.stdout.write(JSON.stringify(val));
      else process.stdout.write(String(val));
    });
  ' "$key"
}

fetch_info() {
  curl -fsS "http://127.0.0.1:${RPC_PORT_NODE1}/get_info"
}

if [[ "$CLEAN_START" == "1" ]]; then
  bash "$SCRIPT_DIR/stop_local_3node_testnet.sh" "$DATA_ROOT" >/dev/null 2>&1 || true
  sleep 1
fi

BIN_DIR="$BIN_DIR" DATA_ROOT="$DATA_ROOT" ALLOW_UNSYNC_MINING=1 \
  bash "$SCRIPT_DIR/start_local_3node_testnet.sh" "$BIN_DIR" "$DATA_ROOT"

echo "Waiting for 3-node health..."
health_ok=0
status_tmp="$(mktemp)"
for ((i=1; i<=HEALTH_TIMEOUT_SEC; i++)); do
  if bash "$SCRIPT_DIR/status_local_3node_testnet.sh" "$DATA_ROOT" >"$status_tmp" 2>&1; then
    health_ok=1
    break
  fi
  sleep 1
done

echo
cat "$status_tmp" || true
rm -f "$status_tmp"
echo

mining_ok=0
if (( health_ok == 1 )); then
  before_height="$(fetch_info | json_field height)"
  if [[ -z "$before_height" ]]; then
    before_height=0
  fi

  start_raw="$(curl -fsS -X POST "http://127.0.0.1:${RPC_PORT_NODE1}/start_mining" \
    -H 'Content-Type: application/json' \
    -d "{\"miner_address\":\"${MINER_ADDRESS}\",\"threads_count\":${THREADS},\"do_background_mining\":false,\"ignore_battery\":true}")"

  mining_status="$(printf '%s' "$start_raw" | json_field status)"
  if [[ "$mining_status" != "OK" ]]; then
    echo "start_mining failed: $start_raw"
  else
    target_height=$((before_height + 2))
    for ((i=1; i<=MINING_TIMEOUT_SEC; i++)); do
      current_height="$(fetch_info | json_field height)"
      if [[ -n "$current_height" ]] && (( current_height >= target_height )); then
        mining_ok=1
        break
      fi
      sleep 1
    done
  fi

  curl -fsS -X POST "http://127.0.0.1:${RPC_PORT_NODE1}/stop_mining" \
    -H 'Content-Type: application/json' -d '{}' >/dev/null 2>&1 || true
fi

echo "Readiness checklist"
echo "- 3+ local nodes stay synced: $([[ $health_ok -eq 1 ]] && echo YES || echo NO)"
echo "- Miner can submit blocks:   $([[ $mining_ok -eq 1 ]] && echo YES || echo NO)"

if (( health_ok == 1 && mining_ok == 1 )); then
  echo
  echo "RESULT: LOCAL TESTNET READY"
  echo "Nodes are still running. Stop with:"
  echo "  bash $SCRIPT_DIR/stop_local_3node_testnet.sh $DATA_ROOT"
  exit 0
fi

echo
echo "RESULT: NOT READY (see checklist above)"
exit 1
