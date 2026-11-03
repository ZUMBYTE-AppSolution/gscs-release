#!/usr/bin/env bash
set -euo pipefail
root=${GSCS_DATA:-/var/lib/gscs}
while true;do
 if [[ -f $root/update.request && ! -f $root/run/adopting-image ]];then
  if helper=$("$root/application/current/GSCS" --copy-update-helper --data-root "$root");then
   if "$helper" --apply-update --data-root "$root" > "$root/run/update-result.log" 2>&1;then rm -f -- "$root/run/update-error";else printf 'Das Update wurde nicht übernommen. Details: update-result.log\n' > "$root/run/update-error";fi
  else printf 'Updatehelfer konnte nicht geprüft werden.\n' > "$root/run/update-error";fi
  rm -f -- "$root/update.request"
 fi
 sleep 2
done
