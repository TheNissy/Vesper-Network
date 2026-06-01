#!/usr/bin/env bash
set -euo pipefail

DATA_ROOT="${1:-$HOME/tvesper-localnet}"

ports=(38181 38191 38201)
node_names=(node1 node2 node3)

fetch_info() {
  local rpc_port="$1"
  curl -fsS "http://127.0.0.1:${rpc_port}/get_info"
}

echo "Local testnet status"
echo "Data root: $DATA_ROOT"
echo

heights=()
hashes=()
peers=()

for i in "${!ports[@]}"; do
  port="${ports[$i]}"
  name="${node_names[$i]}"
  if ! raw="$(fetch_info "$port" 2>/dev/null)"; then
    echo "$name rpc:$port -> OFFLINE"
    heights+=("-1")
    hashes+=("offline")
    peers+=("0")
    continue
  fi

  parsed="$(printf '%s' "$raw" | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{const j=JSON.parse(d);console.log([j.height,j.target_height,j.top_block_hash,j.outgoing_connections_count,j.incoming_connections_count,j.synchronized,j.status].join("|"));});')"

  IFS='|' read -r height target hash outc incc synced status <<< "$parsed"
  echo "$name rpc:$port -> height=$height target=$target peers(out/in)=$outc/$incc synced=$synced status=$status"

  heights+=("$height")
  hashes+=("$hash")
  peers+=("$((outc + incc))")

  if [[ -f "$DATA_ROOT/$name/monerod.log" ]]; then
    tail -n 1 "$DATA_ROOT/$name/monerod.log" | sed "s/^/  log: /"
  fi

done

echo
all_same_hash=1
for h in "${hashes[@]}"; do
  if [[ "$h" == "offline" ]]; then
    all_same_hash=0
    break
  fi
  if [[ "$h" != "${hashes[0]}" ]]; then
    all_same_hash=0
    break
  fi
 done

all_online=1
for h in "${heights[@]}"; do
  if [[ "$h" == "-1" ]]; then
    all_online=0
    break
  fi
done

at_least_one_peer_each=1
for p in "${peers[@]}"; do
  if (( p < 1 )); then
    at_least_one_peer_each=0
    break
  fi
done

if (( all_online == 1 && all_same_hash == 1 && at_least_one_peer_each == 1 )); then
  echo "HEALTH: OK (all nodes online, same tip hash, each has at least one peer)"
  exit 0
fi

echo "HEALTH: WARN (check node connectivity/sync)"
exit 1
