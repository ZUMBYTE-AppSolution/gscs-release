#!/usr/bin/env bash
set -euo pipefail
umask 077
secret=/mnt/disk1/appdata/.gscs-registry-auth/ghcr.json
# The array can start after /boot/config/go. Never create a data directory before its disk is mounted.
for attempt in {1..720};do
 if mountpoint -q /mnt/disk1 && [[ -f $secret ]];then break;fi
 sleep 5
done
[[ -f $secret ]] || { printf 'GSCS: Registry-Anmeldung wartet auf den Datenträger.\n' >&2;exit 1; }
jq -e '.username|type=="string"' "$secret" >/dev/null
jq -e '.auth|type=="string"' "$secret" >/dev/null
install -d -m 0700 /root/.docker
config=/root/.docker/config.json
work=$(mktemp /root/.docker/.gscs-auth-XXXXXX)
trap 'rm -f -- "$work"' EXIT
if [[ -f $config ]];then
 jq --slurpfile credentials "$secret" '.auths=(.auths//{}) | .auths["ghcr.io"]={auth:$credentials[0].auth}' "$config" > "$work"
else
 jq '{auths:{"ghcr.io":{auth:.auth}}}' "$secret" > "$work"
fi
chmod 0600 "$work"
mv -- "$work" "$config"
printf 'GSCS: Private GHCR-Anmeldung für Docker und Unraid wiederhergestellt.\n'
