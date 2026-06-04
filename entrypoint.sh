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
  rm -f "${SERVER_DIR}/valve/dlls/hl_arm64.so" 2>/dev/null || true
  cp "${SERVER_DIR}/native_dlls/hl_arm64.so" "${SERVER_DIR}/valve/dlls/hl_arm64.so"
fi

# Handle cstrike library
if [ -f "${ASSETS_DIR}/cstrike/dlls/cs_arm64.so" ]; then
  echo "Found mounted ARM64 CS library (cs_arm64.so)."
else
  echo "Copying built-in native ARM64 CS library..."
  mkdir -p "${SERVER_DIR}/cstrike/dlls"
  rm -f "${SERVER_DIR}/cstrike/dlls/cs_arm64.so" 2>/dev/null || true
  cp "${SERVER_DIR}/native_dlls/cs_arm64.so" "${SERVER_DIR}/cstrike/dlls/cs_arm64.so"
fi

ENABLE_METAMOD="${ENABLE_METAMOD:-1}"
if [ "${ENABLE_METAMOD}" = "1" ]; then
  echo "Installing native ARM64 Metamod-FWGS..."
  mkdir -p "${SERVER_DIR}/cstrike/addons/metamod"
  cp "${SERVER_DIR}/native_dlls/metamod_arm64.so" "${SERVER_DIR}/cstrike/addons/metamod/metamod_arm64.so"

  if [ ! -f "${SERVER_DIR}/cstrike/addons/metamod/plugins.ini" ]; then
    : > "${SERVER_DIR}/cstrike/addons/metamod/plugins.ini"
  fi

  cat > "${SERVER_DIR}/cstrike/addons/metamod/config.ini" <<'EOF'
debuglevel 0
gamedll dlls/cs_arm64.so
exec_cfg addons/metamod/exec.cfg
clientmeta yes
dynalign_list yes
EOF

  if [ -L "${SERVER_DIR}/cstrike/gameinfo.txt" ]; then
    cp "$(readlink "${SERVER_DIR}/cstrike/gameinfo.txt")" "${SERVER_DIR}/cstrike/gameinfo.txt.tmp" 2>/dev/null || true
    rm -f "${SERVER_DIR}/cstrike/gameinfo.txt"
    if [ -f "${SERVER_DIR}/cstrike/gameinfo.txt.tmp" ]; then
      mv "${SERVER_DIR}/cstrike/gameinfo.txt.tmp" "${SERVER_DIR}/cstrike/gameinfo.txt"
    fi
  fi

  if [ ! -f "${SERVER_DIR}/cstrike/gameinfo.txt" ]; then
    cat > "${SERVER_DIR}/cstrike/gameinfo.txt" <<'EOF'
game "Counter-Strike"
gamedir "cstrike"
fallback_dir "valve"
gamedll "dlls/cs.dll"
gamedll_linux "addons/metamod/metamod.so"
EOF
  elif grep -q '^gamedll_linux' "${SERVER_DIR}/cstrike/gameinfo.txt"; then
    sed -i 's#^gamedll_linux.*#gamedll_linux "addons/metamod/metamod.so"#' "${SERVER_DIR}/cstrike/gameinfo.txt"
  else
    printf '\ngamedll_linux "addons/metamod/metamod.so"\n' >> "${SERVER_DIR}/cstrike/gameinfo.txt"
  fi
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
