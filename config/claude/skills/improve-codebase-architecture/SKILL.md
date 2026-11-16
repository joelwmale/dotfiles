---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. User-invoked, not automatic.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that
turn shallow modules into deep ones. The aim is testability and navigability, for people
and for agents.

Load the `codebase-design` skill first. Use its vocabulary exactly in every suggestion -
**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality** -
and its principles: the deletion test, "the interface is the test surface", "one adapter
is a hypothetical seam, two is a real one". Do not drift into "component", "service",
"API" or "boundary".

If the project has a domain glossary (`GLOSSARY.md` or `docs/GLOSSARY.md`) or ADRs (`docs/adr/`), read them for
the area first. The glossary names good seams, and ADRs record decisions not to re-litigate.

## Process

### 1. Explore

**Scope before you scan.** A deeper module pays off by making future changes easier, so
weight the code that changes. Decide where to look first:

- If the user named a module, subsystem or pain point, take it and skip the inference.
- Otherwise find the hot spots in history: `git log --since="6 months ago" --name-only
  --pretty=format: | sort | uniq -c | sort -rn | head -30`. Files and directories that keep
  appearing pull your attention first. If changes are scattered, widen the net.

Then explore with a fresh-context sub-agent where the environment has one (a delegated
review follows `agent_recovery.md`: a focused scope, in the background, with a time limit).
Do not follow rigid heuristics; note where you feel friction:

- Where does understanding one concept mean bouncing between many small files?
- Where is a module **shallow** - an interface nearly as complex as its body?
- Where was a pure function extracted only for testability, while the real bugs hide in how
  it is called (no **locality**)?
- Where do tightly coupled modules leak across their seams?
- What is untested, or hard to test through its current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it
concentrate complexity, or just move it? "Concentrates" is the signal.

### 2. Present candidates

Write a self-contained HTML file to the scratchpad or OS temp directory - never into the
repo - and open it for the user; tell them the absolute path. Where an Artifact tool is
available, publishing it as a private artifact is fine. Follow [HTML-REPORT.md](HTML-REPORT.md)
for the scaffold, diagram patterns and styling.

For each candidate, a card with:

- **Files** involved
- **Problem**: why the current structure causes friction
- **Solution**: plain English, what would change
- **Benefits**, in terms of locality and leverage, and how the tests would improve
- **Before / after** diagram
- **Strength**: `Strong`, `Worth exploring` or `Speculative`

End with a **Top recommendation**: which candidate first, and why.

If a candidate contradicts an ADR, surface it only when the friction is real enough to
reopen the ADR, and mark it clearly. Do not list every refactor an ADR forbids.

Do **not** propose interfaces yet. Ask which candidate to explore.

### 3. Grill the chosen one

Load `grill-me` and walk the decision tree: constraints, dependencies (use the categories in
[DEEPENING.md in codebase-design](../codebase-design/DEEPENING.md)), the shape of the
deepened module, what sits behind the seam, which tests survive.

As decisions settle, keep the project's language current:

- A deepened module named after a concept missing from `GLOSSARY.md`: add the term
  (create the file lazily).
- A fuzzy term sharpened in conversation: update it there and then.
- A candidate rejected for a load-bearing reason: offer an ADR, so a future review does not
  suggest it again. Skip ephemeral reasons ("not now") and self-evident ones.
- Alternative interfaces wanted: use the design-it-twice pattern in `codebase-design`.

### 4. Tests move with the code

A deepening replaces tests, it does not stack them. Once tests exist at the deepened
module's interface, delete the old unit tests on the shallow modules it absorbed. Say which
you deleted. The `writing-tests` skill and `testing_policy.md` still decide whether a new
test is warranted.

Source: adapted from Matt Pocock's skills (MIT), https://github.com/mattpocock/skills.
