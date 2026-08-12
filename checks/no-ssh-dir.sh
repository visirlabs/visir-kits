#!/bin/bash
# check: no ~/.ssh
set -eu

if [ ! -e "$HOME/.ssh" ]; then
	exit 0
fi

echo "$HOME/.ssh exists"
exit 1
