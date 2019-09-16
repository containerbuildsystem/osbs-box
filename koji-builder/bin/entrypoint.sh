#!/bin/sh
set -euo pipefail

# Become kojiadmin
pick-koji-user.sh "kojiadmin"

# Wait for up to a minute until koji is ready
if ! timeout 60 moshimoshi.sh; then
    echo "Koji still not ready after 60s, something might be wrong." >&2
    exit 124
fi

# Set up kojibuilder
if ! koji list-hosts | grep -q "kojibuilder"; then
    koji add-host "kojibuilder" x86_64
    koji add-host-to-channel --new "kojibuilder" "container"
fi

exec "$@"
