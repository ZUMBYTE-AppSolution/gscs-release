#!/usr/bin/env bash
set -euo pipefail
if [[ ${GSCS_ROLE:-master} == master && -f $GSCS_DATA/embedded-postgres.json ]];then
 ready=false
 for attempt in {1..90};do if pg_isready --host "$GSCS_DB_HOST" --port "$GSCS_DB_PORT" --username gscs --dbname gscs >/dev/null 2>&1;then ready=true;break;fi;sleep 1;done
 $ready || { printf 'Die interne Datenbank ist nicht bereit.\n' >&2;exit 1; }
fi
promotion=$GSCS_DATA/application/image-promotion.json
clear_image_maintenance(){ if [[ -f $GSCS_DATA/maintenance.flag ]] && [[ $(cat "$GSCS_DATA/maintenance.flag") == image-promotion ]];then rm -f -- "$GSCS_DATA/maintenance.flag";fi; }
if [[ ! -f $GSCS_DATA/maintenance.flag || -f $promotion ]];then
 touch "$GSCS_DATA/run/adopting-image"
 if ! /opt/gscs/GSCS --adopt-image --data-root "$GSCS_DATA";then
  if [[ -f $promotion ]];then printf 'Die unterbrochene Image-Aktualisierung konnte nicht sicher wiederaufgenommen werden. Programmstände und Datenbank bleiben erhalten.\n' >&2;exit 1;fi
  printf 'Image-Anwendung konnte noch nicht übernommen werden. Vorhandene Anwendung wird gestartet.\n' >&2
 fi
 rm -f -- "$GSCS_DATA/run/adopting-image"
fi
if [[ -f $promotion ]];then
 expected=$(jq -er '.version | select(type == "string")' "$promotion")
 expected_digest=$(jq -er '.manifestSha256 | select(type == "string" and test("^[a-fA-F0-9]{64}$")) | ascii_downcase' "$promotion")
fi
"$GSCS_DATA/application/current/GSCS" --data-root "$GSCS_DATA" &
panel_pid=$!
printf '%s\n' "$panel_pid" > "$GSCS_DATA/run/gscs.pid"
if [[ -f $promotion ]];then
 healthy=false
 url=${GSCS_URL:-http://127.0.0.1:5080};url=${url/0.0.0.0/127.0.0.1}
 for attempt in {1..90};do
  if ! kill -0 "$panel_pid" 2>/dev/null;then break;fi
  if [[ ${GSCS_ROLE:-master} == node ]];then
   sleep 3
   if kill -0 "$panel_pid" 2>/dev/null && [[ $(readlink -f "/proc/$panel_pid/exe") == "$(readlink -f "$GSCS_DATA/application/current/GSCS")" ]] && "$GSCS_DATA/application/current/GSCS" --verify-payload >/dev/null && [[ $(sha256sum "$GSCS_DATA/application/current/gscs-runtime.json" | cut -d' ' -f1) == "$expected_digest" ]];then healthy=true;fi
   break
  fi
  if curl --fail --silent --max-time 3 "$url/health" 2>/dev/null | jq -e --arg version "$expected" --arg digest "$expected_digest" '.version == $version and ((.runtimeManifestSha256 // "") | ascii_downcase) == $digest' >/dev/null;then healthy=true;break;fi
  sleep 1
 done
 if $healthy;then mv -- "$promotion" "$GSCS_DATA/application/image-accepted-$(date +%s).json";clear_image_maintenance
 else
  kill -TERM "$panel_pid" 2>/dev/null || true;wait "$panel_pid" || true
  /opt/gscs/GSCS --rollback-image --data-root "$GSCS_DATA"
  clear_image_maintenance
  exec "$GSCS_DATA/application/current/GSCS" --data-root "$GSCS_DATA"
 fi
fi
wait "$panel_pid"
