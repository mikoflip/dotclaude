## Personal Knowledge

`~/.claude/knowledge/` (user-level — present in *every* project, regardless of the current
working directory) holds working notes, references, and how-to instructions for specific
tools/workflows. Read the relevant file when a task matches one of its topics; run
`ls ~/.claude/knowledge/` for the current set. "Check my knowledge" / "check all your
knowledge" always includes this directory — not just knowledge files found inside the
current project.

## Notes

The user keeps notes in two places — check which one a request means:

- **Markdown Notes** — structured notes (development planning notes, job applications)
  as plain Markdown files in a synced vault at `~/Developer/notes`. Read
  `~/.claude/knowledge/markdown-notes-conventions.md` before creating, editing, or
  summarising any of them.
- **Apple Notes** — informal notes in the Notes app, via the `apple-notes` MCP server.
  Read `~/.claude/knowledge/apple-notes-conventions.md` before working with them.
