---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs and performance regressions - build a fast red/green feedback loop first, then reproduce, hypothesise, instrument, fix and clean up. Use when the user says "diagnose" or "debug this", or reports something broken, throwing, failing or slow, and the cause is not already obvious.
---

# Diagnosing Bugs

A discipline for hard bugs. Skip a phase only when you can say why. A bug whose cause is
obvious from the stack trace does not need this; fix it and write the regression test per
`testing_policy.md` (a bug fix is Tier 1: the test reproduces the bug first).

Read the project glossary (`GLOSSARY.md` or `docs/GLOSSARY.md`) and the docs for the area, if they exist.

## Redact

You will show commands, output and captured artifacts. **Redact every secret first**,
writing `<REDACTED>` in its place: `.env` values, API keys (Stripe, Klaviyo, Google,
Meilisearch), session cookies, `Authorization` headers, bank details, personal data.
Build loops that read secrets from the environment, so they never sit in what you show. A
captured request carries auth headers; quote only the lines that carry the signal. If the
redacted output is not enough to diagnose the bug, say so and ask.

## Phase 1: Build a feedback loop

**This is the skill.** With a tight pass/fail signal that goes red on *this* bug, you will
find the cause; bisection, hypotheses and instrumentation just consume it. Without one, no
amount of staring at code helps. Spend disproportionate effort here.

Ways to build one, roughly in this order:

1. **A failing Pest test** at whatever seam reaches the bug: `bin/test --filter=...`. A
   Livewire test with `->set()` and `->call()`, or a feature test through the route.
2. **`curl` against the running app** - `https://rethread.test` under Herd, or the dev
   server - with a real session cookie or token read from the environment.
3. **`php artisan tinker --execute='...'`** calling the action, query or job directly
   against the local database. Never `migrate:fresh` it.
4. **A browser run** for a UI bug: a Pest browser test, or the claude-in-chrome tools, that
   drives the page and asserts on the DOM, console and network.
5. **Replay a captured payload** - a webhook body, an import file, a failed job's payload
   from `failed_jobs` - through the code path in isolation.
6. **A throwaway harness**: a scratch command or test that calls one function with the
   minimal setup.
7. **A fuzz or property loop** when the symptom is "sometimes wrong output": run a thousand
   random inputs and look for the failure.
8. **Bisection**: when it worked at an earlier commit, automate "check at state X" and run
   `git bisect run bin/test --filter=...`.
9. **A differential loop**: the same input through the old and new version, or two
   configs, diffing the output.
10. **A human in the loop**, last. Ask the user to run one exact command and paste the
    output, so the loop is still structured.

**Tighten it.** Faster (narrow the test scope, skip unrelated setup), sharper (assert the
specific symptom, not "did not crash"), more deterministic (`travelTo()`, seed the random
source, `Http::fake()`, `Queue::fake()`). A 30-second flaky loop is barely better than none;
a two-second deterministic one is a debugging superpower.

**Non-deterministic bugs**: the goal is a higher reproduction rate, not a clean repro. Loop
the trigger a hundred times, run in parallel, narrow the timing window. A 50% flake is
debuggable; a 1% flake is not, so keep raising the rate.

**Cannot build a loop?** Stop and say so. List what you tried and ask for access to the
environment that reproduces it, a redacted captured artifact, or permission to add temporary
instrumentation. Do not hypothesise without a loop.

### Done when

You can name **one command** you have already run, whose output you can show (redacted),
that is:

- [ ] **Red-capable**: it drives the real code path and asserts the user's exact symptom, so
  it can go red on this bug and green once fixed. "Runs without erroring" is not it.
- [ ] **Deterministic**: the same verdict every run.
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: no human needed unless step 10.

If you catch yourself reading code to build a theory before this command exists, stop. That
is the exact failure this skill prevents.

## Phase 2: Reproduce and minimise

Run it and watch it go red. Confirm it shows the failure the **user** described, not a
neighbouring one (wrong bug, wrong fix), that it repeats, and that you have captured the
exact symptom (message, wrong value, timing).

Then **minimise**: cut inputs, callers, config, data and steps one at a time, re-running
after each cut, until every remaining element is load-bearing - removing any one makes it go
green. A minimal repro shrinks the hypothesis space and becomes the regression test.

## Phase 3: Hypothesise

Write **three to five ranked hypotheses** before testing any. One hypothesis anchors on the
first plausible idea. Each must be falsifiable and state its prediction:

> If `<X>` is the cause, then changing `<Y>` will make the bug disappear, or changing `<Z>`
> will make it worse.

A hypothesis with no prediction is a vibe; sharpen or discard it. **Show the ranked list to
the user before testing.** They often re-rank it instantly ("we deployed a change to #3").
Do not block on it if they are away.

## Phase 4: Instrument

Each probe maps to a prediction. Change one variable at a time.

1. A debugger or REPL inspection (`tinker`) if available: one breakpoint beats ten logs.
2. Targeted logs at the boundaries that tell hypotheses apart. Never "log everything and grep".

**Tag every temporary log** with a unique prefix, for example `Log::debug('[DEBUG-a4f2] ...')`,
so cleanup is one grep. `dd()`, `dump()`, `ray()`, `var_dump()` and `print_r()` must never
reach a commit.

**Performance bugs**: logs are usually wrong. Take a baseline measurement first - a timing
harness, `DB::listen()` for the query count and time, `EXPLAIN` on the slow query, a
profiler - then bisect. Measure first, fix second. The usual causes are an N+1, a missing
index, or work done per row that belongs outside the loop.

## Phase 5: Fix and regression test

Write the regression test **before** the fix, if a correct seam exists. A correct seam
exercises the real bug pattern as it occurs at the call site. If the only seam is too
shallow (a single-caller test when the bug needs several callers), a test there gives false
confidence. **No correct seam is itself a finding**: the structure is preventing the bug
from being locked down. Note it for the architecture review (`improve-codebase-architecture`).

With a correct seam:

1. Turn the minimised repro into a failing test.
2. Watch it fail. If you forced the red by mutating code or a fixture, diff against a
   pristine copy to prove the mutation landed.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 loop against the original, un-minimised scenario.

## Phase 6: Clean up

Required before saying it is done:

- [ ] The original repro no longer reproduces
- [ ] The regression test passes, or the absence of a seam is written down
- [ ] Every `[DEBUG-...]` line is gone (`grep` the prefix)
- [ ] Throwaway harnesses and scratch files are deleted
- [ ] The hypothesis that turned out to be right is in the commit and PR message, so the next
  person debugging learns from it

Source: adapted from Matt Pocock's `diagnosing-bugs` skill (MIT),
https://github.com/mattpocock/skills.
