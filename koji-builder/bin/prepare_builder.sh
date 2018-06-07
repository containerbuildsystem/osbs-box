#!/bin/bash
set -xeuo pipefail

koji add-host kojibuilder `uname -p`
koji add-host-to-channel kojibuilder container --new
