#!/usr/bin/env bash
set -euo pipefail
target=${1:-/opt/gscs-proton}
[[ $target == /* && $target != / && $target != *'/../'* ]] || exit 2
[[ $(uname -m) == x86_64 ]] || exit 0
[[ ! -e $target/proton ]] || exit 0
version=GE-Proton11-11
sha256=aa85986cada5709aa8bbfa8add7f3bfb925cbe15710c98995898d308ff2ca3c1
work=$(mktemp -d)
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$version/$version-x86_64.tar.gz" -o "$work/proton.tar.gz"
printf '%s  %s\n' "$sha256" "$work/proton.tar.gz" | sha256sum -c -
mkdir -p "$target"
tar -xzf "$work/proton.tar.gz" --strip-components=1 --no-same-owner -C "$target"
[[ -x $target/proton ]] || exit 1
printf '%s\n' "$version" > "$target/gscs-runtime-version"
rm -- "$work/proton.tar.gz";rmdir -- "$work"
