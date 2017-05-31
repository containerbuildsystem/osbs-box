#!/bin/bash
set -xeuo pipefail

# Expose generated local data in volume
cp -r /opt/local/osbs /opt/
cp -r /opt/local/koji-clients /opt/
cp -r /opt/local/pki/koji /etc/pki/

for ip in `hostname -I`; do echo 'http://'$ip'/shared'; done
exec "$@"
