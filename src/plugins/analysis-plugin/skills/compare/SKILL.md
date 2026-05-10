---
name: compare
description: Researches two or more entries and produces a structured side-by-side comparison across user-selected dimensions. Proposes relevant dimensions for your approval and lets you refine them before generating output. Performs live web research to ground each cell in authoritative sources. Use when comparing, contrasting, exploring differences between, or understanding the difference between two or more concepts, technologies, tools, or entities.
allowed-tools: [Read, WebSearch, WebFetch]
argument-hint: "<entry> vs <entry> [vs <entry> ...]"
---

## Execution Steps
1. If `$ARGUMENTS` is empty or does not contain at least one ` vs ` (case-insensitive), print `Usage: /analysis:compare <entry> vs <entry> [vs <entry> ...]` and *STOP*
2. Split `$ARGUMENTS` on every ` vs ` (case-insensitive) to produce the ENTRIES list.
3. WebSearch each entry 1–2 times to establish its canonical name and domain. If any entry yields no usable results, print `Could not identify "{ENTRY}". Please provide a more specific term.` and *STOP*
4. Based on the entries' shared domain, propose 5–7 relevant comparison dimensions. Present as:
   ```
   Comparing: "{ENTRY_1}" vs "{ENTRY_2}" [vs ...]

   Suggested dimensions:
   1. [Dimension]
   2. [Dimension]
   ...

   Reply "keep" to proceed, or describe changes (e.g. "remove 3, add licensing").
   ```
   and *STOP*
5. On the next turn, read the user's reply. If they said "keep", use the dimensions from Step 4 as-is. If they requested changes, apply them and print "Updated dimensions: 1. … 2. … [etc.]" — then continue to Step 6.
6. WebSearch each entry 2–3 times per confirmed dimension, prioritising primary sources — official documentation, academic papers, and authoritative reference works — over opinion pieces or summaries. If a query returns no results, reformulate and retry once.
7. WebFetch any result from Step 6 that appears to be a primary source (official documentation, academic paper, reference work, or authoritative article) rather than a summary.
8. Read [Comparison Template](templates/comparison.md). Synthesize retrieved content into one table row per dimension — one column per entry. If information for a cell is genuinely unavailable, state what is known and note the gap; do not leave cells vague or blank.
9. Print the structured comparison. Then *STOP*

## Constraints
- Each dimension cell must contain a concrete claim with inline source attribution for specific facts (e.g. `(Source Name)`)
- **Summary** is always the last row; each cell is a one-sentence verdict for that entry
- No files are created or modified

## Example Output

### No argument or missing "vs":
`Usage: /analysis:compare <entry> vs <entry> [vs <entry> ...]`

### Unresolvable entry:
`Could not identify "frobnicator". Please provide a more specific term.`

### Dimension proposal (Step 4):
```
Comparing: "React" vs "Vue" vs "Svelte"

Suggested dimensions:
1. Learning curve
2. Performance
3. Bundle size
4. Ecosystem & community
5. Reactivity model
6. Corporate backing

Reply "keep" to proceed, or describe changes (e.g. "remove 6, add licensing").
```

### Success:
```
## React vs Vue vs Svelte

| Dimension | React | Vue | Svelte |
|---|---|---|---|
| Learning curve | Steeper; JSX and unidirectional data flow require adjustment (Meta docs) | Gentler; template syntax is closer to plain HTML (Vue docs) | Minimal; no virtual DOM concepts to learn (Svelte docs) |
| Bundle size | ~42 kB min+gzip (React docs) | ~22 kB min+gzip (Vue docs) | ~1.7 kB (Svelte docs) |
| **Summary** | Best for large teams needing strict patterns | Best for teams valuing approachability | Best for projects where runtime overhead matters |
```
