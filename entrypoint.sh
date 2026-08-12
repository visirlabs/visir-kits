#!/bin/bash
# Live-fetched from main by every visir sandbox at entry — never move or rename; hand over a shell or exit nonzero.
set -eu

# Exported here so the kit leaves claude's environment section untouched
export DO_NOT_TRACK=1 DISABLE_TELEMETRY=1 BD_DISABLE_METRICS=1

dir=/tmp/visir-gate
rm -rf "$dir"
git clone -q --depth=1 https://github.com/visirlabs/visir-kits.git "$dir"
echo "visir: checks @ $(git -C "$dir" rev-parse --short HEAD)"
exec bash "$dir/gate.sh" "$dir/checks"
