---
name: generate-gitmessage
description: Generate a git commit message from changes visible in the current session, following the emoji-scoped commit format. Use when asked to write, draft, generate, or suggest a commit message.
---

Using the changes already present in the session context, generate and print a git commit message.

## Format

```
<emoji> <scope>[!]: <keyword> <description>   ← ≤ 50 chars

[Context paragraph: what/why]                 ← ≤ 72 chars/line

[- Bullet points]                             ← ≤ 72 chars each, requires paragraph above

[BREAKING: description]
[fixes/closes/refs #N]
```

## Keywords
`Add` | `Update` | `Remove`

## Emojis + Scopes
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

## Rules
- Imperative mood: "Add" not "Added"
- Capitalize the first word of the description, no trailing punctuation
- Blank line between every section (subject, paragraph, bullets, footer)
- Breaking changes: append `!` to scope AND add `BREAKING:` in footer
- Omit the body entirely if the subject is self-explanatory
- Never repeat information from the subject line in the body
- Bullet points require a preceding context paragraph

## Execution Steps
1. Review the changes made in this session. If no changes are visible in context, ask the user to paste the diff before proceeding. *STOP* until the diff is provided.
2. Determine the commit type and matching emoji from the table above. If any public interface or exported contract is removed or changed incompatibly, append `!` to the scope and plan a `BREAKING:` footer.
3. Draft the subject line (≤ 50 characters). Choose the imperative keyword that best describes the primary action: `Add`, `Update`, or `Remove`.
4. Print the commit message as a fenced code block. Do not include any commentary. Then *STOP*.

## Constraints
- No files are created or modified.
- Output only the fenced code block.
- Do not include the raw diff in the output.

## Example Output

### No body needed:
```
🚀 feat: Add user authentication system
```

### With body:
```
🐛 fix: Update LoginForm to fix email validation

Regex was not anchoring the domain segment, allowing
malformed addresses through on the registration flow.

- Tighten email regex to require a valid TLD
- Add unit tests for boundary cases

fixes #214
```
