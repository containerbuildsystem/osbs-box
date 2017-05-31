#!/bin/bash
set -xeuo pipefail

if [ ! -e "/docker-init" ]
then
    # Use kojiadmin user by default
    mkdir -p /root/.koji
    ln -fs /opt/koji-clients/kojiadmin/config /root/.koji/config

    touch /docker-init
fi

for ip in `hostname -I`;
do
    echo 'http://'$ip'/koji';
    echo 'http://'$ip'/kojifiles';
done

exec "$@"
