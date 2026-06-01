#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  cat >&2 <<'USAGE'
Usage: start_lan_peer_node.sh <seed_ip:seed_p2p_port> [bin_dir] [data_dir] [p2p_bind_ip] [p2p_port] [rpc_bind_ip] [rpc_port]

Example:
  bash start_lan_peer_node.sh 192.168.1.19:38180 ~/Testnet-Vesper-Network/source/build/release/bin ~/tvesper-peer 0.0.0.0 38190 127.0.0.1 38191
USAGE
  exit 1
fi

SEED_NODE="$1"
BIN_DIR="${2:-$HOME/Testnet-Vesper-Network/source/build/release/bin}"
DATA_DIR="${3:-$HOME/tvesper-peer-node}"
P2P_BIND_IP="${4:-0.0.0.0}"
P2P_PORT="${5:-38190}"
RPC_BIND_IP="${6:-127.0.0.1}"
RPC_PORT="${7:-38191}"
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
  --rpc-bind-port "$RPC_PORT" \
  --add-exclusive-node "$SEED_NODE"
