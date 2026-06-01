#!/usr/bin/env bash
set -euo pipefail

DATA_ROOT="${1:-$HOME/tvesper-localnet}"

stop_node() {
  local name="$1"
  local pidfile="$DATA_ROOT/$name/monerod.pid"

  if [[ ! -f "$pidfile" ]]; then
    echo "$name: no pidfile ($pidfile)"
    return
  fi

  local pid
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [[ -z "$pid" ]]; then
    echo "$name: empty pidfile"
    return
  fi

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "$name: stopped pid $pid"
  else
    echo "$name: pid $pid is not running"
  fi
}

stop_node node1
stop_node node2
stop_node node3
