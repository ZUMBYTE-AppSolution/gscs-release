#!/usr/bin/env bash
set -euo pipefail
umask 077
cd -- "$(dirname -- "$0")"
version=0.1.0-alpha.10
for command in curl openssl jq sha256sum docker; do
 command -v "$command" >/dev/null || { printf 'Benötigtes Programm fehlt: %s\n' "$command" >&2;exit 1; }
done
case "$(uname -m)" in x86_64|amd64) rid=linux-x64;;aarch64|arm64) rid=linux-arm64;;*) printf 'Nicht unterstützte Architektur.\n' >&2;exit 1;;esac
base="https://github.com/ZUMBYTE-AppSolution/gscs-release/releases/download/v$version"
mkdir -p "downloads/$version"
folder="downloads/$version"
curl --fail --location --proto '=https' --tlsv1.2 "$base/gscs-images.json" -o "$folder/gscs-images.json"
curl --fail --location --proto '=https' --tlsv1.2 "$base/gscs-images.sig" -o "$folder/gscs-images.sig"
openssl dgst -sha256 -verify release-public.pem -signature "$folder/gscs-images.sig" "$folder/gscs-images.json"
[[ $(jq -r .version "$folder/gscs-images.json") = "$version" ]] || exit 2
[[ $(jq --arg rid "$rid" '[.images[]|select(.rid==$rid)]|length' "$folder/gscs-images.json") = 1 ]] || exit 2
while IFS=$'\t' read -r file hash;do
 [[ $file =~ ^GSCS-[a-zA-Z0-9.-]+-docker-universal-linux-(x64|arm64)\.tar\.gz$ && $hash =~ ^[a-fA-F0-9]{64}$ ]] || exit 2
 if [[ ! -f "$folder/$file" ]] || ! printf '%s  %s\n' "$hash" "$folder/$file" | sha256sum -c - >/dev/null 2>&1;then
  curl --fail --location --proto '=https' --tlsv1.2 "$base/$file" -o "$folder/$file.partial"
  printf '%s  %s\n' "$hash" "$folder/$file.partial" | sha256sum -c -
  mv -- "$folder/$file.partial" "$folder/$file"
 fi
 printf '%s  %s\n' "$hash" "$folder/$file" | sha256sum -c -
 docker load --input "$folder/$file"
done < <(jq -r --arg rid "$rid" '.images[]|select(.rid==$rid)|[.file,.sha256]|@tsv' "$folder/gscs-images.json")
printf 'GSCS-Images geladen. Mit bash prepare.sh fortfahren und anschließend docker compose up -d starten.\n'
