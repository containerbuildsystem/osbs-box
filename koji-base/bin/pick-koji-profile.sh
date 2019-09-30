#!/bin/sh
set -euo pipefail

# Pick a koji profile to be used by the default koji command.

KOJI_USER=${1:-''}

if [ ! "$KOJI_USER" ]; then
    echo "Please supply a username as the 1st argument" >&2
    exit 1
fi

CONF_DIR=~/.koji/config.d

if [ ! -e "$CONF_DIR/$KOJI_USER.conf" ]; then
    echo "The $KOJI_USER koji profile does not seem to exist" >&2
    echo "Please run add-koji-profile.sh '$KOJI_USER' and try again" >&2
    exit 1
fi

sed "s/\\[$KOJI_USER\\]/[koji]/" \
    "$CONF_DIR/$KOJI_USER.conf" > ~/.koji/config
