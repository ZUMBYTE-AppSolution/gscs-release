#!/usr/bin/env bash
set -euo pipefail
umask 077
install_root=/opt/gscs
data_root=/var/lib/gscs
latest=false
while (($#)); do
 case "$1" in
  --install-root) install_root=$2;shift 2;;
  --data-root) data_root=$2;shift 2;;
  --latest) latest=true;shift;;
  --apply-plan) shift;;
  *) printf 'Unbekannte Option: %s\n' "$1" >&2;exit 2;;
 esac
done
[[ $EUID -eq 0 ]] || { printf 'Das Update mit sudo starten.\n' >&2;exit 1; }
if $latest; then "$install_root/current/GSCS" --stage-latest-update --data-root "$data_root";fi
[[ -f "$data_root/update-plan.json" ]] || { printf 'Kein vorbereitetes Update.\n';exit 0; }
helper=$("$install_root/current/GSCS" --copy-update-helper --data-root "$data_root")
exec "$helper" --apply-update --data-root "$data_root"
