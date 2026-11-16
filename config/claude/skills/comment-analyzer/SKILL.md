---
name: comment-analyzer
description: Audit code comments and docblocks for accuracy, staleness and value, against the code they describe. Use after writing or changing comments, before opening a PR that touches comments, or when reviewing a file for comment rot. Advisory only - reports, never edits.
---

# Comment Analyzer

Comments rot: the code changes and the comment keeps saying the old thing. A wrong comment is
worse than none. This reviews comments, skeptically, from the point of view of someone
reading the code a year from now without any context.

The house rule is `code_comments.md`: **code says what, comments say why**, one line almost
always, and a comment must survive "delete it - is anything lost?". This skill applies that
rule to comments that already exist, and checks they are still true.

Report only. Do not edit code or comments.

## What to check, in order

### 1. Accuracy (the highest-value check)

Cross-reference every claim against the code beneath it:

- Does the described behaviour match what the code does now, including edge cases and the
  failure path?
- Do named functions, classes, columns, config keys and flags still exist, and do they do
  what the comment says?
- Do stated parameter types, units, ranges and return values match the signature?
- Are performance, ordering or "always"/"never" claims true? Those are the ones that rot
  first.
- Is a `TODO`/`FIXME` already done, or does it point to a ticket that is closed?
- Do examples in a docblock still run?

### 2. Does it earn its place?

Flag for removal:

- **Restates the line** ("Loop through each user", "Get the errors")
- **Narrates the change** ("Added null check", "Updated to handle empty arrays", "New:
  pagination") - that is a commit message
- **Step narration** in a short function ("Step 1... Step 2...") - split the function
- **Justifies a decision** the reader did not question; the reasoning belongs in the PR,
  commit or ticket. A comment growing past one line usually started defending a choice.
- **Commented-out code** - git has it
- **A docblock repeating the signature** (`@param string $email` above `string $email`)
- **A framework fact** ("Eloquent will hydrate this")
- **Temporary state** ("for now", "until we migrate", "temporary") with no owner or date

### 3. Is a missing comment dangerous?

Do not ask for comments to be added by default; the house style is sparse. Ask only whether
there is a hidden constraint a reader would "fix" and break:

- A business or legal rule the code cannot express
- An ordering or coupling that must be preserved ("must run before X")
- A workaround for an external system, with where to read about it
- Code that looks wrong but is right
- A guard whose removal would be a security or money bug

If one of these is uncommented, suggest **one line**.

### 4. Could it mislead?

Ambiguous wording with two readings, references to code that was refactored, an assumption
that no longer holds, an example that does not match the implementation.

## Output

```
Summary: <scope and finding counts>

Critical (wrong or misleading)
- path:line - <what the comment says> vs <what the code does>. Fix: <one-line rewrite or delete>

Remove (adds nothing)
- path:line - <why>

Missing (a hidden constraint with no comment)
- path:line - <the constraint>. Suggested line: <comment>

Keep (good examples)
- path:line - <why it works>
```

Lead with the critical ones. If there is nothing to report, say so in one line. Do not pad
the list.

Source: adapted from Anthropic's `comment-analyzer` agent (Apache 2.0),
https://github.com/anthropics/claude-plugins-official, re-aligned to the house comment rule.
