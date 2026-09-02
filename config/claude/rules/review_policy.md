# Review Policy (Strict)

Applies whenever you are running a multi-task plan through
`superpowers:subagent-driven-development`, `superpowers:executing-plans`, or any
similar implement-then-review loop.

**This rule overrides those skills.** They mandate a review gate plus a scoped
re-review for every task, which is correct for code that can cause damage and
wasteful for code that cannot. Rules beat skills; apply the tiers below instead.

---

## Tier the task before dispatching, and say which tier out loud

**Tier 1 — full treatment.** Implement, review, fix, scoped re-review, per task.
Use the most capable model for the review. A task is Tier 1 if it touches any of:

- authentication, authorization, or a permission gate
- money, billing, or anything a customer is charged for
- an irreversible or externally-visible side effect: a merge, a deploy, a
  publish, a delete, a webhook that fires, a message to a customer
- anything that writes to a client's repository or infrastructure
- request-signature or token verification
- a state machine whose stuck states block future work

**Tier 2 — batched review.** Group 2-4 related tasks into one dispatch and review
the batch once. Fix findings in one round. Use for ordinary feature work:
services, jobs, components, refactors with tests.

**Tier 3 — no per-task review.** Implement and move on; the whole-branch review
at the end covers it. Use for migrations that only add nullable columns,
factories, seeders, config keys, comment and docblock changes, test-only
additions, and renames.

When a task sits between two tiers, take the higher one. When a Tier 2 or 3 task
turns out to touch a Tier 1 concern, stop and re-tier it.

---

## Always, regardless of tier

- **One whole-branch review at the end**, on the most capable model, before any
  push. This is never skipped and never batched away.
- **Never skip review on a task you had to fix twice.** Two fix rounds means the
  task is not understood; the third attempt gets a real gate.
- **A test proving a guard exists must prove the guarded action did not happen.**
  Asserting a status, a returned string, or that something threw is not enough —
  an unmatched HTTP fake returns a benign 200 and a guard can be deleted with the
  test still green. When a fix is security-relevant, verify it by removing the
  guard, watching the test fail, and restoring the file.
- **Report tier choices and their cost.** If a Tier 3 call turns out to have been
  wrong, say so plainly rather than quietly upgrading later.

---

## Do not

- Do not dispatch more than one implementation subagent at a time. Concurrent
  implementers produce phantom test failures from each other's uncommitted files
  and reformat each other's work.
- Do not run a review round on a diff that is only comments, only test additions,
  or only formatting.
- Do not ask a reviewer to re-run tests the implementer already ran on the same
  code. The implementer's report carries that evidence.
- Do not treat this rule as licence to skip the final whole-branch review, or to
  skip Tier 1 gates because a plan is running long. If time is the problem,
  batch Tier 2 harder — do not downgrade Tier 1.
