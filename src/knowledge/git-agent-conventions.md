# Git Agent Conventions

## Overview
Conventions for using a coding agent (Claude Code, Codex, Gemini CLI, etc.) as a git collaborator in this workflow — as distinct from [git-local-merge-workflow.md](git-local-merge-workflow.md) (the merge mechanics) and [git-worktree-first-approach.md](git-worktree-first-approach.md) (the worktree-per-branch layout). `<agent-name>` below stands in for whichever agent is doing the work (e.g. `Claude`, `Codex`, `Gemini`).

## Omit the agent co-author trailer
Do not add a `Co-Authored-By: <agent-name> ...` trailer to commit messages. Commits are authored under the user's own identity only.

## Place worktrees beside main
When an agent creates a worktree for a task, place it as a sibling directory of `main` (e.g. `../<branch-name>`), not nested under an agent-specific state directory (e.g. `.claude/worktrees/`, `.codex/worktrees/`). Keeps agent-created worktrees in the same location as manually-created ones.

## Name branches by commit type
Branch names follow `<type>-<short-desc>`, matching the commit's conventional-commit `type:` prefix (`docs-`, `feat-`, `fix-`, `refactor-`, …) — e.g. `fix-marketplace-path-leak` for a `fix:` commit. The commit type/scope itself should follow this repo's actual `git log` convention rather than any fixed default — the `generate-gitmessage` skill derives it that way.

## Confirm before creating a worktree
Whenever an agent is instructed to create a worktree for a task, confirm the worktree/branch name and a provisional commit subject line with the user *before* creating it, not after — refine the message once the diff is final. Deciding both up front keeps the branch's scope clear from the start and speeds up wrap-up (commit, push, PR) once the change is done.

## Keep one logical change per worktree
If a change doesn't already have a worktree open for it, create one (per "Confirm before creating a worktree") rather than editing directly in `main` or piggybacking on an unrelated open worktree. Keeps each branch's diff — and its eventual commit/PR — scoped to one concern.

## Confirm before rewriting pushed history
Amending, resetting, or otherwise rewriting commits already pushed to `main` — and the force-push that follows — always needs explicit user confirmation at the time, even if a related change was approved earlier in the same conversation.
