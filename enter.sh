#!/bin/bash
# Runs after gate.sh passes. Starts the base agent, then hands over a shell
# regardless of how the agent exits — never exec the agent itself.
set -eu

base="${1-}"
[ $# -gt 0 ] && shift

# Copied verbatim, flags included, from each base's entrypoint in
# upstream/kits/<base>.yaml. Re-check on sbx upgrade (docs/sbx-upgrade-verification.md).
case "$base" in
claude) launch=(claude --dangerously-skip-permissions) ;;
codex) launch=(codex --dangerously-bypass-approvals-and-sandbox) ;;
copilot) launch=(copilot --yolo) ;;
cursor) launch=(cursor-agent --yolo) ;;
devin) launch=(devin --permission-mode dangerous --respect-workspace-trust=false) ;;
docker-agent) launch=(docker-agent run --yolo --agent-picker) ;;
droid) launch=(droid) ;;
gemini) launch=(gemini --yolo) ;;
kiro) launch=(kiro chat --trust-all-tools) ;;
opencode) launch=(opencode) ;;
*) launch=() ;;
esac

if [ "${#launch[@]}" -eq 0 ]; then
	exec bash -l
fi

echo "visir: press Enter to start ${launch[*]} — Ctrl+D for a shell"

# A handler rather than an ignore, so the agent starts with default SIGINT
# and this script survives a Ctrl+C during the wait or the agent's run. POSIX
# read resumes rather than failing when a trapped signal doesn't terminate the
# shell, so Ctrl+C at the wait is a no-op here, not a shortcut to the shell —
# Ctrl+D (real EOF) is the only way out of the wait.
trap : INT
if read -r; then
	# A login shell gives the agent the same PATH and /etc/sandbox-persistent.sh
	# it would get typed at the prompt. read fails on Ctrl+D and on EOF with no
	# terminal, both falling through to the shell below.
	bash -lc 'exec "$@"' visir-agent "${launch[@]}" "$@" || :
fi
trap - INT
exec bash -l
