---
name: common-commands
description: Identify and summarize common commands and workflow for the current folder or repository. Use when users ask what commands to run, how to work in a repo, how to develop/test/build/lint/format, or want a quick project onboarding checklist.
---

# Common Commands

Help users learn the common commands and workflow for the current folder or repository.

## Goal

Return a concise, evidence-based command guide for the given folder/repo:

- Setup/install commands
- Development/run commands
- Test commands
- Lint/format/typecheck commands
- Build/package commands
- Useful maintenance commands
- Normal contributor workflow

Do not invent commands. Prefer commands found in repo files.

## Inspection Workflow

1. Identify current folder and repo root.
2. Inspect command sources, if present:
   - `README*`, `CONTRIBUTING*`, `docs/**`
   - `package.json`, `bun.lock`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`
   - `Makefile`, `justfile`, `Taskfile.yml`, `mise.toml`, `.envrc`
   - `pyproject.toml`, `uv.lock`, `requirements*.txt`, `tox.ini`, `noxfile.py`
   - `Cargo.toml`, `go.mod`, `deno.json`, `flake.nix`, `shell.nix`
   - CI files such as `.github/workflows/**`, `.gitlab-ci.yml`
3. Extract commands from scripts, targets, docs, and CI.
4. Prefer project-documented commands over inferred commands.
5. If commands conflict, show source and note uncertainty.
6. If command source missing, say so and give only safe discovery commands.

## Output Format

Use this structure:

```markdown
## Common Commands

### Setup

- `command` — purpose. Source: `file`

### Develop

- `command` — purpose. Source: `file`

### Test / Check

- `command` — purpose. Source: `file`

### Build / Package

- `command` — purpose. Source: `file`

### Workflow

1. Step
2. Step
3. Step

### Notes

- Caveat or missing info
```

Omit empty sections. Keep output short.

## Command Rules

- Use exact commands from repo files when available.
- Include working directory when command must run from subfolder.
- Mention required tools or package managers only when repo evidence shows them.
- Avoid destructive commands unless user asks and repo docs clearly include them.
- Do not run install, build, test, or mutation commands unless user asks.
- OK to run read-only inspection commands such as `find`, `rg`, `ls`, and file reads.

## Package Manager Detection

When multiple package managers are possible, use lockfiles and docs:

- `bun.lock` or `bun.lockb` → prefer `bun`
- `pnpm-lock.yaml` → prefer `pnpm`
- `yarn.lock` → prefer `yarn`
- `package-lock.json` → prefer `npm`
- `uv.lock` → prefer `uv`

If no lockfile exists, quote scripts without choosing a runner unless docs choose one.

## Useful Discovery Commands

Use read-only commands like:

```bash
pwd
find . -maxdepth 3 -type f \( -name 'README*' -o -name 'CONTRIBUTING*' -o -name 'package.json' -o -name 'Makefile' -o -name 'justfile' -o -name 'pyproject.toml' -o -name 'Cargo.toml' -o -name 'go.mod' -o -name 'flake.nix' \) -print
rg -n "(npm|pnpm|yarn|bun|make|just|cargo|go test|pytest|uv run|nix|docker compose)" README* CONTRIBUTING* docs .github 2>/dev/null
```

Adapt paths to the current folder. Prefer `read` for file contents.
