---
name: review-branch
description: "Review the changes since a fixed point (commit, branch, tag or merge-base) on two separate axes - Standards (does the code follow this repo's documented rules?) and Spec (does it do what the issue asked?) - using parallel sub-agents, reported side by side. Use when asked to review a branch, a PR or work in progress, or to 'review since X'. For security-focused review of a diff use differential-review."
---

# Review Branch

Two-axis review of the diff between `HEAD` and a fixed point:

- **Standards**: does the code conform to this repo's documented standards?
- **Spec**: does the code do what the originating issue or spec asked?

Each axis runs as its own sub-agent with a fresh context so neither colours the other, and
the results are reported separately. A change can pass one axis and fail the other: code
that follows every standard but builds the wrong thing, or does exactly what the ticket
said and breaks the conventions. One merged ranking would let one axis mask the other.

Review delegation follows `agent_recovery.md`: focused slices, background, time limit. A
large diff is split by directory or feature, with the diff for that slice in the prompt.

## Process

### 1. Pin the fixed point

Whatever the user gave is the fixed point (SHA, branch, tag, `master`, `HEAD~5`). If they
gave none, ask. Capture the diff once as `git diff <fixed-point>...HEAD` (three dots, so it
compares against the merge-base) and the commits as `git log <fixed-point>..HEAD --oneline`.

Check `git rev-parse <fixed-point>` resolves and the diff is non-empty before spawning
anything. A bad ref should fail here, not inside two sub-agents.

### 2. Find the spec

In order:

1. An issue reference in the commit messages or branch name (`RET-17`, `#123`, `Closes
   #45`), fetched with `gh` or the project's tracker tools (its `CLAUDE.md` names the tracker).
2. A path the user passed.
3. A spec under `docs/`, `specs/` or `docs/superpowers/specs/` matching the branch.
4. Otherwise ask. If there is no spec, skip the Spec axis and say so.

### 3. Find the standards

Collect every file that says how code is written here: the project `CLAUDE.md`, `AGENTS.md`,
`CONTRIBUTING.md`, `CODING_STANDARDS.md`, `docs/`, and the user's rules in
`~/.claude/rules/` (`php_coding_rules`, `code_comments`, `testing_policy`,
`review_policy`, `git_workflow`). Tools already enforce formatting and static analysis
(Pint, PHPStan, ESLint), so skip anything they catch.

On top of the documented standards, the Standards axis always carries the **smell
baseline** below: Fowler's code smells (*Refactoring*, ch. 3). Two rules bind it:

- **The repo overrides.** A documented standard always wins; where it endorses something
  the baseline would flag, suppress the smell.
- **Always a judgement call.** Each is a labelled heuristic ("possible Feature Envy"),
  never a hard violation.

- **Mysterious Name**: a name that does not reveal what the thing does or holds. Rename; if
  no honest name comes, the design is murky.
- **Duplicated Code**: the same logic shape in more than one hunk. Extract and call it.
- **Feature Envy**: a method reaching into another object's data more than its own. Move it.
- **Data Clumps**: the same few fields or parameters travelling together. Give them a type.
- **Primitive Obsession**: a string or int standing in for a domain concept (a status, a
  money amount). Give it an Enum or value object.
- **Repeated Switches**: the same `match` or `if` cascade on one type recurring. Replace
  with polymorphism or one shared map.
- **Shotgun Surgery**: one logical change forcing scattered edits. Gather what changes together.
- **Divergent Change**: one file edited for several unrelated reasons. Split it.
- **Speculative Generality**: abstraction, parameters or hooks for needs the spec lacks.
  Delete it.
- **Message Chains**: long `a->b()->c()->d()` navigation the caller should not know. Hide it.
- **Middle Man**: a class that mostly delegates onward. Cut it.
- **Refused Bequest**: a subclass ignoring most of what it inherits. Use composition.

### 4. Run both reviews in parallel

Issue both sub-agent calls together, in the background, and aggregate once both have reported.

**Standards sub-agent**, given: the diff command and commit list; the standards files from
step 3 plus the smell baseline pasted in full (it has no other access to it). Brief:

> Report, per file or hunk, (a) each place the diff violates a documented standard, citing
> the file and rule, and (b) any baseline smell, naming it and quoting the hunk. Separate
> hard violations from judgement calls: documented breaches can be hard, baseline smells
> are always judgement calls, and a documented standard overrides the baseline. Skip
> anything tooling enforces. Report only findings a maintainer would act on.

**Spec sub-agent**, given: the diff command and commit list, and the spec's contents. Brief:

> Report (a) requirements the spec asked for that are missing or partial, (b) behaviour in
> the diff that was not asked for, (c) requirements that look implemented but look wrong.
> Quote the spec line for each finding. Report findings only, not a summary of what matches.

### 5. Report

Present `## Standards` and `## Spec`, verbatim or lightly cleaned. Do not merge or re-rank
them. End with one line: findings per axis and the worst issue within each axis, never a
single winner across axes.

Source: adapted from Matt Pocock's `code-review` skill (MIT),
https://github.com/mattpocock/skills.
