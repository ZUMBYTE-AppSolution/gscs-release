#!/usr/bin/env bash
set -euo pipefail
umask 077
cd -- "$(dirname -- "$0")"
[[ ! -e .env ]] || { printf 'Vorhandene .env wird beibehalten. Keine Neueinrichtung.\n';exit 1; }
printf '1 Master mit Webinterface und interner Datenbank\n2 Node ohne Webinterface und Verwaltungsdatenbank\n'
read -r -p 'Rolle [1]: ' role
[[ ${role:-1} == 1 || ${role:-1} == 2 ]] || exit 2
read -r -p 'Absoluter Datenordner [/mnt/disk1/appdata/gscs]: ' root
root=${root:-/mnt/disk1/appdata/gscs}
[[ $root =~ ^/[a-zA-Z0-9_./-]+$ && $root != / && $root != *'/../'* && $root != */.. && ! -e $root ]] || { printf 'Einen neuen, absoluten Datenordner angeben.\n' >&2;exit 2; }
local_node=false
if [[ ${role:-1} == 1 ]];then
 printf '0 Vorerst ohne Nodes\n1 Lokale Gameserver\n2 Remote-Nodes später anbinden\n3 Lokale und entfernte Nodes\n'
 read -r -p 'Node-Plan [1]: ' plan
 [[ ${plan:-1} =~ ^[0-3]$ ]] || exit 2
 [[ ${plan:-1} == 1 || ${plan:-1} == 3 ]] && local_node=true
 read -r -p 'Web-Port [5080]: ' port;port=${port:-5080}
 [[ $port =~ ^[0-9]{1,5}$ && $port -ge 1 && $port -le 65535 ]] || exit 2
else
 read -r -p 'HTTPS-Adresse des Masters: ' master
 [[ $master =~ ^https://[a-zA-Z0-9.:-]+/?$ || $master =~ ^http://(127\.0\.0\.1|localhost):[0-9]+/?$ ]] || exit 2
 read -r -p 'Node-ID: ' node
 [[ $node =~ ^[a-zA-Z0-9_-]{1,100}$ ]] || exit 2
 read -r -s -p 'Registrierungsschlüssel: ' key;printf '\n'
 [[ ${#key} -ge 32 ]] || exit 2
fi
mkdir -p "$root/secrets"
printf 'GSCS_HOST_DATA=%s\nGSCS_LOCAL_NODE=%s\n' "$root" "$local_node" > .env
if [[ ${role:-1} == 1 ]];then
 for file in db_password setup_token;do openssl rand -hex 32 > "$root/secrets/$file";done
 printf 'GSCS_URL=http://0.0.0.0:%s\n' "$port" >> .env
 printf 'Datenbank: gscs\nBenutzer: gscs\nDB-Passwort: ';cat "$root/secrets/db_password"
 printf 'Einmaliger Einrichtungscode: ';cat "$root/secrets/setup_token"
 printf 'Start: docker compose up -d\nWebinterface: http://SERVER-IP:%s\n' "$port"
else
 printf '%s' "$key" > "$root/secrets/agent_key";unset key
 printf 'GSCS_MASTER_URL=%s\nGSCS_NODE_ID=%s\n' "$master" "$node" >> .env
 printf 'Start: docker compose -f compose.node.yml up -d\n'
fi
printf 'Daten: %s\nDer Master übernimmt seine Datenbankdaten automatisch.\n' "$root"
