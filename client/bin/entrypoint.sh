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

# TODO: Just create directly in DB?
koji add-tag build --arches=x86_64
koji add-tag dest --arches=x86_64
koji add-target candidate build dest

koji add-pkg dest osbs-buildroot-docker --owner kojiadmin
# TODO: Create a channel

# For accessing containers not part of the default network
WORKSTATION_IP=$(/sbin/ip route | awk '/default/ { print $3 }')

ln -s /opt/osbs/osbs.conf /etc/osbs.conf
oc login --insecure-skip-tls-verify=true -u osbs -p osbs https://${WORKSTATION_IP}:8443/
oc new-project osbs
# Not ideal, but otherwise builder service account which is
# used for builds, is not able to query pods and attach metadata
# to OpenShfit builds via atomic-reactor.
oc adm policy add-role-to-user admin system:serviceaccount:osbs:builder

token=$(oc whoami -t)
sed --follow-symlinks -i "s/OSBS_TOKEN/${token}/" /etc/osbs.conf
# Use workstation's IP so it's reachable from within openshift's pods
sed --follow-symlinks -i "s/KOJI_HUB_IP/${WORKSTATION_IP}/" /etc/osbs.conf
sed --follow-symlinks -i "s/OPENSHIFT_IP/${WORKSTATION_IP}/" /etc/osbs.conf

# TODO: set secrets

exec "$@"
