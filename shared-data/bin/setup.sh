#!/bin/bash
set -xeuo pipefail

# Create folder structure local data
mkdir -p /opt/local/koji-clients

# Generate users certificates
mkuser.sh kojiweb
mkuser.sh kojibuilder
mkuser.sh kojiadmin
mkuser.sh kojiosbs

# Enable kojiadmin config for root user
mkdir -p /root/.koji
ln -s /opt/local/koji-clients/kojiadmin/config /root/.koji/config

# Set password for registry
mkdir /opt/local/auth
htpasswd -Bbn osbs craycray > /opt/local/auth/htpasswd
