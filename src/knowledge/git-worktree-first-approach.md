# Git Worktree-First Approach

## Overview
A consolidated command reference for setting up and maintaining a Git project using a Worktree-first approach, with a bare repository as the root and separate worktrees per branch. Covers two starting scenarios: an existing remote repository, and a brand-new project with no remote yet.

## Scenario 1 — Existing project (git clone)

**Initialize project directory and bare repository**
```bash
mkdir <project_dir>
cd <project_dir>

git clone <repo_url> --bare .git
git config --git-dir=.git remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
```

**Create main worktree and configure upstream tracking**
```bash
git worktree add ./main
cd main
git fetch origin
git branch --set-upstream-to=origin/main main
cd ..
```

## Scenario 2 — New project (git init)

**Initialize project directory and bare repository**
```bash
mkdir <project_dir>
cd <project_dir>
git init --bare .git
```

**Create main worktree and initial commit**
```bash
git worktree add ./main -b main
cd main
# create your files
git add .
git commit -m "Initial commit"
cd ..
```
*-b main is required here since an empty bare repository has no refs to check out yet.*

**Create the GitHub repo and connect it**

Create an empty repository on GitHub (no README/license, to avoid conflicting history), then:
```bash
git remote add origin <repo_url>
git config --git-dir=.git remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git push -u origin main
```

## Common steps

**Create feature and hotfix worktrees from explicit start point**
```bash
git worktree add -b <feature_branch> ./<feature_branch> origin/main
git worktree add -b <hotfix_branch> ./<hotfix_branch> origin/main
```

**Remove a worktree and its associated branch ref**
```bash
git worktree remove <non_main_branch>
git branch -d <non_main_branch>
```
Removes the branch ref itself, if no longer needed.

**Sync main with remote**
```bash
git pull
```
Run from the main directory/branch — resolves via the configured upstream.

## Notes
- The bare clone/init alone does not configure remote-tracking refs; the `remote.origin.fetch` config step is required for later `fetch`/`pull`/`push` operations.
- Explicit `origin/main` start points avoid ambiguity once `main` has diverged from its initial clone state.
- `git worktree remove` deletes the worktree checkout only, not the underlying branch ref.
- In Scenario 2, `-b main` on the first `worktree add` is necessary because no branch ref exists until the first commit is made.
