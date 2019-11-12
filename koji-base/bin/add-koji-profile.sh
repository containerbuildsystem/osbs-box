#!/bin/bash
set -euo pipefail

# Generate a koji profile for the specified user.
#
# If this container cannot access koji-hub at the default hostname (koji-hub),
# you should set the HUB_HOST environmental variable before running this script.
#
# You can also choose the list of koji cli plugins by setting the CLI_PLUGINS
# environment variable (should be a space-separated list).
#
# After generating a profile, you can:
#   * `ln -s /usr/bin/koji <somewhere in $PATH>/<username>` and use
#      the symlinked binary instead of 'koji'
#   * `pick-koji-profile.sh <username>` and use the 'koji' binary as usual

KOJI_USER=${1:-''}

if [ ! "$KOJI_USER" ]; then
    echo "Please supply a username as the 1st argument" >&2
    exit 1
fi

if [ ! -e "/etc/pki/koji/$KOJI_USER.pem" ]; then
    echo "Client certificate for $KOJI_USER not found" >&2
    exit 1
fi

HUB_HOST=${HUB_HOST:-koji-hub}
CLI_PLUGINS=${CLI_PLUGINS:-runroot}

CONF_DIR=~/.koji/config.d

mkdir -p "$CONF_DIR"

sed -e "s;\\\$KOJI_USER;$KOJI_USER;" \
    -e "s;\\\$HUB_HOST;$HUB_HOST;" \
    -e "s;\\\$CLI_PLUGINS;$CLI_PLUGINS;" \
    /etc/koji.conf.d/template > "$CONF_DIR/$KOJI_USER.conf"
