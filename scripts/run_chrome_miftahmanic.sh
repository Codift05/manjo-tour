#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8787}"
URL="http://127.0.0.1:${PORT}"

# Open tab in miftahmanic@gmail.com (Chrome Default profile) as soon as server is ready
(
  for _ in $(seq 1 60); do
    if curl -sf "${URL}" >/dev/null 2>&1; then
      google-chrome --profile-directory=Default "${URL}" >/dev/null 2>&1 &
      exit 0
    fi
    sleep 1
  done
) &

exec flutter run -d web-server --web-port "${PORT}" --web-hostname 127.0.0.1
