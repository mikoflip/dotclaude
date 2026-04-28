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
└── commands/         # Slash commands
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

## Adding Skills

**Simple skill** (preferred): add `src/skills/<skill-name>/SKILL.md`.

**Plugin skill**: add `src/plugins/<plugin-name>/skills/<skill-name>/SKILL.md` and register in `src/plugins/.claude-plugin/marketplace.json`.

After adding, run `./install.sh && ./status.sh`.
