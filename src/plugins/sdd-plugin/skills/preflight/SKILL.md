---
name: preflight
description: Check whether the working tree is clean and on a dedicated feature branch before starting spec-driven work. Aborts with guidance if the tree is dirty or still on main/master. Use before /sdd:specify to confirm a clean, worktree-first starting point.
disable-model-invocation: true
allowed-tools: [Bash]
---

## Execution Steps
1. Bash `git status --porcelain`. If the command exits non-zero (e.g. not inside a git repository), print the error verbatim and *STOP*
2. If output is non-empty, the working tree has uncommitted, unstaged, or untracked changes. Print `Working tree is dirty. Commit or stash changes before running /sdd:specify.` followed by the raw output from Step 1, then *STOP*
3. Bash `git branch --show-current`. If output is empty (detached HEAD) or is `main`/`master`, print `Not on a dedicated feature branch (currently: {branch, or "detached HEAD" if empty}). Create a worktree first, e.g. git worktree add ../feat-<slug> -b feat-<slug>, before running /sdd:specify.` then *STOP*
4. The branch name itself is the `slug`, used verbatim (no prefix stripping)
5. Print `Working tree is clean. Detected worktree branch: {branch} (slug: {slug}). Ready for /sdd:specify.` then *STOP*

## Constraints
- Read-only — modifies no files
- Print status message only, no additional commentary
- Never runs `git add`, `git commit`, `git stash`, `git switch`, `git worktree add`, or any other state-changing git command

## Example Output

### Dirty tree:
```
Working tree is dirty. Commit or stash changes before running /sdd:specify.
 M src/plugins/sdd-plugin/skills/preflight/SKILL.md
?? _specs/
```

### Still on main:
```
Not on a dedicated feature branch (currently: main). Create a worktree first, e.g. git worktree add ../feat-<slug> -b feat-<slug>, before running /sdd:specify.
```

### Clean tree on a feature branch:
```
Working tree is clean. Detected worktree branch: feat-card-component-dashboard (slug: feat-card-component-dashboard). Ready for /sdd:specify.
```

### Not a git repository:
```
fatal: not a git repository (or any of the parent directories): .git
```
