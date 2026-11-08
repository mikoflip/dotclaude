---
name: generate-gitmessage
description: Generate a git commit message from changes visible in the current session, following the format defined in ~/.claude/knowledge/git-commit-message-format.md, matched to the repo's own git log convention. Use when asked to write, draft, generate, or suggest a commit message.
---

Using the changes already present in the session context, generate and print a git commit message.

**`~/.claude/knowledge/git-commit-message-format.md` is the single source of truth** for structure, wording (`<emoji> <scope>[!]: <keyword> <description>`), length limits, and footer rules. Read it before drafting and follow it exactly. This skill only covers gathering the change, matching the repo's convention, and printing the result.

## Emoji reference

The knowledge file names the `<scope>` values and says to use an emoji only when the repo's `git log` already does. When emoji are used, map scope → emoji:

| Emoji | Scope      | Use for                              |
|-------|------------|--------------------------------------|
| 🚀    | `feat`     | New features                         |
| 🐛    | `fix`      | Bug fixes                            |
| 🔥    | `hotfix`   | Critical production fixes            |
| 📝    | `docs`     | Documentation only                   |
| ✅    | `test`     | Tests only                           |
| ♻️    | `refactor` | Restructure without behavior change  |
| 💄    | `style`    | Visual/UI styling                    |
| 📦    | `deps`     | Dependency updates                   |
| ⚙️    | `config`   | Configuration changes                |
| 🗃️   | `db`       | Database schema/migrations           |
| 🔒    | `security` | Security fixes                       |
| ⚡    | `perf`     | Performance improvements             |
| 🚧    | `ci`       | CI/CD workflows                      |
| 🚀    | `deploy`   | Deployment                           |
| ⏪    | `revert`   | Reverting a previous commit          |
| 🏷️   | `release`  | Release tagging                      |
| 🚀    | `init`     | Initial project scaffolding          |

## Execution Steps
1. Read `~/.claude/knowledge/git-commit-message-format.md` in full. If it is missing, fall back to a `<scope>: <Keyword> <description>` subject (≤ 65 chars) with an optional body, and note that the file was not found.
2. Review the changes made in this session. If no changes are visible in context, ask the user to paste the diff before proceeding. *STOP* until the diff is provided.
3. Check `git log --oneline -20` (or similar) for this repo's established convention — whether it uses emoji, and which `<scope>` names it uses — and match it.
4. Determine `<scope>` and, if the repo uses emoji, the matching emoji from the table above. If any public interface or exported contract is removed or changed incompatibly, append `!` to the scope and plan a `BREAKING:` footer.
5. Choose the `<keyword>` — `Add`, `Update`, or `Remove` — for the primary action. A restructure, move, or rename is `Update`.
6. Draft the message per the knowledge file: subject ≤ 65 chars; optional context paragraph; optional bullet points (only after a context paragraph); optional footer. One blank line between every section.
7. Print the commit message as a single fenced code block. No commentary. Then *STOP*.

## Constraints
- No files are created or modified.
- Output only the fenced code block — no raw diff, no explanation.
- The knowledge file governs any detail not spelled out here; if the two ever conflict, the knowledge file wins.

## Example Output

### No body needed:
```
🚀 feat: Add user authentication system
```

### With body:
```
🐛 fix: Update LoginForm to fix email validation

Email regex did not anchor the domain, letting malformed addresses reach the API.

- Tighten the email regex to require a valid TLD
- Add unit tests for boundary cases

fixes #214
```
