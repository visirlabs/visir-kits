#!/bin/bash
# check: no SSH environment variables besides SSH_AUTH_SOCK
set -eu

# SSH_AUTH_SOCK is judged by what it names, not by being set: see no-ssh-auth-sock.sh.
# Also scan PID 1: an exec'd gate does not inherit what sbx set on init.
own="$(env | grep '^SSH_' | grep -v '^SSH_AUTH_SOCK=' || true)"
pid1="$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | grep '^SSH_' | grep -v '^SSH_AUTH_SOCK=' || true)"

found="$(printf '%s\n%s' "$own" "$pid1" | grep . || true)"
if [ -z "$found" ]; then
	exit 0
fi

echo "found: $(echo "$found" | cut -d= -f1 | sort -u | paste -sd' ' -)"
exit 1
