#!/usr/bin/env bash
set -euo pipefail
umask 0077
if [[ ${GSCS_MODE:-controller} == game ]];then
 export HOME=/home/container
 if [[ ${GSCS_JAVA_MAJOR:-} =~ ^(17|21|25)$ ]];then export JAVA_HOME=/opt/gscs-java/$GSCS_JAVA_MAJOR;export PATH=$JAVA_HOME/bin:$PATH;fi
 exec /usr/local/bin/gscs-game-entrypoint "$@"
fi
if (($#));then exec /opt/gscs/GSCS "$@";fi
[[ $(id -u) = 0 ]] || { printf 'GSCS benötigt für die interne Diensteeinrichtung den Container-Start als root.\n' >&2;exit 1; }
root=${GSCS_DATA:-/var/lib/gscs}
[[ $root == /* && $root != / && $root != *$'\n'* && $root != *'%'* ]] || exit 2
role=${GSCS_ROLE:-master};[[ $role == master || $role == node ]] || exit 2
install -d -o gscs -g gscs -m 0750 "$root"
for folder in home run secrets;do install -d -o gscs -g gscs -m 0750 "$root/$folder";done
export HOME=$root/home DISPLAY=:99
export GSCS_DATA=$root GSCS_ROLE=$role
# Stable across panel-process restarts; new for every complete container boot.
export GSCS_CONTAINER_BOOT_ID=$(cat /proc/sys/kernel/random/uuid)
/opt/gscs/GSCS --prepare-hardware
if [[ $role == node && -n ${GSCS_AGENT_KEY_FILE:-} ]];then
 [[ -r $GSCS_AGENT_KEY_FILE ]] || { printf 'Node-Schlüsseldatei ist nicht lesbar.\n' >&2;exit 1; }
 if [[ $GSCS_AGENT_KEY_FILE != "$root/secrets/agent_key" ]];then cp -- "$GSCS_AGENT_KEY_FILE" "$root/secrets/agent_key";fi
 chown gscs:gscs "$root/secrets/agent_key";chmod 600 "$root/secrets/agent_key"
 export GSCS_AGENT_KEY_FILE=$root/secrets/agent_key
fi
if [[ -z ${GSCS_HOST_MACHINE_ID_FILE:-} && -r /sys/class/dmi/id/product_uuid ]];then
 sha256sum /sys/class/dmi/id/product_uuid | cut -d' ' -f1 > "$root/run/host-machine-id"
 chown gscs:gscs "$root/run/host-machine-id";chmod 600 "$root/run/host-machine-id"
 export GSCS_HOST_MACHINE_ID_FILE=$root/run/host-machine-id
fi
if [[ -S /var/run/docker.sock ]];then
 gid=$(stat -c %g /var/run/docker.sock)
 group=$(getent group "$gid" | cut -d: -f1 || true)
 if [[ -z $group ]];then group=gscs-docker-$gid;groupadd --gid "$gid" "$group";fi
 usermod -aG "$group" gscs
fi
if [[ -f $root/bootstrap.json ]];then chown gscs:gscs "$root/bootstrap.json";chmod 600 "$root/bootstrap.json";fi
install -d -o gscs -g gscs -m 0750 "$root/application"
if [[ ! -d $root/application/current && ! -f $root/application/image-promotion.json ]];then
 install -d -o gscs -g gscs -m 0750 "$root/application/current"
 cp -a /opt/gscs/. "$root/application/current/"
 chown -R gscs:gscs "$root/application/current"
fi
if [[ -f $root/bootstrap.json ]];then
 jq --arg install "$root/application" --arg url "${GSCS_URL:-http://0.0.0.0:5080}" '.installRoot=$install | .listenUrl=$url' "$root/bootstrap.json" > "$root/run/bootstrap.new"
 chown gscs:gscs "$root/run/bootstrap.new";chmod 600 "$root/run/bootstrap.new";mv -- "$root/run/bootstrap.new" "$root/bootstrap.json"
fi
embedded=false
if [[ $role == master ]];then
 if [[ -f $root/embedded-postgres.json ]];then embedded=true
 elif [[ ! -f $root/bootstrap.json && ${GSCS_DB_MODE:-embedded} == embedded && -z ${GSCS_DB_HOST:-} ]];then embedded=true
 fi
fi
if $embedded;then
 export PGDATA=$root/postgresql
 export GSCS_DB_HOST=$root/postgres-socket GSCS_DB_PORT=5432 GSCS_DB_NAME=gscs GSCS_DB_USER=gscs
 export GSCS_DB_PASSWORD_FILE=$root/secrets/db_password GSCS_SETUP_TOKEN_FILE=$root/secrets/setup_token
 if [[ -f $PGDATA/PG_VERSION && ! -f $GSCS_DB_PASSWORD_FILE ]];then printf 'Datenbankpasswortdatei fehlt. Vorhandene Datenbank wird nicht neu initialisiert.\n' >&2;exit 1;fi
 for file in "$GSCS_DB_PASSWORD_FILE" "$GSCS_SETUP_TOKEN_FILE";do
  if [[ ! -f $file ]];then openssl rand -hex 32 > "$file";fi
  chown gscs:gscs "$file";chmod 640 "$file"
 done
 install -d -o postgres -g postgres -m 0700 "$PGDATA"
 install -d -o postgres -g gscs -m 0770 "$GSCS_DB_HOST"
 if [[ ! -f $PGDATA/PG_VERSION ]];then
  gosu postgres initdb -D "$PGDATA" --username=gscs --pwfile="$GSCS_DB_PASSWORD_FILE" --auth-local=scram-sha-256 --auth-host=scram-sha-256 --locale=C.UTF-8 > "$root/run/initdb.log" 2>&1
  cat >> "$PGDATA/postgresql.conf" <<CONFIG
listen_addresses = ''
unix_socket_directories = '$GSCS_DB_HOST'
unix_socket_group = 'gscs'
unix_socket_permissions = 0770
jit = off
CONFIG
  printf 'CREATE DATABASE gscs OWNER gscs;\n' | gosu postgres postgres --single -D "$PGDATA" template1 > "$root/run/create-database.log" 2>&1
 fi
 [[ $(cat "$PGDATA/PG_VERSION") = 18 ]] || { printf 'Für diese PostgreSQL-Daten ist eine bewusste Versionsmigration erforderlich.\n' >&2;exit 1; }
 printf '{"majorVersion":18,"mode":"embedded"}\n' > "$root/embedded-postgres.json"
 chown gscs:gscs "$root/embedded-postgres.json";chmod 600 "$root/embedded-postgres.json"
fi
config=$root/run/supervisord.conf
cat > "$config" <<CONFIG
[supervisord]
nodaemon=true
user=root
logfile=/dev/null
pidfile=$root/run/supervisord.pid
[unix_http_server]
file=$root/run/supervisor.sock
chmod=0660
chown=root:gscs
[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface
[supervisorctl]
serverurl=unix://$root/run/supervisor.sock
[program:gscs]
command=/usr/local/bin/gscs-start-panel
directory=/opt/gscs
user=gscs
priority=20
autorestart=unexpected
startsecs=3
stopasgroup=true
killasgroup=true
stopwaitsecs=60
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
[program:updates]
command=/usr/local/bin/gscs-watch-updates
user=gscs
priority=25
autorestart=unexpected
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/null
stderr_logfile=/dev/null
CONFIG
if $embedded;then
 cat >> "$config" <<CONFIG
[program:postgres]
command=/usr/lib/postgresql/18/bin/postgres -D $PGDATA
user=postgres
priority=10
autorestart=unexpected
startsecs=3
stopsignal=INT
stopwaitsecs=60
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
CONFIG
fi
if command -v wine >/dev/null;then
 cat >> "$config" <<CONFIG
[program:xvfb]
command=/usr/bin/Xvfb :99 -screen 0 1280x720x24 -nolisten tcp
user=gscs
priority=15
autorestart=unexpected
stdout_logfile=/dev/null
stderr_logfile=/dev/null
CONFIG
fi
chown root:gscs "$config";chmod 640 "$config"
exec /usr/bin/supervisord -c "$config"
