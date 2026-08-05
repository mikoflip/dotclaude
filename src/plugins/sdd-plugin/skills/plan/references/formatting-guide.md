# Formatting Guide

Voice and structure rules for generated spec/plan prose. Governs *how*
free-text sections read — the section skeleton itself comes from
`templates/spec.md` (or the plan equivalent), not from here.

## Voice

- Declarative, not hedged. State what's true or what to do — not what
  might, could, or should ideally happen
  - Bad: "The system should ideally try to validate user input in order to ensure data integrity where possible"
  - Good: "Reject submissions with an empty title field"
- Sentence fragments over full sentences when a fragment carries the same
  information
  - Bad: "This is a dotfiles-style configuration manager that is designed for Claude Code"
  - Good: "Dotfiles-style configuration manager for Claude Code"
- No marketing adjectives: seamless, powerful, robust, cutting-edge,
  intuitive, elegant. Describe the mechanism, not the feeling
  - Bad: "Adds a seamless and intuitive way to interact with the dashboard, enhancing the overall user experience"
  - Good: "Adds a summary card to the dashboard showing task counts by status. Currently users must open each list to see counts"
- No meta-narration: don't announce what a section is about to do
  ("This section describes...", "Let's walk through..."). Start with the
  content
- No hedging filler: "in order to", "this allows us to", "it's worth
  noting that", "generally speaking". Cut the lead-in, keep the claim
- No exclamation points, no emoji
- State the *why* only when it's non-obvious — a constraint, a prior
  incident, a tradeoff. Skip it when the *what* is self-explanatory

## Structure

- Two heading levels only: `#` for the document title, `##` for
  top-level sections. No `###` nesting — split into more `##` sections
  instead
- Bullets for anything enumerable (goals, requirements, open questions).
  Prose (1-3 sentences) only for narrative sections (Overview, Problem)
  where a list would fragment a single thought
- Tables only when comparing 3+ dimensions across 3+ items. Default to
  bullets or a checklist otherwise
- Backtick every identifier: file paths, field names, status values, flag
  names, command names (`` `_specs/003-slug.md` ``, `` `status: ready` ``)
- Use `→` for sequences and state transitions instead of spelling them out
  in prose
  - Bad: "The status of the spec will transition from ready to planned once the plan stage has successfully read it"
  - Good: "`status`: `ready` → `planned`, flipped by `plan` on successful read"
- Em dash for a short aside or consequence clause, not a new sentence
  - Good: "Symlinks each child individually — lets Claude Code write runtime files without polluting the repo"
