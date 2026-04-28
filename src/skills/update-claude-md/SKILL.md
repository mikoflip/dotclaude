---
name: update-claude-md
description: Update the project's CLAUDE.md to reflect changes made in this session — new commands, architecture shifts, added or removed components. Use when asked to update, refresh, or sync CLAUDE.md after making changes to a codebase, or when asked to document recent changes to the project.
allowed-tools: [Read, Edit]
---

Update CLAUDE.md to reflect what changed in this session. Edit only what's affected; leave accurate content untouched.

## Execution Steps
1. Read `CLAUDE.md`. If it does not exist, print `No CLAUDE.md found — use /init to create one` and *STOP*.
2. Review the changes made in this session. If no changes are visible in context, ask the user what changed before proceeding. *STOP* until answered.
3. Identify which sections need updating. Common triggers:
   - New or removed CLI commands → update the commands section
   - New files, directories, or components → update architecture/structure
   - New skills, plugins, or integrations → update the relevant inventory section
   - Changed conventions or patterns → update any section that describes them
   - Renamed or moved items → find and update every reference
4. Edit the identified sections. If no matching section exists, add a minimal one rather than forcing content into an unrelated section.
5. After editing, re-read the file and verify: no section contradicts the changes made, no stale references remain. Print a one-line summary of what changed (e.g. `CLAUDE.md updated — added generate-gitmessage to the Skills section.`). Then *STOP*.

## Rules
- Describe commands and architecture that aren't obvious from reading the code
- No generic advice ("write tests", "handle errors") — only project-specific facts
- Keep entries concise; one line per item is usually enough
- Prefer updating an existing section over adding a new one

## Constraints
- Only `CLAUDE.md` in the project root is modified.
- Do not reformat or reorder sections that weren't affected by the changes.
- Do not add placeholder or speculative content.

## Example Output

`CLAUDE.md updated — added generate-gitmessage to the Skills section.`
