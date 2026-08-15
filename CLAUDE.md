# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Dotfiles-style configuration manager for Claude Code. Everything under `src/` is symlinked into `~/.claude` by `install.sh`, keeping version-controlled config separate from runtime state. See README.md for install steps, the full command reference, the `src/` structure diagram, and the current skills/plugins catalog.

## Commands

There is no build or test system. Run `./status.sh` after changes to verify correctness.

## Architecture

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
