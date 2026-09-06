# Filesystem Tool Conventions

## Overview
Conventions for interacting with the user's local filesystem (as distinct from Claude's own sandboxed filesystem) via the `list_directory`, `directory_tree`, `read_file`, `read_text_file`, `write_file`, `edit_file`, and `move_file` tools.

## Confirm exact paths before acting
Before acting on a named file or project, confirm its exact location with a directory listing (`list_directory` / `directory_tree`) rather than assuming a path from memory — subfolder and repository names can change without notice.

## Verify before assuming
Read a file's content (`read_file` / `read_text_file`) before editing or summarizing it — never infer its contents or structure from its name alone. When editing, preserve all sections not explicitly being changed.

## Confirm before altering
File moves, renames, or overwrites (`write_file`, `edit_file`, `move_file`) require an inline draft or diff and explicit user confirmation, particularly when the target is ambiguous or the change is hard to reverse.

## Never delete
Files are never permanently deleted. `move_file` relocates or renames only — it is never used to delete. Direct the user to delete a file themselves.

## Match existing conventions
When editing or adding content, follow the language, tone, and format already established in the surrounding file or project unless the user instructs otherwise.

## Handle sensitive content with care
Files may contain sensitive data. Reference such content only as needed for the task at hand, and never transcribe it into external destinations (messages, uploads, third-party services) without explicit instruction.

## Notes
- This file covers the Filesystem MCP tool used by Claude Desktop to reach the user's local machine. Claude Code has native filesystem access and does not need this tool or file.
