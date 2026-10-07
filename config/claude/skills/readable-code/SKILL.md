---
name: readable-code
description: Readability standard for writing, refactoring and reviewing code - write the plain version, not the naive one or the clever one. Use whenever writing or changing code, and when reviewing a diff or PR.
---

# Readable Code

The same behaviour can be written three ways:

- **Naive** - beginner code. It works, but the same rule is copy-pasted in
  several places, logic sits wherever it was first needed, and a change means
  hunting down every copy.
- **Clever** - code that shows off. Closures returning closures, callbacks
  passed into wrappers, values smuggled out by reference, dense one-liners.
  It may be a few lines shorter or a hair faster, and nobody can follow it
  without a debugger.
- **Plain** - the target. Well structured (SOLID, DRY, each piece in the
  domain it belongs to) and written so a developer new to the file
  understands it in one top-to-bottom read.

Write plain. Plain often costs a few extra lines - a named variable, an
explicit `if`, a second small method. Pay that cost every time. A few lines
and a few microseconds are cheap; a reader misunderstanding the code is how
bugs ship.

## What plain looks like

- **Reads top to bottom.** Data goes in through parameters and comes out
  through return values. The reader never has to jump into a closure defined
  somewhere else to learn what happens next.
- **Names tell the truth.** A method does what its name says, and still does
  after the refactor. If `sendConfirmation()` now only claims a record,
  rename it `claimConfirmation()`.
- **One job per method.** Split a method into named steps (`claim`, `send`,
  `markSent`) before you reach for a callback to sequence them.
- **DRY means one home for each rule.** Deduplicate knowledge - a business
  rule, a status transition, a query constraint - into a scope, an Action, an
  enum. Two blocks that merely look alike but change for different reasons
  can stay separate.
- **Code lives in its domain.** Business logic in Actions/Services, query
  constraints in scopes, validation in FormRequests, authorisation in
  Policies. Controllers and views stay thin.
- **Flat over nested.** Early returns, guard clauses, at most two levels of
  indentation in most methods.
- **Closures stay small and local.** A short `fn` passed to `map`, `filter`,
  `DB::transaction` or `Cache::lock` is fine when its whole body fits on a
  few lines and it does not reach back out to change outer variables.

## Signs of clever code, and the plain rewrite

| Clever | Plain |
|---|---|
| A method returns a `Closure` for the caller to run later | Return the data (a model, a DTO) and call a named method with it |
| Closure inside closure inside closure | Named private methods, called in order |
| `function () use (&$result)` to get a value out | Return the value |
| A `withSomething(fn () => ...)` wrapper whose only job is setup and teardown | `try` / `finally` inline, or a well-named method that does the whole job |
| `$callback?->__invoke()` | `if ($callback) { $callback(); }` - or better, no callback |
| A collection pipeline mixing filtering, mapping and side effects | A `foreach` with the side effect in plain sight |
| An abstraction, interface or generic helper with one caller | The concrete code, until a second caller exists |
| A transaction closure that returns one value and writes two more by reference | A small result object, or split the work into separate methods |

## Signs of naive code, and the plain rewrite

| Naive | Plain |
|---|---|
| The same condition or query copy-pasted in several places | A model method, query scope or enum |
| A 150-line controller method doing validation, queries and side effects | FormRequest + Action, controller just wires them |
| Magic strings and numbers | Enums, constants, config |
| Deep `if` / `else` pyramids | Early returns |

## Example

Clever - correct, and it takes four hops to see that an email gets sent:

```php
public function sendBookingConfirmation(ApplicationForm $form): void
{
    $this->withEmailLock($form, Touch::BOOKING_CONFIRMATION, function () use ($form): void {
        $sendEmail = DB::transaction(function () use ($form): ?Closure {
            Candidate::whereKey($form->candidate_id)->lockForUpdate()->first();

            return $this->sendBookingConfirmationLocked($form->fresh()); // returns a closure
        });

        $sendEmail?->__invoke();
    });
}
```

Plain - a few more lines, read once and understood:

```php
public function sendBookingConfirmation(ApplicationForm $form): void
{
    $lock = Cache::lock("application-email:{$form->id}:booking_confirmation", 60);
    $lock->block(30);

    try {
        $touch = DB::transaction(fn () => $this->claimBookingConfirmation($form));

        if ($touch) {
            $this->sendTemplateEmail($touch, $form->candidate, 'cleaner_interview_confirmation');
        }
    } finally {
        $lock->release();
    }
}
```

## The test

Hand the method to a developer who has never seen the file. After one read
from top to bottom, can they say what it does, in what order, and what it
returns? If they would need to trace a closure, follow a reference variable,
or open three other methods to answer, rewrite it plain.

## When reviewing

Unreadable code is a change request, not a nit. Name which of the three the
code is, point at the specific construct from the tables above, and include
the plain rewrite so the author can see the target.
