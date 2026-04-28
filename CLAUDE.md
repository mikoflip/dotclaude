# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Dotfiles-style configuration manager for Claude Code. Everything under `src/` is symlinked into `~/.claude` by `install.sh`, keeping version-controlled config separate from runtime state.

## Commands

```bash
./install.sh                 # Symlink src/ into ~/.claude and register plugins (idempotent)
./install.sh --dry-run       # Preview without making changes
./install.sh --uninstall     # Remove managed symlinks and unregister plugins
./reset-claude.sh            # Archive ~/.claude, then re-run install.sh (preserves auth)
./reset-claude.sh --dry-run  # Preview without making changes
./reset-claude.sh --full     # Also archive ~/.claude.json (requires re-login)
./status.sh                  # Check symlink integrity and plugin registration
./status.sh --short          # CI-friendly one-liner (exit 1 if unhealthy)
```

There is no build or test system. Run `./status.sh` after changes to verify correctness.

## Architecture

```
dotclaude/
├── install.sh        # Symlink manager (entry point)
├── reset-claude.sh   # Archive ~/.claude then call install.sh
├── status.sh         # Health checker
└── src/              # Everything here gets deployed to ~/.claude
    ├── CLAUDE.md         # Global Claude Code instructions (not this file)
    ├── settings.json     # Hooks, plugins, effortLevel
    ├── hooks/            # Scripts triggered by Claude Code events
    ├── plugins/          # Local plugin marketplace
    ├── skills/           # Local skills (non-plugin)
    ├── agents/           # Remote agents
    └── commands/         # Slash commands
```

**Symlink model:** `install.sh` creates `~/.claude/<dir>/` as a real directory, then symlinks each child individually. This lets Claude Code write runtime files into `~/.claude` without polluting the repo.

**Plugin system:** `src/plugins/` is registered as a local marketplace named `my-plugins` (defined in `src/plugins/.claude-plugin/marketplace.json`). Each subdirectory is a plugin containing a `skills/` tree of `SKILL.md` files.

**Two CLAUDE.md files:** `src/CLAUDE.md` is the global Claude Code config (symlinked to `~/.claude/CLAUDE.md`). This root `CLAUDE.md` documents the repo itself.

## Adding Skills

**Simple skills** (preferred for standalone use): add a directory under `src/skills/<skill-name>/SKILL.md`.

**Plugin skills** (for grouped/related skills): add under `src/plugins/<plugin-name>/skills/<skill-name>/SKILL.md` and register the plugin in `src/plugins/.claude-plugin/marketplace.json`.

All skills follow the [Agent Skills spec](https://agentskills.io/specification):

- Frontmatter: `name`, `description`, `allowed-tools`, optionally `disable-model-invocation`
- Numbered imperative steps with `*STOP*` barriers at decision points
- A `Constraints` section bounding output format and file modifications
- Supporting files (`templates/`, `references/`, `scripts/`) alongside `SKILL.md`

After adding a skill, run `./install.sh` then `./status.sh` to verify deployment.

## Skills

**`src/skills/generate-gitmessage`** — generate a git commit message from session context following the emoji-scoped commit format.

**`src/skills/update-claude-md`** — update the project's CLAUDE.md to reflect changes made in the current session.

## Plugins

**skill-plugin** — `/review`: audits a SKILL.md against the Agent Skills spec.

**todo-plugin** — three composable skills meant to run in sequence:
1. `/init-md` — scaffold `TODO.md` with priority sections
2. `/suggest` — analyze the codebase and generate ranked improvement suggestions
3. `/add` — convert selected suggestions into tracked TODO items
