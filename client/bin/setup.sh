#!/bin/bash
set -xeuo pipefail

# TODO: Just create directly in DB?
koji add-tag build --arches=x86_64
koji add-tag dest --arches=x86_64
koji add-target candidate build dest

koji add-pkg dest osbs-buildroot-docker --owner kojiadmin
koji add-pkg dest docker-hello-world --owner kojiadmin

# Enable content generator access
koji grant_cg_access kojiosbs atomic-reactor
# TODO: Create a channel

WORKSTATION_IP='172.17.0.1'
oc login --insecure-skip-tls-verify=true -u osbs -p osbs https://${WORKSTATION_IP}:8443/
# Some of the commands below require user to be a cluster admin
# In the future, this project should provide an ansible playbook
# that uses the existing ansible role osbs-namespace to perform such operations.
# Although, secret is probably better handled here.
# In the meantime, just make osbs user a cluster admin
# (can be done prior to user and namespace are created):
#   oc -n osbs adm policy add-cluster-role-to-user cluster-admin osbs

oc new-project osbs
oc adm policy add-role-to-user edit -z builder

oc secret new kojisecret \
    serverca=/etc/pki/osbs-box/certs/koji_ca_cert.crt \
    ca=/etc/pki/osbs-box/certs/koji_ca_cert.crt \
    cert=/etc/pki/osbs-box/certs/kojiosbs.crt

oc secrets add serviceaccount/builder secrets/kojisecret --for=mount

oc adm policy add-role-to-user system:build-strategy-custom -z builder -n osbs

oc create secret generic v2-registry-dockercfg --from-file=.dockerconfigjson=/configs/dockerconfigjson --type=kubernetes.io/dockerconfigjson
oc secrets link builder v2-registry-dockercfg --for=mount

oc new-project worker
oc adm policy add-role-to-user edit -z builder

oc secret new kojisecret \
    serverca=/etc/pki/osbs-box/certs/koji_ca_cert.crt \
    ca=/etc/pki/osbs-box/certs/koji_ca_cert.crt \
    cert=/etc/pki/osbs-box/certs/kojiosbs.crt

oc secrets add serviceaccount/builder secrets/kojisecret --for=mount

oc adm policy add-role-to-user system:build-strategy-custom -z builder -n worker

oc create secret generic v2-registry-dockercfg --from-file=.dockerconfigjson=/configs/dockerconfigjson --type=kubernetes.io/dockerconfigjson
oc secrets link builder v2-registry-dockercfg --for=mount

cp /configs/reactor-config-secret.yml /tmp/reactor-config-secret.yml
cp /configs/reactor-config-map.yml /tmp/reactor-config-map.yml
cp /configs/client-config-secret.conf /tmp/osbs.conf
sed -i "s/KOJI_HUB_IP/${WORKSTATION_IP}/" /tmp/osbs.conf
sed -i "s/KOJI_HUB_IP/${WORKSTATION_IP}/" /tmp/reactor-config-map.yml
sed -i "s/OPENSHIFT_IP/${WORKSTATION_IP}/" /tmp/reactor-config-map.yml

oc project osbs
oc create secret generic client-config-secret --from-file=/tmp/osbs.conf
oc create secret generic reactor-config-secret --from-file='config.yaml'=/tmp/reactor-config-secret.yml
oc create configmap reactor-config-map --from-file='config.yaml'=/tmp/reactor-config-map.yml
