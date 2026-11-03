#!/usr/bin/env bash
set -euo pipefail
[[ ${GSCS_MODE:-controller} == game ]] && exit 0
root=${GSCS_DATA:-/var/lib/gscs}
[[ -f $root/run/gscs.pid ]] && kill -0 "$(cat "$root/run/gscs.pid")"
[[ ${GSCS_ROLE:-master} == node ]] && exit 0
if [[ -f $root/embedded-postgres.json ]];then pg_isready --host "$root/postgres-socket" --port 5432 --username gscs --dbname gscs >/dev/null;fi
url=${GSCS_URL:-http://127.0.0.1:5080};url=${url/0.0.0.0/127.0.0.1}
curl --fail --silent --max-time 3 "$url/health" >/dev/null
