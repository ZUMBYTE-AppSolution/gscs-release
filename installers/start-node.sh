#!/usr/bin/env bash
set -euo pipefail
umask 077
cd -- "$(dirname -- "$0")"
chmod u+x GSCS
data_root=${GSCS_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/gscs-node}
./GSCS --configure-node --data-root "$data_root"
exec ./GSCS --data-root "$data_root"
