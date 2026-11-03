#!/usr/bin/env bash
set -euo pipefail
install_root=${1:-/opt/gscs}
script_root=$(cd -- "$(dirname -- "$0")" && pwd)
[[ $EUID -eq 0 && $install_root == /* && $install_root != / ]] || exit 2
apt-get install -y --no-install-recommends curl ca-certificates xz-utils unzip tar jq xvfb xauth libatomic1 libpulse0 libglu1-mesa libsdl2-2.0-0 git wget bzip2 python3 python3-venv mono-runtime libgdiplus libmono-system-xml4.0-cil libmono-system-data4.0-cil libmono-system-net-http4.0-cil
architecture=x64;[[ $(dpkg --print-architecture) == arm64 ]] && architecture=arm64
dotnet_root=$install_root/runtimes/dotnet
mkdir -p "$dotnet_root"
for major in 8 9 10;do
 metadata=$(mktemp)
 curl --fail --location --retry 3 "https://builds.dotnet.microsoft.com/dotnet/release-metadata/$major.0/releases.json" -o "$metadata" --silent --show-error
 version=$(jq -r '.["latest-runtime"]' "$metadata")
 asset=$(jq -c --arg version "$version" --arg rid "linux-$architecture" '.releases[]|select(.runtime.version==$version)|.runtime.files[]|select(.rid==$rid and (.name|startswith("dotnet-runtime-")) and (.name|endswith(".tar.gz")))' "$metadata" | head -n 1)
 url=$(jq -r .url <<< "$asset");hash=$(jq -r .hash <<< "$asset")
 [[ $url == https://builds.dotnet.microsoft.com/* && $hash =~ ^[a-fA-F0-9]{128}$ ]] || exit 2
 package=$(mktemp)
 curl --fail --location --retry 3 "$url" -o "$package" --silent --show-error
 printf '%s  %s\n' "$hash" "$package" | sha512sum -c -
 tar -xzf "$package" --no-same-owner -C "$dotnet_root"
 rm -- "$package" "$metadata"
done
if [[ $(dpkg --print-architecture) == amd64 ]];then
 dpkg --add-architecture i386;apt-get update -qq
 apt-get install -y --no-install-recommends lib32gcc-s1 lib32stdc++6 lib32z1 wine wine64 wine32:i386 winbind
 bash "$script_root/install-proton.sh" "$install_root/runtimes/proton"
fi
cat > /etc/systemd/system/gscs-display.service <<'UNIT'
[Unit]
Description=GSCS compatibility display
After=network.target
[Service]
User=gscs
Group=gscs
ExecStart=/usr/bin/Xvfb :99 -screen 0 1280x720x24 -nolisten tcp
Restart=on-failure
NoNewPrivileges=yes
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload;systemctl enable --now gscs-display.service
