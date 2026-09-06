# Apple Notes Conventions

## Overview
Conventions for reading, creating, and editing notes in the user's Apple Notes app (synced via iCloud). Two distinct tool sets now reach Apple Notes:

- **Claude Desktop** — the built-in `list_notes`, `get_note_content`, `add_note`, `update_note_content` tools (underscore-named).
- **Claude Code** — the `apple-notes` MCP server (`apple-notes-mcp` npm package), exposing a larger, hyphen-named tool set (`list-notes`, `get-note-content`, `create-note`, `update-note`, `search-notes`, `move-note`, and others).

Both talk to the same Notes.app via AppleScript, so the underlying data and its quirks are shared. Naming convention alone (underscore vs. hyphen) tells you which environment you're in. Formatting itself is governed by a separate **Apple Notes Style Guide** note maintained in the app — consult it via the relevant `get_note_content` / `get-note-content` tool rather than duplicating its rules here; this file covers tool behavior and workflow only.

## Shared principles (apply in both environments)

### Verify before acting
List notes or read full note content before editing, summarizing, or referencing them — never infer a note's contents or structure from its title alone. When editing an existing note, preserve all sections not explicitly being changed.

### Confirm before creating or editing
Any note creation or edit requires an inline draft or diff and explicit user confirmation beforehand, particularly when the target note is ambiguous or the change is hard to reverse.

### Never delete
Notes are never deleted by Claude in either environment, regardless of confirmation. This holds even though the Claude Code tool set technically exposes `delete-note`, `batch-delete-notes`, and `delete-folder` (the underlying app-level operations move items to Recently Deleted rather than purging them immediately). Treat those three tools as off-limits by policy, not by capability — direct the user to delete the note or folder themselves in the Notes app.

### Match existing conventions
Follow the language, tone, and formatting already established in a note (e.g. Dutch vs. English) unless the user instructs otherwise.

### Handle sensitive content with care
Notes may hold sensitive data. Reference such content only as needed for the task at hand, and never transcribe it into external destinations (messages, uploads, third-party services) without explicit instruction.

### Verify writes, don't trust success messages
In both environments, a tool's success response is not reliable evidence that markup rendered correctly. Always re-read the note afterward (`get_note_content` / `get-note-content`) before treating a write as done.

### Checklists cannot be created programmatically
Apple Notes stores checklist state as a paragraph style AppleScript does not expose, and writing it directly to the underlying database is unsafe. In **both** environments, checkbox markup — native `class="checklist"` / `<input type="checkbox">` in Claude Desktop, or the same in Claude Code's `format: "html"` content — is silently stripped or collapsed on save, leaving a plain bullet with no error. Use Markdown-style plain text instead in both: `- [ ] item` / `- [x] item` as its own line, no `<ul>` wrapper, since the leading `-` already serves as the marker. If a checklist already exists (created manually in-app), Claude Code's `get-checklist-state` and `get-note-markdown` can read its done/undone state, but this requires Full Disk Access (see below) and neither environment can create one.

---

## Environment: Claude Desktop (`list_notes` / `get_note_content` / `add_note` / `update_note_content`)

### Title handling differs between creation and edit
`add_note`'s `name` parameter already renders as the note's title — never repeat it as a heading inside `content`. `update_note_content` has no `name` parameter; it derives the title from `content`'s first line, so that call must always open with a single styled title line matching the Style Guide's heading format.

### `add_note` ampersand and title-styling quirks
`add_note`'s `name` parameter is not HTML-decoded — pass a literal `&` directly, never `&amp;`, or the entity text appears verbatim in the title. Separately, because `content` must omit the title line (to avoid the duplicate-title bug above), a note created via `add_note` ends up with a plain, unstyled title rather than the Style Guide's bold heading. Every `add_note` call therefore needs an immediate `update_note_content` follow-up that supplies a single styled title line to fix this.

### In-bullet line breaks fail silently
In-bullet breaks (`<br>` inside `<li>`, nested `<div>` inside `<li>`, literal newlines inside `<li>`) are stripped or collapsed on save without error, independent of the checklist issue above.

### No folder or delete tools
This tool set has no create-folder, move, search, or delete capability. If a note needs to go in a specific folder, ask the user to create it in the Notes app first — a bare folder name resolves correctly even when nested.

---

## Environment: Claude Code (`apple-notes` MCP server, package `apple-notes-mcp`)

### Tool surface
Notably larger than Claude Desktop's four tools. Frequently relevant ones:

| Purpose | Tool |
|---|---|
| List notes | `list-notes` |
| Search by title/content | `search-notes` |
| Read note (HTML / plaintext / Markdown) | `get-note-content` / `get-note-plaintext` / `get-note-markdown` |
| Create note | `create-note` |
| Replace note body | `update-note` |
| Append/prepend without replacing | `append-to-note` |
| Move note to folder | `move-note` |
| List / create folders | `list-folders` / `create-folder` |
| Attachments | `list-attachments`, `save-attachment`, `fetch-attachment` |
| Diagnostics | `doctor`, `health-check` |

(`delete-note`, `batch-delete-notes`, `delete-folder` also exist but are excluded by the Never Delete principle above.)

### Title handling is automatic on create — no follow-up needed
`create-note` auto-prepends `title` as a styled `<h1>` in both `plaintext` and `html` formats. Do **not** include the title inside `content` (it would then appear twice), and — unlike Claude Desktop's `add_note` — do **not** issue a follow-up styling call; `create-note` already produces a correctly styled heading in one call.

### `update-note` replaces the entire body; use `append-to-note` for additive edits
`update-note`'s `newContent` **replaces** the note body rather than appending to it. To preserve existing content, read it first with `get-note-content` and include it in `newContent` — or, for purely additive changes, prefer `append-to-note`, which reads and writes as HTML and preserves existing rich formatting automatically.

### Attachments can be silently dropped on full-body rewrites
Before calling `update-note` or `append-to-note` on a note that may contain embedded files, images, scans, PDFs, or audio, run `list-attachments` first. If attachments are present, either preserve them via `save-attachment` / `fetch-attachment` before rewriting, or avoid a full-body replace altogether (e.g. use `append-to-note`, or build a new note instead).

### Backslash escaping in JSON parameters
Content containing literal backslashes (shell-escaped paths, Windows paths, regex patterns) must be double-escaped as `\\` when passed as a tool parameter, since the MCP transport is JSON. A failure to escape can cause notes to be created or updated with mangled or missing backslashes, sometimes without an explicit error.

### Prefer note `id` over `title` for follow-up calls
Most read/update/move/delete-adjacent tools accept either `id` or `title`, but `id` (the CoreData identifier returned by `create-note` / `search-notes` / `list-notes`) is unique, while titles can collide. Capture and reuse the `id` for any multi-step operation on the same note within a task.

### Folder creation is available directly
Unlike Claude Desktop, `create-folder` exists here — Claude Code can create a missing destination folder itself rather than asking the user to do it in-app first. Confirm with the user before creating a folder if its necessity or name is ambiguous, per the shared "confirm before creating" principle.

### Permissions
- **Automation permission**: the first tool call triggers a one-time macOS prompt asking to allow the host process (Terminal, iTerm, or VS Code — whichever launched Claude Code) to control Notes.app. This must be approved manually; it cannot be scripted.
- **Full Disk Access** (optional): required only for `get-checklist-state`, checklist annotations inside `get-note-markdown`, and parts of `get-note-metadata` / `get-note-link`. All core create/read/update/move tools work without it. Run `doctor` to check current status.

---

## Starting planning notes for a new project
Copy the six-section body from the **Planning Note Template** note into each new note, replacing placeholders with unit-specific content. Name each note `{NNN} - {Title}` — zero-padded 3 digits, one sequence shared across the whole project folder rather than reset per effort or note type; `{Title}` is a bare unit name without a repeated project name, since the folder already scopes that. Apply markup per the Style Guide note (checklists, tree structures, code, headings) together with the tool-quirk rules above.

- **In Claude Desktop**: confirm the relevant project subfolder exists first (ask the user to create it in-app if missing) before creating planning notes there.
- **In Claude Code**: the subfolder can be created directly with `create-folder` if missing, subject to user confirmation.

## Notes
- The Style Guide and Planning Note Template are themselves Apple Notes, not files — read them with the relevant read tool when needed rather than assuming their content from memory.
- Tool success messages are not reliable evidence that markup rendered correctly in either environment; always re-read after a write.
- If the two tool sets ever diverge further (e.g. the chat-interface connector gains folder or delete tools), revisit the Never Delete and folder-creation notes above rather than assuming this document stays accurate indefinitely.
