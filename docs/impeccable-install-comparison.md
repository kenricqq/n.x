# Impeccable installation routes

Checked 2026-09-12 against official documentation. No installer was run.

Both commands install the same Impeccable project. `bunx` is the package runner; the meaningful choice is **Impeccable's own installer versus the generic skills installer**. Bun documents `bunx` as its equivalent of `npx`. ([Bun documentation](https://bun.sh/docs/pm/bunx), [Impeccable install options](https://impeccable.style/docs/))

| Route | Installed result | Update command |
| --- | --- | --- |
| `bunx impeccable@latest install` | Tool-specific build, with supported tool integrations. Prompts for provider and project/global scope. | `bunx impeccable@latest update` |
| `bunx skills@latest add pbakaus/impeccable` | Shared Impeccable skill, managed alongside other skills. | `bunx skills@latest update impeccable` |

Impeccable recommends its own installer for integrations tailored to the coding tool; its documentation also supports the shared skills route. Update using the route that installed the skill. ([Impeccable documentation](https://impeccable.style/docs/), [update FAQ](https://impeccable.style/faq/))

The dedicated installer can install automatic design-check hooks for supported tools. For Codex, the skill goes in `.agents/skills/` for a project or `~/.agents/skills/` globally; hooks remain project-local in `.codex/hooks.json`. Interactive installation offers hook consent, and `--no-hooks` skips hooks for that run. Provider and scope can be specified with `--providers=codex --scope=global`. A global skill installation therefore does not make project hooks global. These are Impeccable's documented integration behaviors, not a verification of this machine's active Codex hooks. ([Impeccable README](https://github.com/pbakaus/impeccable#installation))

The generic skills installer defaults to project scope; `-g` selects global installation, `-a codex` selects Codex, and `-y` skips prompts. It supports a canonical copy with symlinks into agent directories or separate copies. Its current documented global Codex destination is `~/.codex/skills/`. Therefore, two directory entries can be symlinks to one payload, while two installation declarations do not prove either command has run. ([Skills README](https://github.com/vercel-labs/skills#readme))

For this setup, choose one owner for Impeccable. Prefer the dedicated installer when tool-specific guidance and hooks are wanted; prefer the skills route when managing a shared skill with the existing global skills collection. Explicit provider/scope flags are appropriate for a repeatable setup command. Do not run both installation routes over the same skill as part of routine setup.
