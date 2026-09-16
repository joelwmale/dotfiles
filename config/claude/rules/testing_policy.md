# Testing Policy (Proportionate)

Applies to every change.

## This file is the only authority on whether to test

There is no second opinion to weigh against it.

| Question | Answer lives in |
|---|---|
| **Whether** a test gets written | **This file. Nowhere else.** |
| **How** to write it, once this file says to | the `writing-tests` skill |

`superpowers:test-driven-development` is **disabled** in settings.json via
`skillOverrides`, precisely so there is nothing to arbitrate between. There is
no coverage target anywhere.

If any other source - a plugin skill, an agent, a project `CLAUDE.md`, a
generic TDD instinct - implies a test for something this file places in Tier 3,
**this file wins, and you do not need to ask.**

### Named subordinates

Turning the TDD skill off does not remove TDD instructions embedded in other
skills' text. These are known, and this file governs all of them:

- **`superpowers:writing-plans`** says "DRY. YAGNI. TDD." When writing a plan,
  **tier every task here first** and mark TDD only on Tier 1 tasks. A plan that
  marks a copy change or a one-off command TDD is a defective plan.
- **`superpowers:subagent-driven-development`** tells implementers to "write
  tests (following TDD if task says to)" and to report TDD evidence "if TDD was
  required". The task says to only when the task is Tier 1. State the tier in
  the task so the subagent does not have to guess.
- **`superpowers:systematic-debugging`** points at the TDD skill for writing a
  failing test. Use the `writing-tests` skill instead. The reproduction test for
  a real bug is Tier 1 anyway, so this one usually agrees with us.
- **`superpowers:brainstorming`** says "TDD applies" to the normal development
  workflow. It applies per the tiers below.

**Skipping a test under Tier 3 is the correct call, not a rationalisation.**
Generic TDD guidance assumes every change carries silent risk. Across these
projects that assumption has been wrong often enough to produce suites of
thousands of tests running for tens of minutes, where most never catch anything
and all of them slow the work down. A test that cannot fail is not neutral - it
costs runtime, review attention, and trust in the suite.

---

## The question to ask

**If this silently broke, would anyone notice before a customer did?**

- **No** - the behaviour is invisible until it is wrong in production. Test it.
- **Yes, immediately and obviously** - the change is visible on the page, or the
  command either works or does not the one time it runs. Do not test it.

Not "is this code?" Not "is this a feature?" Only: can it break quietly.

---

## Tier 1 - test first, TDD

Write the failing test, watch it fail, then implement. Mechanics are in the
`writing-tests` skill. A change is Tier 1 if it touches any of:

- authentication, authorisation, or a permission gate
- money, billing, pricing, discounts, credit or refunds
- an irreversible or externally visible side effect: a deploy, a publish, a
  delete, a webhook that fires, a message to a customer
- request-signature or token verification
- a state machine whose stuck states block future work
- tenancy or data scoping between accounts
- anything that writes to a client's repository or infrastructure

Also Tier 1 regardless of subject matter:

- **a security fix.** Verify it by deleting the guard, watching the test fail,
  and restoring it. A test that stays green without the guard is not a test.
- **a bug fix.** The test reproduces the bug first. That is what stops it
  coming back.

## Tier 2 - test in the same commit, after implementing

Ordinary behaviour with branches, calculations, parsing or persistence:
services, actions, jobs, queries, components that hold state, API endpoints.

A feature test that exercises the real path is worth more than three unit tests
around it. One good test is the target, not a suite.

## Tier 3 - do not write a test

Write the change, verify it works, move on. No test, and no apology for the
absence of one:

- copy, text, labels, translations, markup and styling
- Blade or component changes with no logic beyond rendering what it was given
- one-off commands, scripts and data migrations that run once and are deleted
- migrations that only add a nullable column or an index
- config values, seeders, factories
- comments, docblocks, formatting, renames, import ordering
- dependency version bumps with no code change
- anything already covered by an existing test that still passes

---

## Coverage

**There is no coverage target.** A percentage drives tests written to move a
number rather than to catch a defect, which is how a suite ends up slow,
brittle and trusted less than it should be.

Judge the suite by whether deleting a guard turns it red, not by what it
reports.

---

## Always, regardless of tier

- **Say which tier you picked** when it is not obvious, in one clause. "Tier 3,
  copy change, no test" is enough.
- **When a change sits between two tiers, take the higher one.**
- **When a Tier 2 or 3 change turns out to touch a Tier 1 concern, stop and
  re-tier it.** A "just change the label" task that turns out to alter what a
  permission check reads is Tier 1.
- **Run the existing suite** on anything above Tier 3, even when adding no test.
- **A test proving a guard exists must prove the guarded action did not
  happen.** Asserting a status code, a returned string, or that something threw
  is not enough - the guard can be deleted with the test still green.

## Do not

- Do not write a test to demonstrate diligence. An assertion that cannot fail
  is worse than no test: it costs runtime and implies coverage that is absent.
- Do not test framework behaviour. Laravel's validator, Eloquent's casting and
  the router are already tested.
- Do not test a one-off command by mocking the world it runs in. Run it.
- Do not add a test to a Tier 3 change because the diff "felt too small".
- Do not ask permission to skip a Tier 3 test. Skip it and say so.
