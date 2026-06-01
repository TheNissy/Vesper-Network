#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${BIN_DIR:-${1:-$HOME/Testnet-Vesper-Network/source/build/release/bin}}"
DATA_ROOT="${DATA_ROOT:-${2:-$HOME/tvesper-localnet}}"
P2P_BIND_IP="${P2P_BIND_IP:-0.0.0.0}"
RPC_BIND_IP="${RPC_BIND_IP:-127.0.0.1}"
LOG_LEVEL="${LOG_LEVEL:-1}"
ALLOW_UNSYNC_MINING="${ALLOW_UNSYNC_MINING:-1}"

if [[ -x "$BIN_DIR/vesperd" ]]; then
  DAEMON_BIN="$BIN_DIR/vesperd"
elif [[ -x "$BIN_DIR/monerod" ]]; then
  DAEMON_BIN="$BIN_DIR/monerod"
else
  echo "vesperd/monerod not found in: $BIN_DIR" >&2
  exit 1
fi

mkdir -p "$DATA_ROOT"

start_node() {
  local name="$1"
  local p2p_port="$2"
  local rpc_port="$3"
  local zmq_port="$4"
  shift 4

  local node_dir="$DATA_ROOT/$name"
  mkdir -p "$node_dir"

  local args=(
    --testnet
    --non-interactive
    --detach
    --no-igd
    --hide-my-port
    --disable-dns-checkpoints
    --check-updates disabled
    --confirm-external-bind
    --data-dir "$node_dir"
    --log-file "$node_dir/monerod.log"
    --pidfile "$node_dir/monerod.pid"
    --log-level "$LOG_LEVEL"
    --p2p-bind-ip "$P2P_BIND_IP"
    --p2p-bind-port "$p2p_port"
    --rpc-bind-ip "$RPC_BIND_IP"
    --rpc-bind-port "$rpc_port"
    --zmq-rpc-bind-port "$zmq_port"
  )

  if [[ "$ALLOW_UNSYNC_MINING" == "1" ]]; then
    args+=(--allow-testnet-mining-without-sync)
  fi

  while [[ "$#" -gt 0 ]]; do
    args+=("$1")
    shift
  done

  "$DAEMON_BIN" "${args[@]}"
  echo "Started $name (p2p:$p2p_port rpc:$rpc_port zmq:$zmq_port)"
}

# Bootstrap node (seed)
start_node node1 38180 38181 38182

# Followers pin to bootstrap for deterministic local bootstrapping
start_node node2 38190 38191 38192 --add-exclusive-node 127.0.0.1:38180
start_node node3 38200 38201 38202 --add-exclusive-node 127.0.0.1:38180

echo

echo "All 3 testnet nodes launched."
echo "Data root: $DATA_ROOT"
echo "Use status script: $(dirname "$0")/status_local_3node_testnet.sh $DATA_ROOT"
