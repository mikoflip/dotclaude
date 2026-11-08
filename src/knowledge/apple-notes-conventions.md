# Apple Notes Conventions

## Overview
Conventions for reading, creating, and editing notes in the user's Apple Notes app (synced via iCloud). They govern **both Claude Code and Claude Desktop**.

Both hosts use the same tool set: the `apple-notes` MCP server (`apple-notes-mcp` npm package), a stdio server. Each host runs its own instance, and both drive the same Notes.app via AppleScript, so behavior, data, and quirks are identical regardless of host.

Frequently relevant tools:

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

Formatting is governed by a separate **Apple Notes Style Guide** note kept in the app — read it with `get-note-content` when needed rather than duplicating its rules here. The Style Guide and the **Planning Note Template** are themselves Apple Notes, not files; never assume their contents from memory.

## Governing principles

### Verify before acting
List notes or read full note content before editing, summarizing, or referencing them — never infer a note's contents or structure from its title alone. When editing, preserve every section not explicitly being changed.

### Confirm before creating or editing
Any note creation or edit requires an inline draft or diff and explicit user confirmation beforehand, especially when the target note is ambiguous or the change is hard to reverse. The same applies to creating a folder whose necessity or name is ambiguous.

### Deletion (soft-delete only)
Claude may move a note or folder to Recently Deleted via delete-note / delete-folder when either: (a) the item was created by Claude earlier in the same task and is being cleaned up as a superseded duplicate, or (b) the user gives explicit, per-item confirmation. Claude states which item(s) it's about to move before calling the tool. batch-delete-notes requires the user to have reviewed and confirmed the full list first. Claude never empties Recently Deleted or otherwise purges data permanently; "delete" here always means recoverable.

### Match existing conventions
Follow the language, tone, and formatting already established in a note (e.g. Dutch vs. English) unless the user instructs otherwise.

### Handle sensitive content with care
Notes may hold sensitive data. Reference it only as far as the task needs, and never transcribe it into external destinations (messages, uploads, third-party services) without explicit instruction.

### Verify writes
A tool's success response is not evidence that markup rendered correctly. Always re-read the note with `get-note-content` after a write before treating it as done.

### Checklists cannot be created programmatically
Apple Notes stores checklist state as a paragraph style AppleScript does not expose. Checkbox markup (`class="checklist"` / `<input type="checkbox">` in `format: "html"` content) is silently stripped or collapsed on save, leaving a plain bullet with no error. Use Markdown-style plain text instead: `- [ ] item` / `- [x] item` on its own line, no `<ul>` wrapper, since the leading `-` already serves as the marker. For a checklist created manually in-app, `get-checklist-state` and `get-note-markdown` can read its done/undone state (needs Full Disk Access — see Permissions), but no tool can create one.

## Tool behavior

### Title handling is automatic on create
`create-note` auto-prepends `title` as a styled `<h1>` in both `plaintext` and `html` formats. Do **not** repeat the title inside `content` (it would then appear twice), and do **not** issue a follow-up styling call — one `create-note` call produces the correctly styled heading.

### `update-note` replaces the entire body
`update-note`'s `newContent` replaces the note body rather than appending. To preserve existing content, read it first with `get-note-content` and include it in `newContent` — or, for purely additive changes, use `append-to-note`, which reads and writes HTML and preserves existing rich formatting automatically.

### Attachments can be silently dropped on full-body rewrites
Before calling `update-note` or `append-to-note` on a note that may hold embedded files, images, scans, PDFs, or audio, run `list-attachments`. If any are present, either preserve them via `save-attachment` / `fetch-attachment` first, or avoid the full-body replace altogether (use `append-to-note`, or build a new note).

### Backslash escaping in JSON parameters
Literal backslashes (shell-escaped paths, Windows paths, regex patterns) must be double-escaped as `\\` when passed as a tool parameter, since the MCP transport is JSON. Unescaped backslashes can be mangled or dropped, sometimes with no explicit error.

### Prefer note `id` over `title` for follow-up calls
Titles can collide; `id` (the CoreData identifier returned by `create-note` / `search-notes` / `list-notes`) is unique. Capture and reuse it for any multi-step operation on the same note within a task.

### Permissions
- **Automation**: the first tool call triggers a one-time macOS prompt to let the host process control Notes.app — the terminal app (Terminal, iTerm, VS Code) for Claude Code, or Claude.app for Claude Desktop. Each host is prompted separately; approval is manual and cannot be scripted.
- **Full Disk Access** (optional): needed only for `get-checklist-state`, checklist annotations inside `get-note-markdown`, and parts of `get-note-metadata` / `get-note-link`. Grant it to the same host process. Core create/read/update/move tools work without it. Run `doctor` to check status.

## Starting planning notes for a new project
Copy the six-section body from the **Planning Note Template** note into each new note, replacing placeholders with unit-specific content. Name each note `{NNN} - {Title}` — zero-padded 3 digits, one sequence shared across the whole project folder rather than reset per effort or note type; `{Title}` is a bare unit name without a repeated project name, since the folder already scopes that. Apply markup per the Style Guide together with the tool-behavior rules above. Create the project subfolder with `create-folder` if missing, subject to user confirmation.

## Known issues

### `apple-notes` (sweetrb): hash requirement blocks some writes
**Encountered in Claude Desktop only.**

`update-note`, `delete-note`, `append-to-note`, and `batch-delete-notes` require
an `expectedContentHash` from a prior `get-note-content` read. No read tool has
been observed to return this value, so these four calls cannot be completed —
don't retry with a fabricated hash; it fails safely by design but isn't
recoverable. All other `apple-notes` tools (reads, `create-note`, `move-note`,
`delete-folder`, etc.) are unaffected. Claude Code connects to a separate
instance of this same server and has not hit this issue.

### Claude Desktop: fallback for blocked writes
A second server, **`Read and Write Apple Notes`**, may be configured. It has
only `list_notes`, `get_note_content`, `update_note_content`, `add_note` —
addressed by name + optional folder, no hash required.

**Rule:** default to `apple-notes` for everything; fall back to
`Read and Write Apple Notes` only for:
- `update-note` → `update_note_content`
- `append-to-note` → read with `get_note_content`, concatenate, write with
  `update_note_content`

No fallback exists for deletion — `delete-note`/`batch-delete-notes` failures
still require manual deletion in Notes.app. Before writing via
`Read and Write Apple Notes`, confirm the note name is unique within its
folder (via its own `list_notes`) — it doesn't disambiguate duplicate titles
by id the way sweetrb's tools do.
