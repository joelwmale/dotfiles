---
name: creating-pull-requests
description: Use when creating a pull request description. Triggers on "make a PR", "open a pull request", "create a PR", or after finishing work that's ready for review.
---

# Creating Pull Requests

Write for a reviewing engineer skimming _before_ they open the diff — not a
full technical narrative, and not a stripped-of-jargon business summary (that's
`creating-clickup-tickets`). The diff is where line-by-line detail lives; the
description's job is to tell the reviewer what to expect and where to look.

This governs the _writing altitude_ of the PR description — it doesn't
replace the mechanics of gathering commit history and diffing against the
base branch, which existing git workflow instructions already cover.

**Summary only — no Test plan section.** Don't add a "## Test plan" checklist
even if a default template suggests one. If verification is worth mentioning,
fold it into a Summary bullet (see example).

## Workflow

1. Gather the full commit history and diff against the base branch — not just
   the latest commit.
2. Group changes by theme/intent, not commit-by-commit.
3. Write the Summary: 2–5 bullets, one theme each.
4. Call out anything risky or uncertain explicitly (a known flake, a required
   migration, a follow-up needed) instead of burying it in a bullet.

## Altitude Checklist

| Keep                                                             | Drop                                                  |
| ---------------------------------------------------------------- | ----------------------------------------------------- |
| System/component names (checkout page, billing job, CI pipeline) | Line-by-line code narration                           |
| The core mechanism, in one clause ("switched from X to Y")       | Full stack traces, raw error text                     |
| Concrete verification evidence, folded into a bullet if relevant | Every touched file enumerated                         |
| Explicitly called-out risks or follow-ups                        | Config/diff pasted inline, separate Test plan section |

**Test:** would a reviewer who hasn't opened the diff yet understand what to
expect and why, without reading every line? If yes, right altitude. If they'd
need to open the diff to understand the bullet, too vague — add the mechanism.
If the bullet reads like a commit message with inline code, too technical —
pull back to the outcome.

## Example

<Bad — too technical, reads like the commit message>
deploy-production previously ran on every successful Tests run for a push to
master. Now only deploys off a published GitHub Release (`release: types:
[published]` trigger); `deploy-production` conditions on `github.event_name
== 'release'` instead of `github.ref == 'refs/heads/master'`.
</Bad>

<Good — right altitude for a reviewer>

- Production deploys now trigger off published GitHub Releases instead of
  every push to `master`, adding a deliberate checkpoint before code reaches
  customers. Staging is unchanged — still deploys on every push to `develop`.
- Fixed 4 CI-only test failures invisible until now (Feature-suite tests were
  silently skipped in CI until this change): a missing frontend asset build
  step, and a MySQL string-vs-int type bug in the sales report query.
- Local tests now run against MySQL instead of SQLite to match CI/production,
so driver-specific bugs like the one above get caught before push. Full
suite passes locally and in CI.
</Good>

## When to Break This

If the user asks for a fully technical PR (e.g. "include exact code changes"
for a detailed audit trail), a non-technical one (rare for a PR, but possible
for a stakeholder-facing changelog), or explicitly wants a Test plan section
back, match that instead. This altitude — and Summary-only — is the default,
not a hard rule.
