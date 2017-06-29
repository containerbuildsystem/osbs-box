#!/bin/bash
set -xeuo pipefail

# Expose generated local data in volume
cp -r /opt/local/osbs /opt/
cp -r /opt/local/koji-clients /opt/
cp -r /opt/local/pki/koji /etc/pki/
cp -r /opt/local/auth /
if [ ! -f /certs/domain.crt ]; then
  cp -r /opt/local/certs /
fi

for ip in `hostname -I`; do echo 'http://'$ip'/shared'; done
exec "$@"
