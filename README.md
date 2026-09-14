# visir-kits

Visir adds security checks to [sbx](https://docs.docker.com/ai/sandboxes/)
sandboxes and blocks entry if a check fails.

All commands below work in bash and PowerShell.

## 1. Prerequisites

- [sbx](https://docs.docker.com/ai/sandboxes/) (requires a Docker account).
  Visir is tested against sbx v0.42.1; other versions may break it.

Verify that sbx is installed before continuing:

```bash
sbx version
```

Visir blocks entry while sbx forwards an SSH agent into sandboxes, which sbx
does by default. Turn forwarding off once per host; the restart stops all
running sandboxes:

```bash
sbx settings set ssh.agentForwardingEnabled false
sbx daemon restart
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
sbx run docker.io/visirlabs/visir:latest
```

The first run creates a sandbox named `visir-` plus your project's directory name.
Every run fetches the latest checks and runs them.
If any check fails, Visir blocks entry.
If all checks pass, Visir starts the agent.

The same command re-enters the sandbox later, as does `sbx run --name visir-your-project`.
Pass agent flags after `--`, e.g. `sbx run docker.io/visirlabs/visir:latest -- --resume`.

The sandbox is built on sbx's `claude` agent unless you pick another built-in
agent when it is first created:

```bash
sbx run docker.io/visirlabs/visir:latest --kit-arg visir.base=codex
```

`base` accepts `claude`, `codex`, `copilot`, `cursor`, `devin`, `docker-agent`,
`droid`, `gemini`, `kiro`, `opencode` and `shell`, and is fixed at create time
(`sbx rm` and re-run to change it). `base=shell`, and any sandbox created
before this behavior shipped, drops straight into a shell instead.

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

## Optional kits

Extra tooling is opt-in. The baseline `visir` kit is only the gate and its
network policy; stack a mixin kit onto `sbx run` to add a tool to a new sandbox.

| Kit | Installs |
|---|---|
| `opencode` | the [opencode](https://opencode.ai) CLI, its model-provider credentials, and the sandbox MCP gateway |
| `az-cli` | the Azure CLI (`az`) and the `azure-devops` extension |

```bash
sbx settings set kit.allowedSources '["docker.io/","github.com/visirlabs/"]'
sbx run docker.io/visirlabs/visir:latest \
  --kit "git+https://github.com/visirlabs/visir-kits.git#dir=opencode"
```

Re-enter that sandbox with the plain command from [Run](#3-run): sbx accepts
`--kit` only when it creates a sandbox.

A mixin can also be added afterwards: `sbx kit add <sandbox> <ref>` recreates
the sandbox's container with the kit appended, keeping the workspace and the
agent's session state.

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
that script clones it, runs `gate.sh` against `checks/`, and — once the gate
passes — hands off to `enter.sh`, which waits for Enter and launches the
agent (or, for `base=shell`, hands over a shell directly). That is what keeps
existing sandboxes current without recreation.

To reference the visir-kits repo directly instead of Docker Hub, allow it as
a kit source once per host:

```bash
sbx settings set kit.allowedSources '["docker.io/","github.com/visirlabs/"]'
sbx run "git+https://github.com/visirlabs/visir-kits.git#dir=visir"
```
