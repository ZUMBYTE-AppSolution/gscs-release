#!/bin/sh
set -eu
umask 0002
# Some Steam dedicated servers resolve their SDK through the game user's home.
if [ -f ./steamclient.so ]; then
 class=$(od -An -tu1 -j4 -N1 ./steamclient.so | tr -d ' ')
 case "$class" in 1) sdk=sdk32;; 2) sdk=sdk64;; *) sdk=;; esac
 if [ -n "$sdk" ]; then
  mkdir -p "$HOME/.steam/$sdk"
  cp ./steamclient.so "$HOME/.steam/$sdk/steamclient.so"
 fi
fi
exec "$@"
