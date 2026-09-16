---
name: writing-tests
description: How to write a test that actually catches defects - TDD mechanics for high-risk work, naming the break, avoiding mock theatre, and the mutation check. Use when writing or changing any test. Whether a test is warranted at all is decided by rules/testing_policy.md, not here.
---

# Writing Tests

## This skill does not decide whether to test

**`rules/testing_policy.md` decides that, and it is the only thing that does.**
Tier the change there first:

- **Tier 1** - test first, TDD. Use the Red-Green-Refactor section below.
- **Tier 2** - test in the same commit, after implementing.
- **Tier 3** - no test. Stop reading; there is nothing for this skill to do.

If you arrived here without tiering, go and tier it. Writing a test for a Tier 3
change is a defect in the work, not diligence.

---

## Red-Green-Refactor (Tier 1)

For Tier 1 work - auth, money, irreversible effects, tenancy, security fixes,
bug fixes - write the test first.

### RED: write the failing test

Before writing it, answer one question out loud:

> **What production change would make this test fail?**

If you cannot name it, the test asserts nothing. Rewrite it.

### Verify RED: watch it fail

Run it. Read the failure message.

**This is the step that gives the test its value.** A test you never saw fail is
a test you have not proven can catch anything. If it fails for the wrong reason
- a typo, a missing factory, the wrong exception - fix that and watch it fail
for the right reason before continuing.

### GREEN: minimal code

Write the least code that passes. Not the design you have in mind - the least
code. The design emerges in refactor, with a passing test protecting you.

### Verify GREEN: watch it pass

Run the new test and the whole suite.

### REFACTOR

Clean up with the test green. Re-run after each change.

---

## The mutation check

The only real proof a test works:

**Break the code on purpose. The test must go red.**

Invert the condition, delete the guard, return the wrong value. If the suite
stays green, the test is decoration - it costs runtime and implies a safety it
does not provide.

For anything security-relevant this is not optional. **Delete the guard, watch
the test fail, restore the guard.** A guard can be removed with an
assertion-on-status-code test still passing, which is exactly how a regression
ships.

```php
// NOT ENOUGH - passes even if the deletion goes through
$this->actingAs($other)->delete($url)->assertForbidden();

// PROVES THE GUARD - asserts the action did not happen
$this->actingAs($other)->delete($url)->assertForbidden();
expect(Product::find($product->id))->not->toBeNull();
```

---

## What makes a test worth its runtime

### Assert on behaviour, not on mocks

A mock assertion passes when the mock was called. It says nothing about whether
the real thing works. If the only assertions in a test are on doubles, the test
proves the test.

- Prefer the real collaborator. Reach for a double when the real one is slow,
  external or non-deterministic - not by default.
- When mock setup outgrows the test, that is the signal to use the real object.
- Mirror real payload shapes completely. A double returning a convenient
  half-object hides the field that breaks in production.

### Test your code, not the framework

Laravel's validator, Eloquent's casting, the router and the queue are already
tested. A test asserting `required` rejects null is testing Laravel.

Test the contract *your* code makes: the rule set you chose, the scope you
applied, the state transition you defined.

### Derive expectations independently

Hand-check the expected value. Do not compute it with the same code under test -
that passes whether or not the logic is right.

### One behaviour per test

"and" in the test name means split it. A test asserting five things fails
opaquely and gets deleted rather than fixed.

### No change detectors

A test that fails whenever anyone touches unrelated code trains people to
update assertions without reading them. Assert on the decision, not on the
exact rendered string or the full serialised payload.

---

## Pest and Laravel specifics

- Feature tests over unit tests. One test through the real path beats three
  around it.
- Factories for all setup. No hand-built arrays that drift from the schema.
- `RefreshDatabase`, not a hand-rolled teardown.
- Never test private methods. Test the behaviour that exercises them.
- **`Http::fake()` every URL a code path can reach.** A URL not in the fake
  array is attempted for real - it raises a connection error, or worse, reaches
  the live service. Assert with `Http::assertNotSent()` on the specific request
  a guard should prevent.
- Livewire: `->set()` the tampered property explicitly. A single-request test
  passes against a two-request tampering exploit. See `livewire-conventions`.
- Time-dependent behaviour uses `travelTo()`, never a real sleep.

---

## Rationalisations that are wrong

These apply **once the policy says a test is warranted**. They are not
arguments for testing a Tier 3 change.

| Excuse | Reality |
|---|---|
| "I'll write the test after" | A test written after the code passes immediately, which proves nothing. You never saw it fail, so you never proved it can catch the bug. It is also biased toward the cases you happened to remember. |
| "I already tested it manually" | No record of what you covered, no way to re-run it on the next change. |
| "Test is hard to write" | Listen to it. Hard to test usually means hard to use. Fix the design. |
| "I'll keep the code as reference and write tests around it" | You will adapt it, which is testing after. |
| "It's too simple to break" | For Tier 1 subject matter this is wrong - simple auth and money code breaks, and breaks quietly. For Tier 3 it is correct, and the policy already said not to test it. |

## Rationalisations that are correct

Say these plainly, do not apologise for them:

- "Tier 3, copy change, no test."
- "Tier 3, one-off command, ran it, it worked, deleting it after."
- "Covered by the existing feature test, which still passes."
- "This assertion cannot fail, so I am not writing it."

## Warning signs in a test you are writing

- You cannot name the production change that would make it fail
- It passed the first time you ran it
- Every assertion is on a mock
- It asserts an exact string that any wording change would break
- It needs more setup than the code under test has lines
- You are writing it because the diff felt too small without one
