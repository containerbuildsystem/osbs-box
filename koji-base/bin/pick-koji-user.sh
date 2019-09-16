#!/bin/sh
set -euo pipefail

# Copy all the necessary files for the specified koji user to ~/.koji

CERTS_DIR=/etc/pki/koji
KOJI_CONF=/etc/koji.conf

user=${1:-''}

if [ ! "$user" ]; then
    echo "Please supply a username as the 1st argument" >&2
    exit 1
fi

if [ ! -e "$CERTS_DIR/$user.pem" ]; then
    echo "ERROR: client certificate for user '$user' not found" >&2
    exit 1
fi

mkdir -p ~/.koji

cp "$CERTS_DIR/$user.pem" ~/.koji/client.pem
cp "$CERTS_DIR/koji-ca.crt" ~/.koji/serverca.crt

# Do not overwrite potential manual changes in koji config
cp --no-clobber "$KOJI_CONF" ~/.koji/config
