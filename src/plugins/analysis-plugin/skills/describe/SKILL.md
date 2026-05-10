---
name: describe
description: Researches any concept, technology, entity, or topic using web search and produces a structured description with fixed fields: Overview, Origin, Defining Features, Applications, Caveats, and Further Reading. Confirms the intended subject before generating output. Use when the user wants to describe, explain, research, or get an overview of any concept, technology, or topic.
allowed-tools: [Read, WebSearch, WebFetch]
argument-hint: "<subject>"
---

## Execution Steps
1. If `$ARGUMENTS` is empty, print `Usage: /analysis:describe <subject>` and *STOP*
2. WebSearch `$ARGUMENTS` 2–3 times to establish the most likely intended topic (canonical name, domain, primary field)
3. Present findings and ask: `Describing: "{CANONICAL_NAME}" ({DOMAIN}) — is this correct? [Yes / No / Clarify: ...]` and *STOP*. On the next turn: if "No" or a clarification is given, revise the search target and repeat Step 2 once. If the subject remains unresolvable, print `Subject could not be identified. Please provide a more specific term.` and *STOP*
4. WebSearch the confirmed subject 2–4 more times, targeting: defining features, applications, caveats, origin, and notable facts. If any query returns no results, reformulate and retry once before continuing.
5. WebFetch any result from Step 4 that appears to be a primary source (documentation, reference page, or detailed article) rather than a summary or listicle.
6. Read [Description Template](templates/description-item.md). Synthesize retrieved content into it, populating all fixed fields; include **Origin** only if provenance is clearly established (known author, date, or originating work)
7. Print the structured description. Then *STOP*

## Constraints
- Minimum 4 WebSearch calls total: 2–3 in Step 2, 2–4 in Step 4
- Inline source attribution is required for specific factual claims (e.g. `(Source Name)`)
- **Further Reading** lists recommended next resources, not sources used during research
- No files are created or modified

## Example Output

### No argument supplied:
`Usage: /analysis:describe <subject>`

### Confirmation prompt (Step 3):
`Describing: "Cognitive Load" (Cognitive Psychology) — is this correct? [Yes / No / Clarify: ...]`

### Subject unresolvable after retry:
`Subject could not be identified. Please provide a more specific term.`

### Success:
```
**Topic**: Cognitive Load
**Domain**: Cognitive Psychology
**Overview**: The total amount of mental effort required to process information in working memory at any given moment (Sweller, 1988). Divided into three types — intrinsic, extraneous, and germane — each contributing differently to learning and task performance. Managing cognitive load is central to instructional design, UX, and any domain where information must be communicated clearly.
**Origin**: Introduced by John Sweller in 1988 through research on problem-solving in mathematics; later extended into a comprehensive theory of instructional design.
**Defining Features**:
- Rooted in working memory capacity, which can hold roughly 7 (±2) items simultaneously (Miller, 1956)
- Three-component model: intrinsic (task complexity), extraneous (poor presentation), and germane (schema formation)
- Inversely related to learning efficiency — high extraneous load impairs the formation of long-term schemas
**Applications**:
- Instructional design: sequencing material to avoid overloading novice learners
- UX and interface design: reducing visual clutter and unnecessary steps
- Workplace training: chunking complex procedures into manageable steps
**Caveats**:
- Difficult to measure directly; most studies rely on subjective rating scales (e.g. NASA-TLX)
- The three-type model is debated; some researchers argue germane load is not meaningfully distinct from intrinsic load
- Findings from controlled lab settings do not always transfer cleanly to real-world, multi-task environments
**Further Reading**:
- Sweller, J. (1988). "Cognitive Load During Problem Solving" — *Cognitive Science*, Vol. 12
- Nielsen Norman Group: Minimize Cognitive Load — https://www.nngroup.com/articles/minimize-cognitive-load/
- Paas, F., Renkl, A., & Sweller, J. (2003). "Cognitive Load Theory and Instructional Design" — *Educational Psychologist*
```
