#!/bin/bash
set -xeuo pipefail

sleep 30

if [ ! -e "/opt/osbs/hub-init" ]
then
    . /usr/local/bin/setup.sh
    touch /opt/osbs/hub-init
fi

for ip in `hostname -I`;
do
    echo 'http://'$ip'/koji';
    echo 'http://'$ip'/kojifiles';
done

exec "$@"
