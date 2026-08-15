# dotclaude

Dotfiles-style configuration manager for [Claude Code](https://claude.ai/code). Everything under `src/` is symlinked into `~/.claude` by `install.sh`, keeping version-controlled config separate from runtime state.

## Install

```bash
git clone <repo> dotclaude
cd dotclaude
./install.sh
```

Run `./status.sh` to verify the installation.

## Scripts

| Command | Description |
|---|---|
| `./install.sh` | Symlink `src/` into `~/.claude` and register plugins (idempotent) |
| `./install.sh --dry-run` | Preview without making changes |
| `./install.sh --uninstall` | Remove managed symlinks and unregister plugins |
| `./reset-claude.sh` | Archive `~/.claude`, then re-run `install.sh` (preserves auth) |
| `./reset-claude.sh --dry-run` | Preview without making changes |
| `./reset-claude.sh --full` | Also archive `~/.claude.json` (requires re-login) |
| `./status.sh` | Check symlink integrity and plugin registration |
| `./status.sh --short` | CI-friendly one-liner (exit 1 if unhealthy) |

## Structure

```
src/
├── CLAUDE.md         # Global Claude Code instructions
├── settings.json     # Hooks, plugins, effortLevel
├── hooks/            # Scripts triggered by Claude Code events
├── plugins/          # Local plugin marketplace
├── skills/           # Local skills (non-plugin)
├── agents/           # Remote agents
├── commands/         # Slash commands
└── knowledge/        # Personal working notes and references
```

`install.sh` creates `~/.claude/<dir>/` as a real directory, then symlinks each child individually — letting Claude Code write runtime files without polluting the repo.

## Skills

| Skill | Trigger | Description |
|---|---|---|
| `generate-gitmessage` | `/generate-gitmessage` | Generate a git commit message from session context |
| `update-claude-md` | `/update-claude-md` | Update CLAUDE.md to reflect changes made in the session |

## Plugins

`src/plugins/` is registered as a local marketplace named `my-plugins`.

**skill-plugin**
- `/review` — audit a `SKILL.md` against the [Agent Skills spec](https://agentskills.io/specification)

**todo-plugin** — three composable skills meant to run in sequence:
- `/init-md` — scaffold `TODO.md` with priority sections
- `/suggest` — analyze the codebase and generate ranked improvement suggestions
- `/add` — convert selected suggestions into tracked TODO items

**analysis-plugin** — two web-research skills:
- `/compare` — produce a structured side-by-side comparison of two or more entries
- `/describe` — produce a structured description of any concept, technology, or topic

**sdd-plugin** — five composable skills for spec-driven development in a worktree-first workflow (each worktree/branch is one feature; skills derive the feature slug from the current branch name, no arguments needed except `project`'s and `specify`'s initial description):
- `/project` — capture a high-level project vision and goals in `README.md`, once, at project start (no branch requirement, unlike the rest of the pipeline)
- `/preflight` — check the working tree is clean and on a dedicated feature branch before starting
- `/specify` — turn a short feature idea into a numbered spec under `_specs/`
- `/plan` — turn a ready spec into a numbered implementation plan with a task checklist under `_plans/`
- `/implement` — execute a ready plan's task checklist against the codebase, resumable across invocations

## Adding Skills

**Simple skill** (preferred): add `src/skills/<skill-name>/SKILL.md`.

**Plugin skill**: add `src/plugins/<plugin-name>/skills/<skill-name>/SKILL.md` and register in `src/plugins/.claude-plugin/marketplace.json`.

After adding, run `./install.sh && ./status.sh`.
