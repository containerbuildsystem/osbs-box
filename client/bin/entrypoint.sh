#!/bin/bash
set -xeuo pipefail

rm -rf /root/{.koji,bin}
mkdir -p /root/{.koji,bin}

ln -s /opt/koji-clients/kojiadmin/config /root/.koji/config

set +xe
echo "Waiting for koji-hub to start..."
while true; do
    koji hello && break
	sleep 5
done
set -xe

if [ ! -e "/opt/osbs/client-init" ]
then
  . /usr/local/bin/setup.sh
  touch /opt/osbs/client-init
fi

ln -fs /opt/osbs/osbs.conf /etc/osbs.conf
# For accessing containers not part of the default network
WORKSTATION_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
oc login --insecure-skip-tls-verify=true -u osbs -p osbs https://${WORKSTATION_IP}:8443/
token=$(oc whoami -t)
sed --follow-symlinks -i "s/OSBS_TOKEN/${token}/" /etc/osbs.conf
# Use workstation's IP so it's reachable from within openshift's pods
sed --follow-symlinks -i "s/KOJI_HUB_IP/${WORKSTATION_IP}/" /etc/osbs.conf
sed --follow-symlinks -i "s/OPENSHIFT_IP/${WORKSTATION_IP}/" /etc/osbs.conf

# Use internal koji IP when displaying koji task link
# For some reason koji is not listening
KOJI_IP=$(getent hosts koji-hub | awk '{ print $1 }')
sed --follow-symlinks -i "s/KOJI_IP/${KOJI_IP}/" /root/.koji/config

exec "$@"
