#!/bin/sh
set -euo pipefail

# Wait for up to a minute until koji is ready
if ! timeout 60 moshimoshi.sh; then
    echo "Koji still not ready after 60s, something might be wrong." >&2
    exit 124
fi

exec "$@"
