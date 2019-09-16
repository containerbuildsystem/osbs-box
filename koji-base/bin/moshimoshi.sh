#!/bin/sh
set -euo pipefail

# Call koji hello in a loop until it succeeds.
#
# Use in containers that depend on koji-hub and koji-db being ready.

attempts=0

while true; do
    let attempts+=1
    echo "koji hello attempt #$attempts"

    if timeout 2 koji hello; then
        echo "Success!"
        break
    elif [ $? = 124 ]; then
        echo "Timed out, the hub or database pods are likely still starting."
    fi

    sleep 3
done
