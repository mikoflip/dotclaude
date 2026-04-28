---
name: init-md
description: Initialize a new TODO.md from a structured template, auto-populating project name, tech stack, and current state from the codebase. Backs up any existing TODO.md before overwriting. Use when the user wants to create, scaffold, set up, reset, or initialize a TODO.md.
disable-model-invocation: true
allowed-tools: [Read, Edit, Bash]
---

## Execution Steps
1. Bash `${CLAUDE_SKILL_DIR}/scripts/backup-todo.sh`. Capture stdout as `FILENAME`. If exits non-zero, print error verbatim and *STOP*. Empty stdout is expected when no `./TODO.md` exists (no backup needed)
2. Bash `cp "${CLAUDE_SKILL_DIR}/templates/TODO.md" ./TODO.md`. If exits non-zero, print error verbatim and *STOP*
3. Determine project details from file and folder structure using Bash `ls -la` and Read key top-level files (e.g. `README.md`, `package.json`, `pyproject.toml`, `build.gradle`)
4. Edit `./TODO.md` to replace placeholders (`{PROJECT_NAME}`, `{TYPE_AND_BRIEF_DESCRIPTION}`, `{KEY_TECHNOLOGIES/FRAMEWORKS}`, `{STATUS_SUMMARY}`, `{YYYY-MM-DD}`) with project-specific values. Leave placeholder as-is for undetermined values
5. Print `TODO.md initialized successfully.`. If `$FILENAME` is non-empty (backup was created in Step 1), append `Original file backed up as: $FILENAME.`. Then *STOP* 

## Constraints
- Modify at most 2 files: `./TODO.md` and backup (if one was created)
- Print success message only — no additional commentary

## Example Output

### Backup script fails (e.g. permission error on existing TODO.md):
`mv: ./TODO.md: Permission denied`

### Copying template fails (e.g. missing template file):
`cp: ${CLAUDE_SKILL_DIR}/templates/TODO.md: No such file or directory`

### Initialization success (no existing TODO.md):
`TODO.md initialized successfully.`

### Initialization success (existing TODO.md backed up):
`TODO.md initialized successfully. Original file backed up as: TODO_backup_20240315_142301.md.`

### Example Context section after Step 3:
```
## Context
- **Project Type**: REST API for user authentication
- **Tech Stack**: Node.js, Express, PostgreSQL, JWT
- **Current State**: Auth endpoints implemented; refresh token flow in progress
- **Last Updated**: 2024-03-15
```
