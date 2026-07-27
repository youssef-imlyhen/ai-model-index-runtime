#!/usr/bin/env bash
set -euo pipefail
nginx -t
cd /app/.wasp/out/server
PORT="${WASP_INTERNAL_PORT:-3001}" npm run start-production &
server_pid=$!
nginx -g 'daemon off;' &
nginx_pid=$!
cleanup() {
  kill "$server_pid" "$nginx_pid" 2>/dev/null || true
  wait "$server_pid" "$nginx_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
set +e
wait -n "$server_pid" "$nginx_pid"
status=$?
set -e
exit "$status"
