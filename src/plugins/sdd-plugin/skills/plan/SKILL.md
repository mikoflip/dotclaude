---
name: plan
description: Turn a ready spec into an actionable implementation plan with a task checklist under _plans/. Use when the user wants to plan, break down, or scope implementation for an existing spec.
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Bash]
---

Turn the current worktree's spec into a numbered plan file under `_plans/` of the current project.

## Execution Steps
1. Bash `git branch --show-current`. If output is empty (detached HEAD) or is `main`/`master`, print `Not on a dedicated feature branch (currently: {branch, or "detached HEAD" if empty}). Run /sdd:preflight first.` and *STOP*. Otherwise set `feature_slug` to that branch name verbatim
2. Glob `_specs/*.md`. Keep only matches whose filename, after stripping the leading `{N}-` numeric prefix, equals `{feature_slug}.md` exactly — a shorter slug can otherwise falsely suffix-match a longer, unrelated one (e.g. slug `dashboard` matching `003-feat-card-component-dashboard.md`, whose actual slug is `feat-card-component-dashboard`). If no match, print `No spec found for slug {feature_slug}. Run /sdd:specify first.` and *STOP*
3. If more than one file matched, read each candidate's frontmatter `status` to select one: prefer `status: ready`; if none or more than one qualify, prefer the highest-numbered `N`. Otherwise, the single match from Step 2 is the selected file. Extract `N` from the selected file's filename prefix (`{N}-{feature_slug}.md`) and read its frontmatter `status`
4. If `status` is not `ready`, ask `Spec _specs/{N}-{feature_slug}.md is already {status}. Re-plan anyway? This overwrites _plans/{N}-{feature_slug}.md if it exists. [y/n]` and wait for input. If the response isn't an explicit yes, print `Cancelled.` and *STOP*
5. Draft plan content using the structure in [Plan Template](templates/plan.md) and the voice/structure rules in [Formatting Guide](references/formatting-guide.md), based on the spec's Goals, Requirements, and User Stories. Break the work into tasks, each prefixed with a sequential ID (`T001`, `T002`, ...) and directly executable by `/sdd:implement` — no vague or catch-all tasks. Include the file path in a task's description only when creating a new file (the path is a planning decision at that point); omit it for tasks that edit existing code, since `/sdd:implement` locates those files itself via `Glob`/`Grep`. Carry over any of the spec's Open Questions not resolved during planning. Set frontmatter `status: ready`, `slug: {feature_slug}`, `spec: _specs/{N}-{feature_slug}.md`, `created: {today's date, YYYY-MM-DD}`
6. Write the drafted plan to `_plans/{N}-{feature_slug}.md`. If exits non-zero, print error verbatim and *STOP*
7. Edit `_specs/{N}-{feature_slug}.md` frontmatter to set `status: planned`. If the edit fails, print error verbatim and *STOP*
8. Print:
   ```
   **Plan Created**
   Plan file: `_plans/{N}-{feature_slug}.md`
   Spec: `_specs/{N}-{feature_slug}.md` → status: planned
   Tasks: {TASK_COUNT}
   ```
   Then *STOP*

## Constraints
- Modify at most 2 files: the new/overwritten `_plans/{N}-{feature_slug}.md`, and `_specs/{N}-{feature_slug}.md` (status flip only, no other edits)
- Plan content follows [Plan Template](templates/plan.md) structure exactly
- Plan prose follows [Formatting Guide](references/formatting-guide.md) — no hedged, marketing, or meta-narrated language
- Every task is a checkbox (`- [ ] T{NNN} ...`) directly actionable by `/sdd:implement` — never a vague catch-all
- Never flip the spec's status before the plan file is written successfully
- Print the Step 8 block only — no additional commentary, and never repeat the full plan content unless the user explicitly asks to see it

## Example Output

### Not on a dedicated feature branch:
`Not on a dedicated feature branch (currently: main). Run /sdd:preflight first.`

### No spec found:
`No spec found for slug feat-card-component-dashboard. Run /sdd:specify first.`

### Spec already planned, awaiting confirmation:
`Spec _specs/003-feat-card-component-dashboard.md is already planned. Re-plan anyway? This overwrites _plans/003-feat-card-component-dashboard.md if it exists. [y/n]`

### Re-plan declined:
`Cancelled.`

### Plan written successfully:
```
**Plan Created**
Plan file: `_plans/003-feat-card-component-dashboard.md`
Spec: `_specs/003-feat-card-component-dashboard.md` → status: planned
Tasks: 6
```
