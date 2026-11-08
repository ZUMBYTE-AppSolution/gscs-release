#!/usr/bin/env bash
set -euo pipefail
root=${GSCS_DATA:-/var/lib/gscs}
request=$root/run/maintenance-restart.request
[[ -f $request && -n ${GSCS_CONTAINER_BOOT_ID:-} ]] || exit 0
# Old requests survive on the data volume; only the requesting boot may shut down.
if ! jq -e --arg boot "$GSCS_CONTAINER_BOOT_ID" '
 .bootId == $boot and (.runId | type == "string" and test("^[a-zA-Z0-9_-]{1,100}$"))
' "$request" >/dev/null;then exit 0;fi
[[ -f $root/maintenance.flag && $(cat "$root/maintenance.flag") == scheduled-maintenance ]] || exit 0
[[ ! -f $root/update.request && ! -f $root/run/adopting-image ]] || exit 0
printf 'Wartungsfenster: GSCS-Container wird vollständig neu gestartet.\n'
# With a mounted Docker socket, an explicit restart also works for existing
# Unraid containers which were created without a restart policy. Match the
# mount namespace before addressing any container; names/hostnames are optional.
if command -v docker >/dev/null && [[ -S /var/run/docker.sock ]];then
 namespace=$(readlink /proc/self/ns/mnt)
 candidates=$(timeout 10 docker ps --quiet --no-trunc 2>/dev/null || true)
 for candidate in $candidates;do
  [[ $candidate =~ ^[a-f0-9]{64}$ ]] || continue
  other=$(timeout 10 docker exec "$candidate" readlink /proc/self/ns/mnt 2>/dev/null || true)
  if [[ -n $namespace && $other == "$namespace" ]];then
   exec docker restart --time 150 "$candidate"
  fi
 done
fi
# Shutdown includes PostgreSQL and all container services, not just the panel.
# Docker starts the container again using restart: unless-stopped / always.
supervisorctl -c "$root/run/supervisord.conf" shutdown
