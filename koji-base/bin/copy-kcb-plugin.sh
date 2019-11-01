#!/bin/sh
set -euo pipefail

# After pip-installing koji-containerbuild from git, use this script to copy
# the specified plugin (cli, hub or builder) to the correct location.

KCB="/usr/lib/$PYTHON/site-packages/koji_containerbuild"

plugin=${1:-''}

if [ ! "$plugin" ]; then
    echo 'Please supply name of plugin as the 1st argument' >&2
    exit 1
fi

case "$plugin" in
    cli)
        src="$KCB/plugins/cli_containerbuild.py"
        dest_dir="/usr/lib/$PYTHON/site-packages/koji_cli_plugins/"
        ;;
    hub|builder)
        src="$KCB/plugins/${plugin}_containerbuild.py"
        dest_dir="/usr/lib/koji-$plugin-plugins/"
        ;;
    *)
        echo "ERROR: unkown plugin: $plugin" >&2
        echo "Available plugins: cli, hub, builder" >&2
        exit 1
        ;;
esac

if [ ! -e "$src" ]; then
    echo "ERROR: could not find $plugin plugin in $KCB" >&2
    exit 1
fi

mkdir -p "$dest_dir"
cp "$src" "$dest_dir"
echo "Succesfully copied $src to $dest_dir"
