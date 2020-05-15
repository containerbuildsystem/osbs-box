#!/bin/bash
set -euo pipefail

cachito wait-for-db && cachito db upgrade
exec "$@"
