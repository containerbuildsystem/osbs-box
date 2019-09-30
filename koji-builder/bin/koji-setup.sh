#!/bin/sh
set -euo pipefail

# All of the koji setup necessary for running basic container builds.

check_result() {
    expected_err_msg=$1
    shift

    set +e
    output=`"$@" 2>&1`
    rv=$?
    set -e

    if [ $rv == 0 ]; then
        echo "$output"
        return 0
    elif grep -q -- "$expected_err_msg" <<< "$output"; then
        echo "$expected_err_msg"
        return 0
    else
        echo "$output" >&2
        return $rv
    fi
}

check_result 'kojibuilder is already in the database' \
             koji add-host kojibuilder x86_64

check_result 'host kojibuilder is already subscribed to the container channel' \
             koji add-host-to-channel kojibuilder container --new

check_result "A tag with the name 'build' already exists" \
             koji add-tag build --arches=x86_64
check_result "A tag with the name 'dest' already exists" \
             koji add-tag dest --arches=x86_64

check_result "A build target with the name 'candidate' already exists" \
             koji add-target candidate build dest

check_result 'Package osbs-buildroot-docker already exists in tag dest' \
             koji add-pkg dest osbs-buildroot-docker --owner kojiadmin
check_result 'Package docker-hello-world already exists in tag dest' \
             koji add-pkg dest docker-hello-world --owner kojiadmin

check_result 'btype already exists' \
             koji call addBType operator-manifests

check_result "user already exists: kojiosbs" \
             koji add-user kojiosbs

check_result 'User already has access to content generator atomic-reactor' \
             koji grant_cg_access kojiosbs atomic-reactor
