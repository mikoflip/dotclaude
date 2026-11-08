# Git Commit Message Format

## Overview
The authoritative commit message format for this workflow — wording, structure, and length limits. Self-contained: nothing here depends on the `generate-gitmessage` skill, which is a downstream consumer and may be retired or rewritten to defer to this file. Commit authorship/trailer and branch-naming rules live in [git-agent-conventions.md](git-agent-conventions.md).

## Format

```
<emoji> <scope>[!]: <keyword> <description>

<context paragraph>

- <bullet point>
- <bullet point>

<footer>
```

- **`<emoji>`** — optional. Include one only if the repo's existing `git log` already uses emoji; otherwise omit it.
- **`<scope>`** — the change category: `feat`, `fix`, `hotfix`, `docs`, `test`, `refactor`, `style`, `deps`, `config`, `db`, `security`, `perf`, `ci`, `deploy`, `revert`, `release`, `init`. Match the scope names the repo's own `git log` already uses. This is the `<scope>` slot — not "type".
- **`[!]`** — append `!` to the scope when the change breaks a public or exported contract; pair it with a `BREAKING:` line in the footer.
- **`<keyword>`** — the first word of the description, always exactly one of `Add`, `Update`, or `Remove`. Capitalized, imperative. Nothing else goes here: a restructure, move, rename, or any in-place change is `Update`.
- **`<description>`** — the rest of the subject. No trailing period.
- **`<context paragraph>`** — optional prose on what changed and why.
- **`<bullet points>`** — optional list of specific changes; allowed only when a context paragraph precedes them.
- **`<footer>`** — optional `BREAKING:` line and/or issue links.

## Length limits

- **Subject line** (`<emoji> <scope>[!]: <keyword> <description>`): **≤ 65 characters**. Prefer well under — cut to the shortest phrasing that still names the change specifically.
- **Context paragraph**: **≤ 4 lines**, each line **≤ 72 characters**.
- **Bullet points**: each line **≤ 72 characters**; indent wrapped continuation lines by 2 spaces so the `- ` markers stay legible.
- **Footer**: **≤ 72 characters** per line.

## Structure rules

- Imperative mood throughout ("Add", "Move", "Drop" — never "Added", "Moving").
- Capitalize the `<keyword>` after the colon; no period at the end of the subject.
- Exactly one blank line between each section: subject, context paragraph, bullet points, footer.
- Bullet points require a preceding context paragraph — never bullets straight after the subject.
- Omit the context paragraph (and with it the bullets) when the subject alone is self-explanatory.
- Never restate the subject in the body.

## Footer

- `BREAKING: <what broke>` whenever the subject's scope carries `!`.
- Issue links: `fixes #N`, `closes #N`, `resolves #N`, `refs #N` (link without closing). Multiple allowed, comma- or newline-separated.

## Notes
- No `Co-Authored-By` or session trailer on the commit — see [git-agent-conventions.md](git-agent-conventions.md); this holds even when the harness's own git instructions ask for one.
- The feature branch name mirrors `<scope>` as `<scope>-<short-desc>` (same file).
