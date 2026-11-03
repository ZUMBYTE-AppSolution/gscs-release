#!/usr/bin/env bash
set -euo pipefail
if [[ ${GSCS_ROLE:-master} == master && -f $GSCS_DATA/embedded-postgres.json ]];then
 ready=false
 for attempt in {1..90};do if pg_isready --host "$GSCS_DB_HOST" --port "$GSCS_DB_PORT" --username gscs --dbname gscs >/dev/null 2>&1;then ready=true;break;fi;sleep 1;done
 $ready || { printf 'Die interne Datenbank ist nicht bereit.\n' >&2;exit 1; }
fi
promotion=$GSCS_DATA/application/image-promotion.json
if [[ ! -f $GSCS_DATA/maintenance.flag || -f $promotion ]];then
 touch "$GSCS_DATA/run/adopting-image"
 if ! /opt/gscs/GSCS --adopt-image --data-root "$GSCS_DATA";then printf 'Image-Anwendung konnte noch nicht übernommen werden. Vorhandene Anwendung wird gestartet.\n' >&2;fi
 rm -f -- "$GSCS_DATA/run/adopting-image"
fi
"$GSCS_DATA/application/current/GSCS" --data-root "$GSCS_DATA" &
panel_pid=$!
printf '%s\n' "$panel_pid" > "$GSCS_DATA/run/gscs.pid"
if [[ -f $promotion ]];then
 healthy=false
 url=${GSCS_URL:-http://127.0.0.1:5080};url=${url/0.0.0.0/127.0.0.1}
 for attempt in {1..90};do
  if ! kill -0 "$panel_pid" 2>/dev/null;then break;fi
  if [[ ${GSCS_ROLE:-master} == node ]];then sleep 3;kill -0 "$panel_pid" 2>/dev/null && healthy=true;break;fi
  expected=$(jq -r .version "$promotion")
  if [[ $(curl --fail --silent --max-time 3 "$url/health" 2>/dev/null | jq -r .version) == "$expected" ]];then healthy=true;break;fi
  sleep 1
 done
 if $healthy;then mv -- "$promotion" "$GSCS_DATA/application/image-accepted-$(date +%s).json";rm -f -- "$GSCS_DATA/maintenance.flag"
 else
  kill -TERM "$panel_pid" 2>/dev/null || true;wait "$panel_pid" || true
  /opt/gscs/GSCS --rollback-image --data-root "$GSCS_DATA"
  rm -f -- "$GSCS_DATA/maintenance.flag"
  exec "$GSCS_DATA/application/current/GSCS" --data-root "$GSCS_DATA"
 fi
fi
wait "$panel_pid"
