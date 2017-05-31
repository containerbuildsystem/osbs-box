#!/bin/bash
set -xeuo pipefail

# Create folder structure local data
mkdir -p /opt/local/koji-clients
mkdir -p /opt/local/pki/koji/{certs,private,confs}

# Setup some root stuff
chmod 600 /root/.pgpass
chmod +x /usr/local/bin/*
echo 'root:mypassword' | chpasswd

# Generate CA certificate
pushd /opt/local/pki/koji > /dev/null

touch index.txt
echo 01 > serial

# CA
conf=confs/ca.cnf
cp ssl.cnf $conf

openssl genrsa -out private/koji_ca_cert.key 2048
openssl req -config $conf -new -x509 \
    -subj "/C=US/ST=Drunken/L=Bed/O=IT/CN=koji-hub" \
    -days 3650 \
    -key private/koji_ca_cert.key \
    -out koji_ca_cert.crt \
    -extensions v3_ca

cp private/koji_ca_cert.key private/kojihub.key
cp koji_ca_cert.crt certs/kojihub.crt
popd > /dev/null

# Generate users certificates
mkuser.sh kojiweb
mkuser.sh kojibuilder
mkuser.sh kojiadmin
chown -R nobody:nobody /opt/local/koji-clients

# Enable kojiadmin config for root user
mkdir -p /root/.koji
ln -s /opt/local/koji-clients/kojiadmin/config /root/.koji/config
