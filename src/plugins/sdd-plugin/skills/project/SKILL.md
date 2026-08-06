---
name: project
description: Capture a high-level project vision and goals in README.md, once, at project start. Use when the user wants to establish or record the overall vision, purpose, or goals for a new or existing project.
argument-hint: Short project description
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Bash]
---

Turn `$ARGUMENTS` into a `## Vision` section in `README.md`. Runs once, at project start — no branch or clean-tree requirement, unlike every other `/sdd:*` skill.

## Execution Steps
1. If `$ARGUMENTS` is empty, ask the user for a short description of what's being built and why, then *STOP* until they respond
2. Bash `[ -f README.md ] && echo exists || echo missing`
3. If `missing`: if `$ARGUMENTS` doesn't clearly name the project, ask the user for a short project title, then *STOP* until they respond (never derive the title from the working directory — worktree-first means the directory name may be a worktree/branch name, not the project name). Once `title` is known, write `README.md` as `# {title}\n\n## Vision\n{paragraph}\n\n### Goals\n- {goal}\n- {goal}\n`, where `{paragraph}` (1-2 sentences, what's being built and why) and each `{goal}` are derived from `$ARGUMENTS`. If the write fails, print the error verbatim and *STOP*. Print `**Vision Captured**\nREADME.md created with Vision section.` then *STOP*
4. If `exists`, read `README.md`. If any heading's text (stripped of leading `#`s) contains the whole word `vision`, `overview`, `about`, or `purpose`, case-insensitive, print `README.md already has a "{heading text}" section. Edit it manually — /sdd:project does not overwrite existing content.` then *STOP*
5. If no top-level `# ` heading exists, print `README.md has no top-level # heading. Add one, then re-run /sdd:project.` then *STOP*
6. Edit `README.md` to insert `## Vision\n{paragraph}\n\n### Goals\n- {goal}\n- {goal}\n` (same derivation as Step 3) directly beneath the `# ` title line, above all existing content. If the edit fails, print the error verbatim and *STOP*. Print `**Vision Captured**\nREADME.md updated with Vision section.` then *STOP*

## Constraints
- Modify at most 1 file: `README.md` — create it fresh, or insert into it; never overwrite or rewrite existing content
- Never derive a project title from the working directory or branch name — ask the user if `$ARGUMENTS` doesn't name the project
- Insert `## Vision` only directly beneath the top-level `# ` title — stop rather than guess if no `# ` heading exists or an overview-like heading is already present
- Vision prose: plain declarative sentences — no hedging ("should ideally"), no marketing adjectives (seamless, powerful, robust), no meta-narration ("this section describes...")
- No frontmatter, no status tracking, no numbered file scheme — this skill owns one section of one file
- Print the confirmation block only — no additional commentary, and never repeat the full README content unless the user explicitly asks to see it

## Example Output

### Arguments empty:
`What's the vision for this project? Give me a short description of what you're building and why.`

### README.md missing, title not derivable from arguments:
`What's the project called?`

### README.md missing, created fresh:
```
**Vision Captured**
README.md created with Vision section.
```

### README.md exists, already has an overview-like section:
`README.md already has a "Overview" section. Edit it manually — /sdd:project does not overwrite existing content.`

### README.md exists, no top-level heading:
`README.md has no top-level # heading. Add one, then re-run /sdd:project.`

### README.md exists, Vision section inserted beneath title:
```
**Vision Captured**
README.md updated with Vision section.
```
