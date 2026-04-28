---
name: suggest
description: Analyze the current project and generate 5 improvement suggestions, selected by impact-to-effort ratio and ordered from lowest to highest effort. Use when the user wants actionable improvement ideas for their project, or asks for next steps, things to improve, what to work on next, or what to prioritize. Requires a TODO.md file in the project root.
disable-model-invocation: true
allowed-tools: [Read, Glob, Bash]
---

## Execution Steps
1. Bash `[ -f ./TODO.md ] || { echo "./TODO.md: No such file"; exit 1; }`. If exits non-zero, print error verbatim and *STOP*
2. Read `./TODO.md` to identify existing improvement areas; skip any proposed suggestion that targets the same primary file(s) and the same category of change as an existing item (e.g. do not suggest adding tests to a file already targeted by a test-coverage item)
3. Glob `**/*` excluding common build and dependency directories (e.g. `node_modules`, `dist`, `build`, `vendor`, `.git`, `.next`, `__pycache__`, `coverage`) to map project structure
4. From the glob results, identify entry points, config files, and primary source files. Read no more than 15 files total. Reason about which gaps in content quality, structure, consistency, completeness, and standards have the highest impact-to-effort ratio to determine which 5 suggestions to generate
5. Read [TODO Item Specification](references/todo-specification.md) and [TODO Item Effort Estimation Guidelines](references/todo-effort-estimation.md)
6. Generate 5 improvement suggestions and estimate their effort using the tiers defined in `references/todo-effort-estimation.md`
7. Order suggestions 1–5 by estimated effort (low to high), then format each using [TODO Item Template](templates/todo-item.md)
8. Print suggestions. Then *STOP*

## Constraints
- In output, include only exact existing relative paths for file references; never use wildcards (`*`)
- No files are created or modified

## Example Output

### TODO.md not found:
`./TODO.md: No such file`

### Success (showing first item only):
```
1. **Add Missing Alt Text to Hero Images**

**Description**: Add descriptive alt attributes to the three hero images in the landing page that currently have empty alt values.
**Motivation**: Improve accessibility compliance and screen reader support for visually impaired users.
**Estimated Effort**: Trivial (< 0.5h)
**Impacted Files**:
- src/pages/index.html

2–5. ...
```
