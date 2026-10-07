---
name: readable-code
description: Readability standard for code in any language - write the plain version, not the naive one or the clever one. Load before writing or changing any code, and when reviewing a diff or PR.
---

# Readable Code

The same behaviour can be written three ways:

- **Naive** - beginner code. It works, but the same rule is copy-pasted in
  several places, logic sits wherever it was first needed, and a change means
  hunting down every copy.
- **Clever** - code that shows off. Closures returning closures, callbacks
  passed into wrappers, multi-line lambdas chained through `map` and
  `reduce`, values smuggled out by reference, dense one-liners. It may be a
  few lines shorter or a hair faster, and nobody can follow it without a
  debugger.
- **Plain** - the target. Well structured (SOLID, DRY, each piece in the
  domain it belongs to) and written so a developer new to the file
  understands it in one top-to-bottom read.

Write plain, in every language. Plain often costs a few extra lines - a named
variable, an explicit `if`, a loop, a second small function. Pay that cost
every time. A few lines and a few microseconds are cheap; a reader
misunderstanding the code is how bugs ship.

## What plain looks like

- **Reads top to bottom.** Data goes in through parameters and comes out
  through return values. The reader never has to jump into a closure defined
  somewhere else to learn what happens next.
- **Names tell the truth.** A function does what its name says, and still
  does after the refactor. If `sendConfirmation()` now only claims a record,
  rename it `claimConfirmation()`.
- **One job per function.** Split work into named steps (`claim`, `send`,
  `markSent`) before you reach for a callback to sequence them.
- **DRY means one home for each rule.** Deduplicate knowledge - a business
  rule, a status transition, a query constraint - into one function, method,
  type or constant. Two blocks that merely look alike but change for
  different reasons can stay separate.
- **Code lives in its domain.** Follow the framework's layering: business
  logic in its service layer, validation and authorisation where the
  framework puts them, entry points (controllers, handlers, components,
  views) thin. In Laravel that is Actions/Services, scopes, FormRequests and
  Policies.
- **Flat over nested.** Early returns, guard clauses, at most two levels of
  indentation in most functions.

## Anonymous functions

A one-line anonymous function that names a simple condition or key is plain:

```php
$orders->filter(fn (Order $order) => $order->isComplete());
```
```ts
users.sort((a, b) => a.lastName.localeCompare(b.lastName));
```

Once the body runs past one line, or holds a branch, a side effect or a
nested lambda, give it a name: extract a named function, or write the loop.
The same goes for chains - two or three single-line steps read fine; a long
`map` / `filter` / `reduce` pipeline with logic inside each step reads better
as a loop with named variables.

`match` / `switch` expressions are plain when each arm maps a value to a
value. When an arm holds logic, move that logic into a named function and
let the arm call it.

## Signs of clever code, and the plain rewrite

| Clever | Plain |
|---|---|
| A function returns a function for the caller to run later | Return the data (a record, a DTO) and call a named function with it |
| Lambda inside lambda inside lambda | Named functions, called in order |
| A multi-line lambda passed to `map`, `reduce` or a `match` arm | A named function, or a loop |
| A closure that writes outer variables to get values out (`use (&$x)`, mutated captures, `nonlocal`) | Return the value |
| A `withSomething(fn)` wrapper whose only job is setup and teardown | `try` / `finally` inline, or a well-named function that does the whole job |
| A pipeline mixing filtering, mapping and side effects | A loop with the side effect in plain sight |
| Nested ternaries, nested comprehensions, chained optional calls doing logic | `if` statements and named variables |
| An abstraction, interface or generic helper with one caller | The concrete code, until a second caller exists |

## Signs of naive code, and the plain rewrite

| Naive | Plain |
|---|---|
| The same condition or query copy-pasted in several places | One named function, method, scope or type |
| A 150-line handler doing validation, queries and side effects | Split into the framework's layers; the handler wires them together |
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

## The one-read test

Hand the function to a developer who has never seen the file. After one read
from top to bottom, can they say what it does, in what order, and what it
returns? If they would need to trace a closure, follow a captured variable,
or open three other functions to answer, rewrite it plain.

## Before you call the work done

Re-read every function you added or changed against the two tables and the
anonymous-function rule above. The work is done when each one passes the
one-read test or has been rewritten until it does.

## When reviewing someone else's code

Unreadable code is a change request, not a nit. Name which of the three the
code is, point at the specific construct from the tables, and include the
plain rewrite so the author can see the target.
