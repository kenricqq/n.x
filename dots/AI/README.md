# Shared agent configuration

Home Manager links `~/.agents/skills` to `dots/AI/skills` and
`~/.codex/AGENTS.md` to `dots/AI/AGENTS.md` on Linux and Darwin.
`~/.codex/skills` remains linked to `dots/codex/skills` for Codex's system skills.
Keep each shared skill name in the shared collection only.

## Updating skills

`bun-install` and `bun-update` in `hm/setup.nix` manage the upstream skills.
Their global installation destination resolves through the shared symlink, so
updates appear as repository changes. Review those changes before committing.
Impeccable uses its dedicated installer and updater; the other skill repositories
use the `skills` CLI.

Impeccable's platform engine under `skills/impeccable/scripts/bin/` is ignored by
Git. Its tracked launcher and `VERSION` file support downloading the pinned engine
on another machine; the installer also supplies the platform engine.

## Skill selection

Keep one version of each skill and delete superseded copies. Unique skills that
were previously inactive remain available for explicit invocation, with
`policy.allow_implicit_invocation: false` in their `agents/openai.yaml` metadata.

Darwin's `agent-policy-hook.mjs` uses the JavaScript hook runtime in
`dots/codex/hooks/impeccable`. That directory contains the required runtime code,
not another skill installation.

After changing this layout, resolve both skill symlinks, check that discovered
skill names are unique, and evaluate the Home Manager links for Linux and Darwin.
