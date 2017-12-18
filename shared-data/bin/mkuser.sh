#!/bin/bash
set -xeuo pipefail

IP="172.17.0.1"
user=$1
clients_dir=/opt/local/koji-clients
certs_dir_volume=/etc/pki/osbs-box/certs

mkdir -p "${clients_dir}/${user}"

# Generate user config
cat << EOF > "${clients_dir}/${user}/config"
[koji]
server = https://${IP}:8083/kojihub
authtype = ssl
cert = ${certs_dir_volume}/${user}.crt
serverca = ${certs_dir_volume}/koji_ca_cert.crt
weburl = http://KOJI_IP/koji
topurl = http://KOJI_IP/kojifiles

[koji-containerbuild]
server = https://${IP}:8083/kojihub
authtype = ssl
cert = ${certs_dir_volume}/${user}.crt
serverca = ${certs_dir_volume}/koji_ca_cert.crt
weburl = http://KOJI_IP/koji
topurl = http://KOJI_IP/kojifiles
EOF
