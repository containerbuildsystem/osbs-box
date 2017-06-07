#!/bin/bash
set -xeuo pipefail

koji add-host kojibuilder x86_64
koji add-host-to-channel kojibuilder container --new
