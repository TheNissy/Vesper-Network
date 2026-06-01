#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${1:-$HOME/Testnet-Vesper-Network/source/build/release/bin}"
DATA_DIR="${2:-$HOME/tvesper-seed-node}"
P2P_BIND_IP="${3:-0.0.0.0}"
P2P_PORT="${4:-38180}"
RPC_BIND_IP="${5:-127.0.0.1}"
RPC_PORT="${6:-38181}"
LOG_LEVEL="${LOG_LEVEL:-1}"

if [[ -x "$BIN_DIR/vesperd" ]]; then
  DAEMON_BIN="$BIN_DIR/vesperd"
elif [[ -x "$BIN_DIR/monerod" ]]; then
  DAEMON_BIN="$BIN_DIR/monerod"
else
  echo "vesperd/monerod not found in: $BIN_DIR" >&2
  exit 1
fi

mkdir -p "$DATA_DIR"

"$DAEMON_BIN" \
  --testnet \
  --no-igd \
  --hide-my-port \
  --disable-dns-checkpoints \
  --check-updates disabled \
  --allow-testnet-mining-without-sync \
  --confirm-external-bind \
  --data-dir "$DATA_DIR" \
  --log-level "$LOG_LEVEL" \
  --p2p-bind-ip "$P2P_BIND_IP" \
  --p2p-bind-port "$P2P_PORT" \
  --rpc-bind-ip "$RPC_BIND_IP" \
  --rpc-bind-port "$RPC_PORT"
