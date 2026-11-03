#!/bin/sh
set -eu
umask 0002
export HOME=${HOME:-/home/container}
if [ "${DISPLAY:-}" = :99 ] && command -v Xvfb >/dev/null && [ ! -S /tmp/.X11-unix/X99 ];then
 Xvfb :99 -screen 0 1280x720x24 -nolisten tcp >/dev/null 2>&1 &
fi
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
