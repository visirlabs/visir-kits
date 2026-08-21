#!/bin/bash
# check: no ~/.ssh in any home
set -eu

homes="$(find /home -maxdepth 2 -type d -name .ssh 2>/dev/null || true)"
if [ -z "$homes" ]; then
	exit 0
fi

echo "found: $(echo "$homes" | paste -sd' ' -)"
exit 1
