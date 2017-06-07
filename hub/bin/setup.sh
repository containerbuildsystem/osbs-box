#!/bin/bash
set -xeuo pipefail

# Use kojiadmin user by default
mkdir -p /root/.koji
ln -fs /opt/koji-clients/kojiadmin/config /root/.koji/config
