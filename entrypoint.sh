#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-/assets}"
SERVER_DIR="/opt/cs16"

if [ ! -d "${ASSETS_DIR}/valve" ] || [ ! -d "${ASSETS_DIR}/cstrike" ]; then
  echo "Missing assets. Mount your legal game files to ${ASSETS_DIR} with valve/ and cstrike/."
  echo "Example: -v /path/to/legal-cs16:/assets:ro"
  exit 1
fi

if [ ! -e "${SERVER_DIR}/valve" ]; then
  ln -s "${ASSETS_DIR}/valve" "${SERVER_DIR}/valve"
fi

if [ ! -e "${SERVER_DIR}/cstrike" ]; then
  ln -s "${ASSETS_DIR}/cstrike" "${SERVER_DIR}/cstrike"
fi

if [ ! -f "${SERVER_DIR}/cstrike/server.cfg" ] && [ -f "${SERVER_DIR}/server.cfg" ]; then
  cp "${SERVER_DIR}/server.cfg" "${SERVER_DIR}/cstrike/server.cfg"
fi

if [ -f "${SERVER_DIR}/cstrike/dlls/cs_arm64.so" ]; then
  echo "Using ARM64 game library: cstrike/dlls/cs_arm64.so"
elif [ -f "${SERVER_DIR}/cstrike/dlls/cs.so" ]; then
  echo "Using game library: cstrike/dlls/cs.so"
else
  echo "Missing game library in cstrike/dlls/. Expected cs_arm64.so or cs.so"
  exit 1
fi

MAP="${MAP:-de_dust2}"
MAXPLAYERS="${MAXPLAYERS:-16}"
PORT="${PORT:-27015}"

cd "${SERVER_DIR}"
exec ./xash -console -dedicated -game cstrike +maxplayers "${MAXPLAYERS}" +map "${MAP}" -port "${PORT}" "$@"
