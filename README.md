# visir-kits

Visir adds security checks to [sbx](https://docs.docker.com/ai/sandboxes/)
sandboxes and blocks entry if a check fails.

All commands below work in bash and PowerShell.

## 1. Prerequisites

- [sbx](https://docs.docker.com/ai/sandboxes/) (requires a Docker account)

Verify that sbx is installed before continuing:

```bash
sbx version
```

## 2. Network policy

Visir is built for sbx's `deny-all` global network policy.
Initialize it before creating your first sandbox:

```bash
sbx policy init deny-all
```

> **Note**: If you already initialized a different policy, start over with
> `sbx policy reset` (this clears all custom rules).

## 3. Run

From your project directory:

```bash
sbx run visir --kit docker.io/visirlabs/visir:latest
```

The first run creates a sandbox named `visir-` plus your project's directory name.
Every run fetches the latest checks and runs them.
If any check fails, Visir blocks entry.
If all checks pass, you get a shell in the sandbox.
From there you can start an agent, e.g.:

```bash
claude --dangerously-skip-permissions
```

The same command re-enters the sandbox later, as does `sbx run --name visir-your-project`.

> **Note**: `sbx run` failures at startup are distinguished by their message:
>
> - `500 … docker daemon failed to start inside the sandbox` — the sandbox is
>   still booting; wait ~30 seconds and re-run. If it persists, restart Docker
>   (or the machine) — see
>   [docker/sbx-releases#350](https://github.com/docker/sbx-releases/issues/350).
> - `500 … container missing before start` — the sandbox is a leftover from an
>   interrupted create; `sbx rm` it and re-run.
> - No output at all (hangs) — the sbx daemon's backing engine is wedged;
>   `sbx daemon restart` (this stops all running sandboxes), then re-run.

## Upgrade

Checks and the gate update themselves: every entry fetches the latest from
the [visir-kits](https://github.com/visirlabs/visir-kits) repo,
so existing sandboxes pick up changes at their next entry.

Only changes to the kit spec itself (network policy, entrypoint) require
recreating the sandbox against the newest published kit. Removing a sandbox
deletes its entire state (e.g. agent and shell history) and cannot be undone:

```bash
sbx rm visir-your-project
```

Then see [Run](#3-run).

## How it works

The kit's entrypoint fetches `entrypoint.sh` from the
[visir-kits](https://github.com/visirlabs/visir-kits) repo at every entry;
that script clones it and runs `gate.sh` against `checks/`. That is what
keeps existing sandboxes current without recreation.

To reference the visir-kits repo directly instead of Docker Hub, allow it as
a kit source once per host:

```bash
sbx settings set kit.allowedSources '["docker.io/","github.com/visirlabs/"]'
sbx run visir --kit "git+https://github.com/visirlabs/visir-kits.git#dir=visir"
```
