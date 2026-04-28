---
name: review
description: Review and evaluate Claude skills (SKILL.md files and their surrounding directory structure) against the Agent Skills specification and established best practices. Use this skill when a user asks to review, critique, audit, or improve a skill they are building or have built — including requests like "review my skill", "give feedback on this SKILL.md", "what's wrong with this skill", "critique my skill design", or "help me improve my skill before publishing it".
allowed-tools: [WebFetch, Read, Glob]
---

# Skill Review

This skill guides a structured review of a Claude skill against the Agent Skills specification and design best practices. The goal is actionable feedback the user can act on — not a checklist audit for its own sake.

The user provides a skill to review: either a path to a skill directory, a pasted SKILL.md, or both. If relevant files beyond SKILL.md exist (scripts, references, assets), read them before forming judgments about structure.

---

## Reference Pages

Fetch these pages when you need authoritative detail beyond what is in this skill. They are stable, publicly accessible, and reasonably concise — fetching one adds roughly 3–6k tokens to context.

| Page | When to fetch |
|---|---|
| [Claude Code — Skills](https://code.claude.com/docs/en/skills) | When the skill is intended for Claude Code specifically: slash-command invocation, invocation control (user- vs. agent-invoked), subagent execution, dynamic context injection, skill discovery from nested directories, or any Claude Code extension beyond the base spec |
| [Specification](https://agentskills.io/specification) | Any spec compliance question: frontmatter fields, naming rules, field constraints, directory structure |
| [Best practices](https://agentskills.io/skill-creation/best-practices) | Questions about instruction design, scoping, progressive disclosure, or whether specific content adds value |
| [Optimizing descriptions](https://agentskills.io/skill-creation/optimizing-descriptions) | When the description is weak or the user wants to improve trigger accuracy |
| [Evaluating skills](https://agentskills.io/skill-creation/evaluating-skills) | When the user asks how to test a skill or whether it's production-ready |

Fetch proactively if reviewing an unfamiliar skill domain or if the user asks a question you can't fully answer from this skill alone. The spec page in particular is worth fetching whenever you're flagging a spec violation — it lets you cite exact constraints.

---

## Input Handling

Determine what the user has provided before beginning the review:

If `$ARGUMENTS` is non-empty, treat it as the directory path before checking the cases below.

- **Pasted SKILL.md only** — proceed with the review, but note at the start of the output that file integrity cannot be checked without a directory path.
- **Directory path only** — read `<path>/SKILL.md`. If no SKILL.md exists at that location, report `No SKILL.md found at <path>` and stop.
- **Both path and pasted content** — use the directory for file integrity checks; use the pasted content (or the file at the path, if consistent) as the review target.
- **Neither** — ask the user to provide either a pasted SKILL.md or a path to a skill directory before proceeding.

---

## Review Process

Work through the five dimensions below in order. For each one, note what works, what needs improvement, and — for anything significant — a concrete suggestion. End with a prioritised summary.

Keep the tone direct and constructive. Explain *why* something matters when it isn't obvious. Skip dimensions that aren't applicable rather than padding with "looks fine".

---

## Dimension 1 — Specification Compliance

Check the formal requirements from the Agent Skills spec. These are mostly mechanical and objective.

**Frontmatter fields:**

- `name`: present, lowercase-alphanumeric-and-hyphens only, no leading/trailing/consecutive hyphens, 1–64 characters, matches the directory name
- `description`: present, non-empty, 1–1024 characters
- `license`: not required, but flag if the skill looks redistributable and it's absent
- `compatibility`: not required; if present, must be 1–500 characters
- `metadata`: not required; if present, must be a string→string map
- `allowed-tools`: cross-check every tool listed appears in at least one execution step; flag tools listed but unused, and tools used in steps but absent from `allowed-tools`
- `disable-model-invocation`: not required, but recommended when the skill has deterministic execution steps; flag its absence as a warning on such skills

**Structure:**
- `SKILL.md` is the only required file
- Optional directories are `scripts/`, `references/`, `assets/`
- File references in the body use relative paths from the skill root

Flag any spec violations as **blockers** — they prevent the skill from loading correctly or passing validation.

---

## Dimension 2 — Description Quality

The description is the primary triggering mechanism. An agent reads only the name and description to decide whether to activate a skill. Weak descriptions cause under-triggering (skill ignored when it should help) or over-triggering (skill activated for unrelated tasks).

Evaluate:

- **Completeness**: Does it describe *what the skill does* and *when to use it*? Both halves matter.
- **Specificity**: Does it name the task domain concretely? Vague descriptions ("helps with documents") are less reliable than specific ones ("extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs").
- **Trigger coverage**: Does it include the keywords and phrasings a user would actually type? Consider whether edge cases and alternate wordings are covered.
- **Scope accuracy**: Does the description match what the skill body actually does? Over-promising or under-describing both cause problems.
- **Length vs. signal**: Within the 1024-character limit, descriptions should be informative but not padded. Every sentence should add triggering signal.

A useful test: would an agent reading only this description reliably activate the skill for its intended tasks, and reliably not activate it for unrelated ones?

---

## Dimension 3 — Structure and Organisation

Evaluate how well the skill is laid out, both within SKILL.md and across the directory.

**Progressive disclosure:**
- Metadata (name + description): always in context, ~100 tokens
- SKILL.md body: loaded on activation; keep under 500 lines / ~5000 tokens
- External files (scripts, references, assets): loaded on demand

Flag if the SKILL.md body is overloaded with content that belongs in reference files, or if reference files are referenced without clear conditions for when to load them ("see references/ for details" is weak; "read `references/api-errors.md` if the API returns a non-200 status" is strong).

**Internal organisation:**
- Is the reading order logical? Core workflow before edge cases, common path before variants.
- Are sections clearly headed and scannable?
- Are scripts invoked at the right points, with their purpose stated?
- For domain-variant skills (e.g., aws/gcp/azure), is each variant isolated so Claude loads only the relevant file?

**File integrity** (only when a directory path is available):
- Collect every `[text](path)` link and bare file path in SKILL.md. Read and verify each exists relative to the skill root; flag any missing.
- Glob `<path>/**/*` to list all files present; flag any not referenced anywhere in SKILL.md.

**Structural sections** (only when path or pasted content is available):
- Constraints: present as a named section; items are concrete and behavioral; print/output behavior is covered
- Example Output: at least one complete example present; each conditional *STOP* path has a corresponding example

---

## Dimension 4 — Instruction Quality

This is the hardest dimension to evaluate well. Good instructions are specific enough to correct the agent's natural tendencies without being so prescriptive that they break on inputs the author didn't anticipate.

**Value-add test:** For each section, ask: would Claude get this wrong without this instruction? If the answer is no, the content is padding and should be cut. Strong skills contain mostly things the agent wouldn't know from general training: project-specific conventions, non-obvious API behaviour, environment constraints, and calibrated gotchas.

**Specificity calibration:**
- Fragile or consistency-critical operations → prescriptive (exact command, exact sequence, explicit "do not deviate")
- Flexible operations where multiple approaches are valid → give a default with a brief escape hatch, not a menu of options
- Agent already handles this well → omit it

**Instruction form:**
- Imperative voice: "Run `scripts/extract.py`" not "The script should be run"
- Procedures over declarations: teach the approach, not the answer to one specific instance
- Explain *why* for non-obvious constraints — agents that understand the reason make better context-dependent decisions

**Step hygiene:**
- Steps are numbered sequentially
- Each step uses an imperative verb
- Steps that can fail (file reads, shell commands, argument parsing) have an explicit error message and *STOP*
- Vague verbs ("review", "analyze", "assess") are always qualified with specific criteria or a reference file

**Patterns to look for (positive):**
- Gotchas section: concrete corrections to mistakes the agent will make (e.g., "this table uses soft deletes; always add `WHERE deleted_at IS NULL`")
- Output format template: a literal template is more reliable than a prose description of the format
- Checklist for multi-step workflows: helps the agent track progress and avoid skipping steps
- Validation loop: instruct the agent to validate output before proceeding

**Patterns to look for (negative):**
- Restating general knowledge the agent already has
- Options menus without a clear default
- Instructions so narrow they only apply to one specific input
- Vague directives: "handle errors appropriately", "follow best practices"

---

## Dimension 5 — Scope and Coherence

A skill should encapsulate a coherent unit of work.

- **Too narrow**: forces multiple skills to load for a single logical task; creates overhead and potential instruction conflicts
- **Too broad**: hard to activate precisely; the SKILL.md body becomes a general-purpose manual
- **Mixed concerns**: a skill that covers both "query the database" and "administer the database" is probably two skills

Check also:
- Does the skill solve a real recurring problem, or is it solving a one-off task that doesn't warrant a skill?
- Is the skill grounded in specific domain knowledge, or is it generic enough that Claude would handle it equally well without it?

---

## Review Output Format

Structure your review like this:

```
## Skill Review: [skill name]

**Verdict**: [PASS | NEEDS WORK | FAIL] — N failure(s), N warning(s)

### Specification Compliance
[List any blockers. If clean, say so briefly.]

---

### Description
[Strengths and weaknesses. Suggest revised wording if needed.]

---

### Structure and Organisation
[What's well-organised. What should move to a reference file, or be reorganised.]

---

### Instruction Quality
[What adds genuine value. What should be cut or rewritten. Highlight any strong patterns used (gotchas, templates, checklists) and any antipatterns.]

---

### Scope and Coherence
[Is the scope right? Any splitting or merging to consider?]

---

### Priority Actions
1. [Most important change — usually a spec violation or a description problem]
2. [Second most important]
3. [...]

[End with one sentence on the overall state of the skill.]
```

Adapt the format when appropriate — if a skill only needs minor polish, say that clearly rather than padding all five sections. If a skill is fundamentally misconceived, lead with that.

---

## Example Output

```
## Skill Review: export-report

**Verdict**: NEEDS WORK — 2 failures, 1 warning

### Specification Compliance

⚠ BLOCKER: `name` field is "export_report" — underscores are not permitted; must be "export-report" to match the directory name and pass validation.

---

### Description

Weak. "Helps export reports from the system" describes the outcome but gives no triggering signal. A user typing "generate a monthly sales export" or "download the Q3 PDF" would not reliably activate this skill. Suggest:

> "Exports reports from the internal reporting system as CSV or PDF. Use when asked to export, download, or generate a report, including scheduled exports and one-off data pulls."

---

### Structure and Organisation

The SKILL.md body contains a full copy of the API response schema (~120 lines). This belongs in `references/api-schema.md`, loaded conditionally ("read `references/api-schema.md` if the export format is not CSV or PDF"). As written, it loads unconditionally and inflates the body well past the 500-line target.

File integrity (path provided):
✓ references/field-mapping.md — exists
✗ references/error-codes.md — referenced in Step 4 but not found on disk
⚠ scripts/poll-status.py — present in directory but not referenced anywhere in SKILL.md

---

### Instruction Quality

Step 2 uses "review the available fields" with no criteria — vague verb, no reference. Either specify what to look for or point to `references/field-mapping.md` explicitly.

The retry logic in Step 5 is well-specified: exact backoff intervals, maximum attempts, and a literal error message to emit on timeout. Good.

No gotchas section. The polling endpoint returns 202 during processing and 200 on completion — this is non-obvious and the agent will likely misread it as a failure. Add a gotcha.

---

### Scope and Coherence

Scope is appropriate for a single skill. The export and the polling step are part of the same logical operation.

---

### Priority Actions

1. Fix `name` field: "export_report" → "export-report" (spec violation, blocks loading)
2. Rewrite description to include task-domain keywords and a "Use when…" clause
3. Move API schema to `references/api-schema.md` and load it conditionally
4. Fix missing `references/error-codes.md` or remove the reference
5. Add gotcha for 202 vs 200 status on the polling endpoint

The skill has solid execution logic but is blocked by a naming violation and undermined by a description that won't trigger reliably.
```

### No SKILL.md found:
`No SKILL.md found at skills/missing-skill`
