#!/bin/bash
set -euo pipefail

# Create basic directory structure for koji and change the owner to apache
# Has to be done at runtime because the /mnt/koji/ directory is mounted
mkdir -p /mnt/koji/{packages,repos,work,scratch}
chown -R apache:apache /mnt/koji

exec "$@"
