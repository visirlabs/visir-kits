#!/bin/bash
# Fails closed: any unexpected error aborts before the shell is handed over.
#
# A check declares "# check: <name>", exits 0 to pass or 1 to fail with a
# one-line reason on stdout.
set -eu

checks_dir="${1:-$(dirname "$0")/checks}"

failed=0
pass() { echo "visir: PASS  $1"; }
fail() {
	echo "visir: FAIL  $1${2:+ — $2}" >&2
	failed=1
}

run_check() {
	local check="$1"
	local label output status

	label="$(sed -n 's/^# check: //p' "$check" | head -n 1)"
	if [ -z "$label" ]; then
		fail "${check##*/}" "no '# check: <name>' line"
		return
	fi

	# Run with bash rather than execute, so a lost exec bit cannot skip a check.
	output="$(bash "$check" 2>&1)" && status=0 || status=$?
	case "$status" in
	0) pass "$label" ;;
	1) fail "$label" "$output" ;;
	*) fail "$label" "unclear exit $status${output:+ — $output}" ;;
	esac
}

shopt -s nullglob
checks=("$checks_dir"/*.sh)

if [ "${#checks[@]}" -eq 0 ]; then
	fail "checks are available" "no checks in $checks_dir"
else
	for check in "${checks[@]}"; do
		run_check "$check"
	done
fi

if [ "$failed" -ne 0 ]; then
	echo "visir: refusing entry" >&2
	exit 1
fi
echo "visir: all checks passed"
# Installed per entry, only once entry is granted, so existing sandboxes get opencode without recreation
command -v opencode >/dev/null || npm install -g opencode-ai

exec bash -l
