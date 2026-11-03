#!/bin/bash
set -euo pipefail
umask 077
here=$(cd -- "$(dirname -- "$0")" && pwd)
bundle=$(cd -- "$here/.." && pwd)
[[ -f /etc/unraid-version && -d /boot/config && $(id -u) = 0 ]] || { printf 'Dieses Skript als root auf Unraid ausführen.\n' >&2;exit 1; }
load=false
channel=''
while (($#));do
 case "$1" in
  --load-image) load=true;shift;;
  --channel) [[ $# -ge 2 ]] || exit 2;channel=$2;shift 2;;
  *) printf 'Aufruf: bash unraid/install-unraid.sh [--load-image] [--channel alpha|beta|release]\n' >&2;exit 2;;
 esac
done
command -v plugin >/dev/null
command -v php >/dev/null
if [[ -n $channel ]];then
 [[ $channel = alpha || $channel = beta || $channel = release ]] || exit 2
 php -r '$d=json_decode(file_get_contents($argv[1]),true);exit(($d["channels"][$argv[2]]["available"]??false)?0:1);' "$here/channels.json" "$channel" || { printf 'Dieser Kanal ist noch nicht veröffentlicht.\n' >&2;exit 2; }
fi
if $load;then bash "$bundle/load-images.sh";fi
target=/boot/config/plugins/dockerMan/templates-user/my-GSCS.xml
existing=false
[[ ! -e $target ]] || existing=true
for previous in /boot/config/plugins/dockerMan/templates-user/my-gscs-alpha.xml /boot/config/plugins/dockerMan/templates-user/my-gscs-beta.xml /boot/config/plugins/dockerMan/templates-user/my-gscs-release.xml;do
 if [[ -f $previous ]] && php -r '$x=@simplexml_load_file($argv[1]);exit($x&&(string)$x->Name==="GSCS"&&str_starts_with((string)$x->Repository,"ghcr.io/zumbyte-appsolution/gscs:")?0:1);' "$previous";then existing=true;fi
done
temporary=$(mktemp -d /tmp/gscs-unraid-install.XXXXXXXX)
trap 'rm -f -- "$temporary/gscs-channel-selector.plg";rmdir -- "$temporary"' EXIT
cp -- "$here/gscs-channel-selector.plg" "$temporary/gscs-channel-selector.plg"
plugin install "$temporary/gscs-channel-selector.plg" forced
# Existing data paths and channels belong to the operator and are preserved.
if ! $existing;then
 if [[ -z $channel ]];then
  [[ -f "$bundle/release-version.txt" ]] || { printf 'Versionsangabe fehlt.\n' >&2;exit 2; }
  channel=$(tr -d '\r\n' < "$bundle/release-version.txt")
  [[ $channel =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]] || exit 2
 fi
 php -r '$x=simplexml_load_file($argv[1]);$image="ghcr.io/zumbyte-appsolution/gscs:".$argv[2];$x->Repository=$image;foreach($x->Config as $c)if((string)$c["Target"]==="GSCS_CONTAINER_IMAGE")$c[0]=$image;if(!$x->asXML($argv[1]))exit(1);' "$target" "$channel"
fi
printf '\nGSCS-Vorlage und Kanalwahl sind eingerichtet.\nUnter Docker → Container hinzufügen die Vorlage GSCS auswählen.\nFür private Kanäle wird eine GHCR-Anmeldung benötigt.\n'
