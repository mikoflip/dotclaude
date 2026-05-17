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
8. For each confirmed dimension, write a prose section heading (`### {DIMENSION}`) followed by one paragraph per entry covering that entry's position on that dimension. Ground every specific claim with an inline source attribution (e.g. `(Source Name)`). If information is genuinely unavailable, state what is known and note the gap.
9. After all dimension sections, synthesize the findings into a summary table using this structure:
   ```
   ## {ENTRY_1} vs {ENTRY_2} [vs {ENTRY_N} ...] — Summary

   | Dimension | {ENTRY_1} | {ENTRY_2} | {ENTRY_N} |
   |---|---|---|---|
   | {DIMENSION} | {FINDING} | {FINDING} | {FINDING} |
   | **Summary** | {ONE_LINE_VERDICT} | {ONE_LINE_VERDICT} | {ONE_LINE_VERDICT} |
   ```
   Each cell distills the corresponding prose section to a single concrete claim. If a prose section noted a gap, reflect that in the cell.
10. Print the prose sections, then the summary table. Then *STOP*

## Constraints
- Each dimension must produce one prose paragraph per entry before appearing in the table
- Each table cell must distill its corresponding prose paragraph to a single concrete claim with inline source attribution (e.g. `(Source Name)`)
- **Summary** is always the last table row; each cell is a one-sentence verdict for that entry
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
### Learning curve

**React:** React's learning curve is steeper than most alternatives. Developers must internalize JSX syntax, the unidirectional data-flow model, and hook rules before writing idiomatic components (React docs).

**Vue:** Vue's template syntax stays close to plain HTML and CSS, making the initial ramp-up gentler. The Options API in particular reads naturally for developers coming from traditional web development (Vue docs).

**Svelte:** Svelte eliminates the virtual DOM mental model entirely. Components are compiled at build time, so developers write close-to-vanilla JavaScript with minimal framework-specific concepts to learn (Svelte docs).

### Bundle size

**React:** The React + ReactDOM runtime weighs approximately 42 kB minified and gzipped and is always shipped to the client (React docs).

**Vue:** Vue's runtime is roughly 22 kB minified and gzipped, making it noticeably lighter than React while still being a runtime dependency (Vue docs).

**Svelte:** Svelte compiles components to vanilla JavaScript at build time, so there is no runtime library. A minimal app ships approximately 1.7 kB, though large apps grow as compiled output accumulates (Svelte docs).

## React vs Vue vs Svelte — Summary

| Dimension | React | Vue | Svelte |
|---|---|---|---|
| Learning curve | Steeper; JSX and unidirectional data flow require adjustment (React docs) | Gentler; template syntax is closer to plain HTML (Vue docs) | Minimal; no virtual DOM concepts to learn (Svelte docs) |
| Bundle size | ~42 kB min+gzip runtime always shipped (React docs) | ~22 kB min+gzip runtime always shipped (Vue docs) | ~1.7 kB for minimal app; no runtime library (Svelte docs) |
| **Summary** | Best for large teams needing strict patterns | Best for teams valuing approachability | Best for projects where runtime overhead matters |
```
