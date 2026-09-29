---
name: brainstorming
description: Use before building a feature, component or behaviour change, to agree what is being built before any code is written. Turns an idea into an approved design - a short in-chat design for bounded changes, a written spec for architectural ones.
---

# Brainstorming Ideas Into Designs

Turn an idea into a design the user has approved, through conversation. Adapted from
obra/superpowers (MIT, see LICENSE).

## Shared understanding first

1. **Find the intent.** From the request and context, work out the outcome, who it is for
   and what success looks like. If that is missing, ask one question about purpose before
   proposing features. Knowing the kind of app does not tell you why the user wants it.
2. **Write it back.** Summarise the outcome, constraints and success criteria in a short
   note, separating what the user said from what you assumed, and invite correction.
3. **Carry it into the design.** Check proposed features and technical choices against
   that note.

When the request already states purpose and constraints, reflect them back rather than
asking again.

## Pick a path and say which

Classify the request before your first question and say so ("this looks bounded, so I'll
put a short design here rather than write a spec"), so the user can override it.

- **Spike** - a feasibility question whose output is an answer, not kept code. Say what
  you will try in two or three sentences, get a nod, then find out as cheaply as
  correctness allows. Report a recommendation; label anything built as throwaway.
- **Bounded** - a well-scoped change to a flow that already exists in this repo: a flag,
  a small endpoint, a one-file fix. Ask the questions that matter, present a short design
  in chat (approach, files touched, testing tier), and wait for a yes. No spec file.
- **Architectural** - new projects, new subsystems, or changes to how components fit
  together or to interfaces others depend on. Full process below.

Bounded is measured by the repo, not by familiarity with the kind of app: with no existing
flow to change, it is architectural. Between two paths, take the heavier one. If hidden
complexity turns up mid-task, stop, say so and move up a path; nothing moves down.

## Approval is the gate

Implementation - product code, scaffolding, installing dependencies - starts only after
the user approves what the path requires: the probe for a spike, the in-chat design for
bounded work, the written spec and then the implementation plan for architectural work.
An approval covers the stage that was presented, not later artifacts. Read-only
exploration is fine before approval. Each follow-up task gets its own classification.

## Architectural process

1. Explore the project: files, docs, recent commits. If the request is really several
   independent subsystems, say so and agree the first one to design.
2. Start the visual companion (below) without asking.
3. Ask clarifying questions one per message, multiple choice where it fits, until
   purpose, constraints and success criteria are clear.
4. Propose two or three approaches with trade-offs, leading with your recommendation.
   Cut features the goal does not need.
5. Present the design in sections sized to their complexity - architecture, components,
   data flow, error handling, testing - and check each section with the user.
6. Write the approved design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
   (where existing specs live, unless the project says otherwise) and commit it.
7. Re-read the spec for placeholders, contradictions, ambiguity and scope that needs
   splitting, and fix them inline.
8. Ask the user to review the spec file and wait for approval.
9. Write the implementation plan, tiering each task per `testing_policy.md` and
   `review_policy.md`, and get it approved before implementing.

## Design principles

- Units with one clear purpose, well-defined interfaces, and internals that can change
  without breaking consumers.
- In an existing codebase, follow its patterns. Include targeted fixes to code the work
  touches, such as an overgrown file, but no unrelated refactoring.

## Visual companion

A browser tab for mockups, diagrams and visual comparisons. Start it at the beginning of
architectural brainstorming, then decide per question: use the browser when the answer is
visual (layouts, wireframes, diagrams, side-by-side designs) and the terminal when it is
words (requirements, scope, trade-offs, approach choices). A question about a UI topic is
not automatically a visual question.

Setup and usage: `~/.claude/skills/brainstorming/visual-companion.md`.
