# Git Local-Merge Workflow

## Overview
PRs are opened on GitHub for review and CI, but merged into main locally rather than via GitHub's web "Merge pull request" button. GitHub's web-UI merge authors the commit using the GitHub profile's *display name*, not the local `git config user.name`, which can cause author-identity mismatches when the same account shows different display names in different contexts. Merging locally keeps every commit's author derived from one source of truth.

## Workflow

**Push the feature branch**
```bash
git push -u origin <branch-name>
```

**Open the PR from the CLI**

Uses the commit's subject and body as the PR title/body (GitHub's default for a single-commit branch).
```bash
gh pr create --fill
```
Note the PR number returned (e.g. #7).

**Merge locally into main**
```bash
cd <main-worktree>
git pull
git merge --no-ff <branch-name> \
  -m "Merge pull request #<N> from <github-username>/<branch-name>" \
  -m "$(git log -1 --format='%s' <branch-name>)"
```

**Push the merge**
```bash
git push
```
Closes the PR on GitHub automatically, since the merge commit references it.

**Clean up the feature branch**
```bash
git worktree remove <branch-name>
git branch -d <branch-name>
git push origin --delete <branch-name>
```

## Notes
- If a local merge was already made with a generic message (e.g. Git's default `Merge branch '<name>'`) before opening the PR, and it hasn't been pushed yet, undo it first: `git reset --hard origin/main`, then redo the push-PR-merge steps.
- To bring an in-progress feature branch up to date with main after a merge lands elsewhere: `cd <feature-worktree> && git merge main`
