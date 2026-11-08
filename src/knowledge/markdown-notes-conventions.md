# Markdown Notes Conventions

## Overview
Conventions for **Markdown Notes**: the user's vault of plain Markdown files, synced through iCloud Drive, edited on the Mac through Claude Code and on mobile with any Markdown editor. On the Mac it's reached as `~/Developer/notes` (a symlink into iCloud Drive).

Markdown Notes is the home for structured notes: development planning notes (`Developer/`) and job applications (`Job Applications/`). **Apple Notes** stays in use for informal notes — see [apple-notes-conventions.md](apple-notes-conventions.md). Where that file describes planning notes, their template, or the Style Guide, this file takes precedence.

## Structure
- `Developer/` — planning notes for development projects, one subfolder per project, named exactly like the project's repository (e.g. `ResumeInBlazor/`, `dotclaude/`)
- `Job Applications/` — application threads, one subfolder per vacancy; its own `CLAUDE.md` holds the area conventions
- `_templates/` — templates per area (`Developer/_templates/`, `Job Applications/_templates/`)
- Folders created by the editor app (e.g. `Welcome/`, `Trash/`) — never touch

The vault's own `CLAUDE.md` files are authoritative for area-specific rules — read the root `CLAUDE.md` and, for job applications, `Job Applications/CLAUDE.md` before creating or editing notes there.

## Naming and numbering
- Files: `NNN-kebab-title.md` — zero-padded 3-digit number, one sequence per project folder (not reset per effort or note type)
- First line of every note is an H1 with the readable title: `# NNN - Title`. Don't repeat the project name; the folder scopes it
- Project folders under `Developer/` keep the repository's exact name (no kebab-casing). In a worktree-first layout, that's the bare repository's directory name — never the worktree or branch name
- Cross-references use the number (e.g. "see 006")

## Planning notes
Start from `Developer/_templates/planning-note-template.md` and keep all its sections; use "None." for empty ones. Key Decisions take the form `**A vs B (context) → Chosen:** rationale`. Checklists use `- [ ]` / `- [x]`.

## Working rules

### Verify before acting
Read a note before editing, summarising, or referencing it — never infer content from the file name. List the folder to find the next `NNN` rather than guessing.

### Confirm before writing
Show a draft or diff and get explicit confirmation before creating, editing, renaming, or moving a note or folder. Preserve every section not explicitly being changed.

### Never delete
Never delete notes or folders; ask the user to do it.

### Verify writes
Re-read the file after writing.

### Match existing conventions
Follow the language, tone, and formatting of the surrounding notes — English for `Developer/`, Dutch for `Job Applications/`.

### Handle sensitive content with care
Notes may hold sensitive data. Reference it only as far as the task needs, and never copy it into external destinations (messages, uploads, third-party services, public repositories) without explicit instruction.

## Sync
- No `.git` inside the vault — it breaks iCloud sync. Version history is kept outside the synced folder
- Conflict copies appear as `… 2.md`; check for them after editing a note that may also have been edited on another device
- Paths contain spaces (`Mobile Documents`, `Job Applications`) — quote them in shell commands
- `.markdownlint.json` at the vault root disables MD013 (line length) and MD036 (emphasis as heading)
