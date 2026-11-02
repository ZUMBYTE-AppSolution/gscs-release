#!/usr/bin/env bash
set -euo pipefail
umask 077
cd -- "$(dirname -- "$0")"
mkdir -p secrets
for secret in db_password setup_token; do
  if [[ ! -e "secrets/$secret" ]]; then openssl rand -hex 32 > "secrets/$secret"; fi
  chmod 600 "secrets/$secret"
done
if [[ ! -e .env ]]; then cp .env.example .env; fi
printf 'GSCS-Docker vorbereitet. Datenbankpasswort: '
cat secrets/db_password
printf 'Einmaliger Web-Einrichtungscode: '
cat secrets/setup_token
printf 'In .env GSCS_HOST_DATA auf den absoluten Hostpfad setzen, z. B. /mnt/user/appdata/gscs.\nDann: docker compose up -d\n'
