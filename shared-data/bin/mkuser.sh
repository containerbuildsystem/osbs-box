#!/bin/bash
set -xeuo pipefail

pushd /opt/local/pki/koji > /dev/null

IP="koji-hub"

# If you change your certificate authority name to
# something else you will need to change the caname
# value to reflect the change.
caname="koji"

user=$1
password="mypassword"
conf=confs/${user}-ssl.cnf

openssl genrsa -out private/${user}.key 2048
cp ssl.cnf $conf

openssl req -config $conf -new -nodes \
    -out certs/${user}.csr \
    -key private/${user}.key \
    -subj "/C=US/ST=Drunken/L=Bed/O=IT/CN=${user}/emailAddress=${user}@kojihub.local"

openssl ca -config $conf -batch \
    -keyfile private/${caname}_ca_cert.key \
    -cert ${caname}_ca_cert.crt \
    -out certs/${user}-crtonly.crt \
    -outdir certs \
    -infiles certs/${user}.csr

openssl pkcs12 -export \
    -inkey private/${user}.key \
    -passout "pass:${password}" \
    -in certs/${user}-crtonly.crt \
    -certfile ${caname}_ca_cert.crt \
    -CAfile ${caname}_ca_cert.crt \
    -chain -clcerts \
    -out certs/${user}_browser_cert.p12

openssl pkcs12 -clcerts \
    -passin "pass:${password}" \
    -passout "pass:${password}" \
    -in certs/${user}_browser_cert.p12 \
    -inkey private/${user}.key \
    -out certs/${user}.pem

cat certs/${user}-crtonly.crt private/${user}.key > certs/${user}.crt

client=/opt/local/koji-clients/${user}
client_shared=/opt/koji-clients/${user}

rm -rf $client
mkdir -p $client
# NOTE: It is IMPORTANT you use the aggregated form
cp /opt/local/pki/koji/certs/${user}.crt $client/client.crt
cp /opt/local/pki/koji/certs/${user}.pem $client/client.pem
cp /opt/local/pki/koji/certs/${user}_browser_cert.p12 $client/client_browser_cert.p12
cp /opt/local/pki/koji/koji_ca_cert.crt $client/clientca.crt
cp /opt/local/pki/koji/koji_ca_cert.crt $client/serverca.crt

# Generate user config
cat << EOF > $client/config
[koji]
server = https://${IP}:8083/kojihub
authtype = ssl
cert = ${client_shared}/client.crt
ca = ${client_shared}/clientca.crt
serverca = ${client_shared}/serverca.crt

[koji-containerbuild]
server = https://${IP}:8083/kojihub
authtype = ssl
cert = ${client_shared}/client.crt
ca = ${client_shared}/clientca.crt
serverca = ${client_shared}/serverca.crt
EOF

popd > /dev/null
