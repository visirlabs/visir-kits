#!/bin/bash
# check: no SSH environment variables
set -eu

# Also scan PID 1: an exec'd gate does not inherit what sbx set on init.
own="$(env | grep '^SSH_' || true)"
pid1="$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | grep '^SSH_' || true)"

found="$(printf '%s\n%s' "$own" "$pid1" | grep . || true)"
if [ -z "$found" ]; then
	exit 0
fi

echo "found: $(echo "$found" | cut -d= -f1 | sort -u | paste -sd' ' -)"
exit 1
