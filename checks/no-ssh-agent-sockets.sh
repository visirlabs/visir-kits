#!/bin/bash
# check: no ssh-agent sockets
set -eu

socks="$(find /tmp /run -maxdepth 4 -type s \( -name '*ssh*' -o -name 'agent.*' \) 2>/dev/null || true)"
if [ -z "$socks" ]; then
	exit 0
fi

echo "found: $(echo "$socks" | paste -sd' ' -)"
exit 1
