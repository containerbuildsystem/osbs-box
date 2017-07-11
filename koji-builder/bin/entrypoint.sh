#!/bin/bash

set -xeuo pipefail

mkdir -p /root/.koji
ln -f -s /opt/koji-clients/kojiadmin/config /root/.koji/config

# Actions below this line, require koji hub to be up
set +xe
echo "Waiting for koji-hub to start..."
while true; do
    koji hello && break
	sleep 5
done
set -xe

if [ ! -e "/opt/osbs/builder-init" ]
then
    prepare_builder.sh
    touch /opt/osbs/builder-init
fi

ln -f -s /opt/osbs/osbs.conf /etc/osbs.conf

systemctl enable kojid
exec "$@"
