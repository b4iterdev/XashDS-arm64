#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: ./run.sh /absolute/path/to/legal/cs16 [extra xash args...]

Examples:
  ./run.sh /data/cs16
  MAP=de_inferno MAXPLAYERS=20 ./run.sh /data/cs16 +sv_lan 1
EOF
  exit 0
fi

ASSETS_PATH="${1:-}"
if [ -z "${ASSETS_PATH}" ]; then
  echo "Missing assets path. Run ./run.sh --help"
  exit 1
fi

shift || true

docker run --rm -it \
  --platform linux/arm64 \
  -p 27015:27015/udp \
  -p 27015:27015/tcp \
  -e MAP="${MAP:-de_dust2}" \
  -e MAXPLAYERS="${MAXPLAYERS:-16}" \
  -e PORT="${PORT:-27015}" \
  -v "${ASSETS_PATH}":/assets:ro \
  cs16-xashds:arm64 \
  "$@"
