#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-/assets}"
SERVER_DIR="${SERVER_DIR:-/opt/cs16}"

# Ensure legal assets are mounted
if [ ! -d "${ASSETS_DIR}/valve" ] || [ ! -d "${ASSETS_DIR}/cstrike" ]; then
  echo "Missing assets. Mount your legal game files to ${ASSETS_DIR} with valve/ and cstrike/."
  exit 1
fi

# Link assets (only if not already there, avoiding bind mount issues)
if [ ! -e "${SERVER_DIR}/valve" ]; then ln -s "${ASSETS_DIR}/valve" "${SERVER_DIR}/valve"; fi
if [ ! -e "${SERVER_DIR}/cstrike" ]; then ln -s "${ASSETS_DIR}/cstrike" "${SERVER_DIR}/cstrike"; fi

# Copy native libs to cstrike/dlls if not already provided by mount
mkdir -p "${SERVER_DIR}/cstrike/dlls"
if [ ! -f "${SERVER_DIR}/cstrike/dlls/cs.so" ]; then
  echo "Copying native ARM64 CS library..."
  cp "${SERVER_DIR}/native_dlls/cs.so" "${SERVER_DIR}/cstrike/dlls/cs.so"
fi

if [ ! -f "${SERVER_DIR}/valve/dlls/hl.so" ]; then
  echo "Copying native ARM64 HL library..."
  mkdir -p "${SERVER_DIR}/valve/dlls"
  cp "${SERVER_DIR}/native_dlls/hl.so" "${SERVER_DIR}/valve/dlls/hl.so"
fi

# Configure server
MAP="${MAP:-de_dust2}"
MAXPLAYERS="${MAXPLAYERS:-16}"
PORT="${PORT:-27015}"

cd "${SERVER_DIR}"
exec ./xash -console -dedicated -game cstrike +maxplayers "${MAXPLAYERS}" +map "${MAP}" -port "${PORT}" "$@"
