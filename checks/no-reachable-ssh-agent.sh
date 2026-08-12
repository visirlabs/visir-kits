#!/bin/bash
# check: no reachable ssh-agent
set -eu

# Probe reachability rather than trusting SSH_AUTH_SOCK — sbx sets it even
# for dead sockets (docker/sbx-releases#247). Without ssh-add this passes
# vacuously, which is why the socket-name scan stays the primary signal.
command -v ssh-add > /dev/null 2>&1 || exit 0

failed=0
reasons=""
seen=""
for sock in /run/ssh-agent.sock "${SSH_AUTH_SOCK:-}"; do
	[ -n "$sock" ] && [ -S "$sock" ] || continue
	case " $seen " in *" $sock "*) continue ;; esac
	seen="$seen $sock"

	out="$(SSH_AUTH_SOCK="$sock" ssh-add -l 2>&1)" && rc=0 || rc=$?
	case "$rc" in
	0)
		reasons="${reasons:+$reasons; }$sock is live, $(echo "$out" | wc -l) identity(ies) usable from inside"
		failed=1
		;;
	1)
		reasons="${reasons:+$reasons; }$sock is live but holds no identities"
		failed=1
		;;
	*) ;; # socket exists but no agent answers — covered by the socket scan
	esac
done

if [ "$failed" -ne 0 ]; then
	echo "found: $reasons"
	exit 1
fi
exit 0
