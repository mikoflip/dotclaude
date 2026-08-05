---
name: implement
description: Execute a ready plan's task checklist directly against the codebase, resuming from the first unchecked task on every invocation. Use when the user wants to implement, build, or execute an existing plan.
disable-model-invocation: true
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

Execute the current worktree's plan checklist under `_plans/` of the current project.

## Execution Steps
1. Bash `git branch --show-current`. If output is empty (detached HEAD) or is `main`/`master`, print `Not on a dedicated feature branch (currently: {branch, or "detached HEAD" if empty}). Run /sdd:preflight first.` and *STOP*. Otherwise set `feature_slug` to that branch name verbatim
2. Glob `_plans/*.md`. Keep only matches whose filename, after stripping the leading `{N}-` numeric prefix, equals `{feature_slug}.md` exactly — a shorter slug can otherwise falsely suffix-match a longer, unrelated one (e.g. slug `dashboard` matching `003-feat-card-component-dashboard.md`, whose actual slug is `feat-card-component-dashboard`). If no match, print `No plan found for slug {feature_slug}. Run /sdd:plan first.` and *STOP*
3. If more than one file matched, read each candidate's frontmatter `status` to select one: prefer `status: ready`; if none or more than one qualify, prefer the highest-numbered `N`. Otherwise, the single match from Step 2 is the selected file. Read the selected plan file fresh from disk — even if it was read earlier this session, re-read it now. Extract `N` from its filename prefix (`{N}-{feature_slug}.md`). Read its frontmatter `status`
4. If `status` is `implemented`, ask `Plan _plans/{N}-{feature_slug}.md is already implemented. Re-run anyway? [y/n]` and wait for input. If the response isn't an explicit yes, print `Cancelled.` and *STOP*
5. Parse the `## Tasks` checklist for unchecked items (`- [ ] T{NNN} ...`)
6. Take the first unchecked task. If none remain, skip to Step 10
7. Execute exactly what the task describes, using whatever of `Read, Edit, Write, Glob, Grep, Bash` it requires. If the task names a file (typically a new file being created), use it directly; if it doesn't, locate the relevant file(s) with `Glob`/`Grep` before editing. If the task's intent is ambiguous or requires a decision the plan doesn't specify, ask `Task T{NNN} is ambiguous: {question}`, wait for the user's reply in this same turn, then resume executing the task using that answer — this is not a terminal stop like Step 9's failure case
8. On success, Edit the plan to flip the task's line from `- [ ]` to `- [x]`, print `Completed: T{NNN} {TASK_DESCRIPTION}`, then return to Step 6 for the next unchecked task
9. On failure, print the error verbatim, leave the task unchecked, print `Task T{NNN} failed. Re-run /sdd:implement to retry.`, then *STOP* — no further tasks, no status flip
10. Once no unchecked tasks remain (whether Step 8 completed all of them, or Step 5 found none to begin with), Edit the plan's frontmatter to set `status: implemented`, skipping the edit if it's already set. If the edit fails, print error verbatim and *STOP*
11. Print:
    ```
    **Implementation Complete**
    Plan file: `_plans/{N}-{feature_slug}.md` → status: implemented
    Tasks completed this run: {COUNT}
    ```
    Then *STOP*

## Constraints
- Only modify files the executing task calls for, plus `_plans/{N}-{feature_slug}.md` itself (checkbox edits and the final status flip) — nothing else
- Always re-read the plan fresh from disk at the start of every invocation — never rely on an earlier read from this session
- Execute unchecked tasks strictly in order — never skip ahead, never batch or parallelize
- A failed task stays unchecked and halts the run — plan `status` is never flipped to `implemented` on a partial or failed run
- Print `Completed: T{NNN} ...` per finished task, plus the Step 11 summary at the end — no other commentary between tasks

## Example Output

### Not on a dedicated feature branch:
`Not on a dedicated feature branch (currently: main). Run /sdd:preflight first.`

### No plan found:
`No plan found for slug feat-card-component-dashboard. Run /sdd:plan first.`

### Plan already implemented, awaiting confirmation:
`Plan _plans/003-feat-card-component-dashboard.md is already implemented. Re-run anyway? [y/n]`

### Re-run declined:
`Cancelled.`

### Task is ambiguous:
`Task T002 is ambiguous: should the dashboard layout use a grid or flex container?`

### Task fails mid-run:
```
npm error ENOENT: no such file or directory, open 'src/components/StatsCard.tsx'
Task T003 failed. Re-run /sdd:implement to retry.
```

### Status-flip edit fails after all tasks complete:
```
Completed: T001 Create StatsCard component in src/components/StatsCard.tsx

No edit made: old_string not found in _plans/003-feat-card-component-dashboard.md
```

### All tasks completed successfully (T001 creates a new file — path is part of the description; T002/T003 edit existing code — no path, located via Glob/Grep at execution time):
```
Completed: T001 Create StatsCard component in src/components/StatsCard.tsx
Completed: T002 Add StatsCard to the dashboard layout
Completed: T003 Wire task counts query into StatsCard

**Implementation Complete**
Plan file: `_plans/003-feat-card-component-dashboard.md` → status: implemented
Tasks completed this run: 3
```
