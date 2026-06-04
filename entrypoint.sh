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
link_shadow_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  for item in "$src"/*; do
    [ -e "$item" ] || continue
    local base
    base=$(basename "$item")
    if [ "$base" = "dlls" ]; then
      mkdir -p "$dst/dlls"
      for subitem in "$item"/*; do
        [ -e "$subitem" ] || continue
        ln -sf "$subitem" "$dst/dlls/$(basename "$subitem")"
      done
    else
      ln -sf "$item" "$dst/$base"
    fi
  done
}

echo "Shadowing read-only assets into writable container layout..."
link_shadow_dir "${ASSETS_DIR}/valve" "${SERVER_DIR}/valve"
link_shadow_dir "${ASSETS_DIR}/cstrike" "${SERVER_DIR}/cstrike"

# Handle valve library
if [ -f "${ASSETS_DIR}/valve/dlls/hl_arm64.so" ]; then
  echo "Found mounted ARM64 HL library (hl_arm64.so)."
else
  echo "Copying built-in native ARM64 HL library..."
  mkdir -p "${SERVER_DIR}/valve/dlls"
  rm -f "${SERVER_DIR}/valve/dlls/hl.so" 2>/dev/null || true
  cp "${SERVER_DIR}/native_dlls/hl.so" "${SERVER_DIR}/valve/dlls/hl.so"
fi

# Handle cstrike library
if [ -f "${ASSETS_DIR}/cstrike/dlls/cs_arm64.so" ]; then
  echo "Found mounted ARM64 CS library (cs_arm64.so)."
else
  echo "Copying built-in native ARM64 CS library..."
  mkdir -p "${SERVER_DIR}/cstrike/dlls"
  rm -f "${SERVER_DIR}/cstrike/dlls/cs.so" 2>/dev/null || true
  cp "${SERVER_DIR}/native_dlls/cs.so" "${SERVER_DIR}/cstrike/dlls/cs.so"
fi

# Copy server.cfg if not mounted
if [ ! -f "${SERVER_DIR}/cstrike/server.cfg" ] && [ -f "${SERVER_DIR}/server.cfg" ]; then
  cp "${SERVER_DIR}/server.cfg" "${SERVER_DIR}/cstrike/server.cfg"
fi

# Configure server
MAP="${MAP:-de_dust2}"
MAXPLAYERS="${MAXPLAYERS:-16}"
PORT="${PORT:-27015}"

cd "${SERVER_DIR}"
exec ./xash -console -dedicated -game cstrike +maxplayers "${MAXPLAYERS}" +map "${MAP}" -port "${PORT}" "$@"
