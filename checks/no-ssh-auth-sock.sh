#!/bin/bash
# check: SSH_AUTH_SOCK names nothing
set -eu

# A path that names nothing is inert — sbx v0.42+ sets a dangling one in every
# sandbox, even with agent forwarding disabled. Anything at the path counts, live or not.
# Also scan PID 1: an exec'd gate does not inherit what sbx set on init.
own="${SSH_AUTH_SOCK:-}"
pid1="$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | sed -n 's/^SSH_AUTH_SOCK=//p' || true)"

present="$(printf '%s\n%s\n' "$own" "$pid1" | sort -u | while IFS= read -r sock; do
	[ -n "$sock" ] || continue
	if [ -e "$sock" ] || [ -L "$sock" ]; then
		echo "$sock"
	fi
done)"

if [ -z "$present" ]; then
	exit 0
fi

echo "found: $(echo "$present" | paste -sd' ' -)"
exit 1
