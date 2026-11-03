#!/usr/bin/env bash
set -euo pipefail
umask 077
role='';local_node='';install_root=/opt/gscs;data_root=/var/lib/gscs;listen_url=http://127.0.0.1:5080
master_url='';node_id='';agent_key_file='';package='';package_hash='';non_interactive=false
script_root=$(cd -- "$(dirname -- "$0")" && pwd)
while (($#));do
 case "$1" in
  --role) role=${2,,};shift 2;; --local-node) local_node=${2,,};shift 2;;
  --install-root) install_root=$2;shift 2;; --data-root) data_root=$2;shift 2;;
  --listen-url) listen_url=$2;shift 2;; --master-url) master_url=$2;shift 2;;
  --node-id) node_id=$2;shift 2;; --agent-key-file) agent_key_file=$2;shift 2;;
  --package) package=$2;shift 2;; --package-sha256) package_hash=$2;shift 2;;
  --non-interactive) non_interactive=true;shift;; *) printf 'Unbekannte Option: %s\n' "$1" >&2;exit 2;;
 esac
done
[[ $EUID -eq 0 ]] || { printf 'Den Installer mit sudo starten.\n' >&2;exit 1; }
[[ -d /run/systemd/system ]] || { printf 'Dieser Installer benötigt systemd. Für Unraid/Docker das Compose-Paket verwenden.\n' >&2;exit 1; }
if [[ -z $role ]];then
 $non_interactive && { printf -- '--role master oder node angeben.\n' >&2;exit 2; }
 printf '1 Masterserver (Webinterface und Datenbank)\n2 Node (nur Agent)\n';read -r -p 'Rolle: ' choice
 case "$choice" in 1) role=master;;2) role=node;;*) exit 2;;esac
fi
[[ $role == master || $role == node ]] || { printf 'Ungültige Rolle.\n' >&2;exit 2; }
if [[ $role == master && -z $local_node ]];then
 $non_interactive && { printf -- '--local-node true oder false angeben.\n' >&2;exit 2; }
 printf '0 Vorerst ohne Nodes\n1 Auch lokale Spielausführung\n2 Remote-Nodes später anbinden\n3 Lokale Ausführung und später Remote-Nodes\n';read -r -p 'Node-Plan [0]: ' choice
 case "$choice" in 1|3) local_node=true;;*) local_node=false;;esac
fi
[[ $local_node == true || $local_node == false || $role == node ]] || exit 2
case "$install_root:$data_root" in *$'\n'*|*'"'*|*'%'*) printf 'Unzulässiger Installationspfad.\n' >&2;exit 2;;esac
[[ $install_root =~ ^/[a-zA-Z0-9_./-]+$ && $data_root =~ ^/[a-zA-Z0-9_./-]+$ && $install_root != / && $data_root != / && $install_root != "$data_root" ]] || exit 2
[[ ! -e "$data_root/bootstrap.json" && ! -e "$install_root/current" ]] || { printf 'GSCS ist bereits vorhanden. update.sh verwenden.\n' >&2;exit 1; }
command -v apt-get >/dev/null || { printf 'Unterstützt werden Debian und Ubuntu. Andere Distributionen: portables Linux-Paket oder Docker.\n' >&2;exit 1; }
apt-get update -qq
apt-get install -y --no-install-recommends curl unzip openssl python3 ca-certificates libicu-dev libssl-dev zlib1g libstdc++6
arch=$(dpkg --print-architecture);case "$arch" in amd64) rid=linux-x64;apt-get install -y --no-install-recommends lib32gcc-s1 lib32stdc++6;;arm64) rid=linux-arm64;;*) printf 'Nicht unterstützte CPU.\n' >&2;exit 1;;esac
work=$(mktemp -d);chmod 700 "$work"
if [[ -z $package ]];then
 curl -fsSL https://api.github.com/repos/ZUMBYTE-AppSolution/gscs-release/releases?per_page=20 -o "$work/releases.json"
 python3 - "$work/releases.json" "$work" <<'PY'
import json,pathlib,sys,urllib.request
release=next(r for r in json.load(open(sys.argv[1])) if not r['draft'])
for name in ['gscs-manifest.json','gscs-manifest.sig']:
 url=next(a['browser_download_url'] for a in release['assets'] if a['name']==name)
 urllib.request.urlretrieve(url,pathlib.Path(sys.argv[2])/name)
PY
 openssl dgst -sha256 -verify "$script_root/release-public.pem" -signature "$work/gscs-manifest.sig" "$work/gscs-manifest.json" >/dev/null
 python3 - "$work/gscs-manifest.json" "$role" "$rid" "$work" <<'PY'
import json,pathlib,sys,urllib.request,hashlib
p=next(p for p in json.load(open(sys.argv[1]))['packages'] if p['role']==sys.argv[2] and p['rid']==sys.argv[3])
assert p['url'].startswith('https://github.com/ZUMBYTE-AppSolution/gscs-release/releases/download/')
out=pathlib.Path(sys.argv[4])/'package.zip';urllib.request.urlretrieve(p['url'],out)
assert out.stat().st_size==p['bytes'] and hashlib.sha256(out.read_bytes()).hexdigest().lower()==p['sha256'].lower()
PY
 package=$work/package.zip
else
 [[ -n $package_hash ]] || { printf 'Für ein lokales Paket --package-sha256 aus dem signierten Manifest angeben.\n' >&2;exit 2; }
 printf '%s  %s\n' "$package_hash" "$package" | sha256sum -c - >/dev/null
fi
mkdir -p "$install_root/current" "$data_root"
python3 - "$package" "$install_root/current" <<'PY'
import pathlib,zipfile,sys
root=pathlib.Path(sys.argv[2]).resolve()
with zipfile.ZipFile(sys.argv[1]) as z:
 for entry in z.infolist():
  assert (root/entry.filename).resolve().is_relative_to(root)
  assert ((entry.external_attr>>16)&0xf000)!=0xa000
 z.extractall(root)
PY
chmod 755 "$install_root/current/GSCS"
"$install_root/current/GSCS" --verify-payload
id gscs >/dev/null 2>&1 && { printf 'Das Systemkonto gscs existiert bereits. Keine Übernahme vorhandener Konten.\n' >&2;exit 1; }
useradd --system --home-dir "$data_root" --shell /usr/sbin/nologin gscs
setup_token='';db_password='';agent_key=''
if [[ $role == master ]];then
 apt-get install -y --no-install-recommends postgresql postgresql-client
 systemctl enable --now postgresql
 exists=$(runuser -u postgres -- psql -Atqc "SELECT count(*) FROM pg_roles WHERE rolname='gscs'")
 [[ $exists == 0 ]] || { printf 'Die Datenbankrolle gscs existiert bereits. Keine vorhandenen Daten werden überschrieben.\n' >&2;exit 1; }
 exists=$(runuser -u postgres -- psql -Atqc "SELECT count(*) FROM pg_database WHERE datname='gscs'")
 [[ $exists == 0 ]] || { printf 'Die Datenbank gscs existiert bereits.\n' >&2;exit 1; }
 db_password=$(openssl rand -hex 32);setup_token=$(openssl rand -hex 32)
 runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 >/dev/null <<SQL
SET log_statement='none'; SET log_min_error_statement='panic';
CREATE ROLE gscs LOGIN PASSWORD '$db_password';
CREATE DATABASE gscs OWNER gscs;
SQL
else
 if [[ -z $master_url ]];then $non_interactive && exit 2;read -r -p 'HTTPS-Adresse des Masters: ' master_url;fi
 if [[ -z $node_id ]];then $non_interactive && exit 2;read -r -p 'Node-ID aus dem Webinterface: ' node_id;fi
 if [[ -n $agent_key_file ]];then agent_key=$(cat -- "$agent_key_file");else $non_interactive && exit 2;read -r -s -p 'Registrierungsschlüssel: ' agent_key;printf '\n';fi
 [[ $node_id =~ ^[a-zA-Z0-9_-]{1,100}$ && ${#agent_key} -ge 24 ]] || exit 2
 python3 - "$master_url" <<'PY'
import sys,urllib.parse,ipaddress
u=urllib.parse.urlsplit(sys.argv[1]);assert u.scheme=='https' or u.scheme=='http' and u.hostname in ('localhost','127.0.0.1','::1')
PY
fi
export GSCS_INSTALL_ROLE=$role GSCS_INSTALL_LOCAL=${local_node:-false} GSCS_INSTALL_ROOT=$install_root GSCS_INSTALL_DATA=$data_root GSCS_INSTALL_LISTEN=$listen_url GSCS_INSTALL_DB_PASSWORD=$db_password GSCS_INSTALL_SETUP=$setup_token GSCS_INSTALL_MASTER=$master_url GSCS_INSTALL_NODE=$node_id GSCS_INSTALL_AGENT_KEY=$agent_key
python3 <<'PY'
import os,secrets,json,hashlib,pathlib
e=lambda k:os.environ.get('GSCS_INSTALL_'+k,'')
master=e('ROLE')=='master'
b=dict(installationId=secrets.token_hex(16),provider='PostgreSQL' if master else 'None',connectionString='Host=127.0.0.1;Port=5432;Database=gscs;Username=gscs;Password='+e('DB_PASSWORD') if master else '',masterKey=__import__('base64').b64encode(secrets.token_bytes(32)).decode(),setupTokenHash=hashlib.sha256(e('SETUP').encode()).hexdigest().upper() if master else '',role=e('ROLE'),enableLocalNode=e('LOCAL')=='true',dataRoot=e('DATA'),installRoot=e('ROOT'),serviceName='gscs' if master else 'gscs-node',listenUrl=e('LISTEN'),controllerUrl=e('MASTER'),nodeId=e('NODE'),agentKey=e('AGENT_KEY'))
p=pathlib.Path(e('DATA'))/'bootstrap.json';p.write_text(json.dumps(b));p.chmod(0o600)
PY
unset GSCS_INSTALL_DB_PASSWORD GSCS_INSTALL_SETUP GSCS_INSTALL_AGENT_KEY
chown -R gscs:gscs "$data_root";chmod 700 "$data_root";chmod -R a+rX "$install_root/current"
cp "$script_root/update.sh" "$install_root/update.sh";chmod 700 "$install_root/update.sh"
if [[ $role == node || $local_node == true ]];then bash "$script_root/install-runtimes.sh" "$install_root";fi
service=gscs;[[ $role == node ]] && service=gscs-node
cat > "/etc/systemd/system/$service.service" <<UNIT
[Unit]
Description=GSCS $role
After=network-online.target postgresql.service
Wants=network-online.target
[Service]
Type=notify
User=gscs
Group=gscs
Environment=DISPLAY=:99
Environment=DOTNET_ROOT=$install_root/runtimes/dotnet
Environment=GSCS_PROTON_PATH=$install_root/runtimes/proton/proton
WorkingDirectory=$install_root/current
ExecStartPre=+$install_root/current/GSCS --prepare-hardware
ExecStart=$install_root/current/GSCS --data-root $data_root
Restart=on-failure
RestartSec=10
TimeoutStopSec=90
UMask=0077
[Install]
WantedBy=multi-user.target
UNIT
cat > "/etc/systemd/system/$service-update.service" <<UNIT
[Unit]
Description=GSCS signed update
[Service]
Type=oneshot
ExecStart=$install_root/update.sh --apply-plan --install-root $install_root --data-root $data_root
TimeoutStartSec=900
UNIT
cat > "/etc/systemd/system/$service-update.path" <<UNIT
[Unit]
Description=GSCS update request
[Path]
PathExists=$data_root/update.request
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload;systemctl enable --now "$service.service" "$service-update.path"
printf '\nGSCS %s installiert.\n' "$role"
if [[ $role == master ]];then
 printf 'Webinterface: %s\nEinmaliger Einrichtungscode: %s\nDB-Host: 127.0.0.1\nDB-Port: 5432\nDatenbank: gscs\nDB-Benutzer: gscs\nDB-Passwort: %s\n' "$listen_url" "$setup_token" "$db_password"
 printf 'Die Datenbankdaten sind hinterlegt. Im Webinterface den Administrator anlegen.\n'
else printf 'Nur Agent installiert. Verbindungsstatus im Master prüfen.\n';fi
printf 'Konfiguration: %s/bootstrap.json\n' "$data_root"
printf 'Updates: sudo %s/update.sh --latest --install-root %s --data-root %s\n' "$install_root" "$install_root" "$data_root"
