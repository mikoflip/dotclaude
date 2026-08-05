---
name: specify
description: Turn a short feature idea into a numbered, structured spec file under _specs/. Use when the user wants to spec out, scope, or start planning a new feature.
argument-hint: Short feature description
disable-model-invocation: true
allowed-tools: [Read, Write, Glob, Bash]
---

Turn `$ARGUMENTS` into a numbered spec file under `_specs/` of the current project.

## Execution Steps
1. Bash `git status --porcelain`. If output is non-empty, print `Working tree is dirty. Commit or stash changes before running /sdd:specify.` followed by the raw output, then *STOP*. This duplicates `/sdd:preflight`'s check deliberately — `specify` must stay safe to run even if `preflight` was skipped
2. Bash `git branch --show-current`. If output is empty (detached HEAD) or is `main`/`master`, print `Not on a dedicated feature branch (currently: {branch, or "detached HEAD" if empty}). Run /sdd:preflight first.` and *STOP*. Otherwise set `feature_slug` to that branch name verbatim
3. If `$ARGUMENTS` is empty, ask the user for a short description of the feature, then *STOP* until they respond
4. Glob `_specs/*.md`. Check whether any match, after stripping its leading `{N}-` numeric prefix, equals `{feature_slug}.md` exactly (not just ends with it — see `plan`/`implement`'s identical exact-match rule). If one exists, read its frontmatter `status` and ask `Spec _specs/{N}-{feature_slug}.md already exists (status: {status}). Overwrite it? [y/n]` and wait for input. If the response isn't an explicit yes, print `Cancelled.` and *STOP*. If confirmed, reuse that file's `N`. If none exists, derive a new `N`: from filenames matching `{NNN}-*.md`, extract the numeric prefixes, take the highest existing prefix (or `0` if none match) plus 1, zero-padded to 3 digits (e.g. `001`, `042`)
5. Read [Spec Template](templates/spec.md) and [Formatting Guide](references/formatting-guide.md). Draft spec content using the template's structure and the guide's voice/structure rules, replacing every placeholder with feature-specific content derived from `$ARGUMENTS` (the Overview section carries the descriptive summary). Set frontmatter `status: ready`, `slug: {feature_slug}`, `created: {today's date, YYYY-MM-DD}`. Do not add technical implementation details such as code examples — that belongs to `/sdd:plan`
6. Write the drafted spec to `_specs/{N}-{feature_slug}.md`. If exits non-zero, print error verbatim and *STOP*
7. Print:
   ```
   **Spec Created**
   Spec file: `_specs/{N}-{feature_slug}.md`
   Status: ready
   ```
   Then *STOP*

## Constraints
- Modify at most 1 file: the new `_specs/{N}-{feature_slug}.md`
- Spec content follows [Spec Template](templates/spec.md) structure exactly — no added technical/implementation detail
- Spec prose follows [Formatting Guide](references/formatting-guide.md) — no hedged, marketing, or meta-narrated language
- Print the Step 7 block only — no additional commentary, and never repeat the full spec content unless the user explicitly asks to see it

## Example Output

### Working tree is dirty:
```
Working tree is dirty. Commit or stash changes before running /sdd:specify.
 M src/plugins/sdd-plugin/skills/specify/SKILL.md
?? _specs/
```

### Not on a dedicated feature branch:
`Not on a dedicated feature branch (currently: main). Run /sdd:preflight first.`

### Arguments empty:
`What should this feature do? Give me a short description.`

### Spec already exists for this branch, awaiting confirmation:
`Spec _specs/003-feat-card-component-dashboard.md already exists (status: ready). Overwrite it? [y/n]`

### Overwrite declined:
`Cancelled.`

### Write fails (e.g. `_specs/` not writable):
`EACCES: permission denied, open '_specs/003-feat-card-component-dashboard.md'`

### Spec written successfully (slug from current worktree branch `feat-card-component-dashboard`):
```
**Spec Created**
Spec file: `_specs/003-feat-card-component-dashboard.md`
Status: ready
```
