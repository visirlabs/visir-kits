# visir-kits

Kits for [sbx](https://docs.docker.com/ai/sandboxes/) that gate sandbox entry behind visir's security checks.

## Use

Allow this repo as a kit source (once per host):

```bash
sbx settings set kit.allowedSources '["docker.io/","github.com/visirlabs/"]'
```

Create and enter a sandbox from your project directory:

```bash
sbx run visir --kit "git+https://github.com/visirlabs/visir-kits.git#dir=visir"
```

Entry runs the checks and is refused if any fail. The same command re-enters the sandbox later, as does `sbx run --name visir-<your-project-dir>`.

## How it works

The kit's entrypoint fetches `entrypoint.sh` from this repo at every entry; that script clones this repo and runs `gate.sh` against `checks/`. Check and gate updates therefore reach existing sandboxes at their next entry — no sandbox recreation needed.
