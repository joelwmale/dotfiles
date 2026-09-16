---
name: laravel-conventions
description: Laravel and PHP style conventions - naming, structure, Eloquent, routing, validation, jobs, events and testing. Use when writing or reviewing Laravel/PHP code. Complements the strict rules in rules/php_coding_rules.md, which take precedence.
---

# Laravel Conventions

Style guidance for Laravel work. The strict requirements live in
`config/claude/rules/php_coding_rules.md` and win on any conflict - this
document covers the conventions those rules do not spell out.

## Core Principle

Follow Laravel conventions first. If the framework has a documented or
idiomatic solution, use it unless there is a clear reason not to, and say what
that reason is.

## PHP Standards

- PSR-1, PSR-2, PSR-12
- `declare(strict_types=1);` in new files
- Typed properties over docblocks
- Always specify return types, including `void`
- Short nullable syntax: `?Type`, never `Type|null`
- Prefer `match` over `switch`
- Constructor property promotion where it fits
- One trait per `use` line

## Naming

| Thing | Convention | Example |
|---|---|---|
| Controllers | singular resource + `Controller` | `UserController` |
| Models | singular | `User` |
| Migrations | descriptive snake_case | `add_status_to_orders_table` |
| Tables | plural snake_case | `order_items` |
| Columns | snake_case, no model prefix | `created_at`, not `user_created_at` |
| Jobs | verb phrase | `SendInvoiceEmail` |
| Events | past tense | `OrderShipped` |
| Listeners | verb + `Listener` suffix optional | `SendShipmentNotification` |
| Actions | verb phrase | `CreateSubscription` |
| Form requests | action + `Request` | `StoreOrderRequest` |
| Policies | model + `Policy` | `OrderPolicy` |
| Config files | kebab-case | `mail-templates.php` |
| Config keys | snake_case | `default_from_address` |

## Class and File Structure

- Small, focused classes
- Avoid temporary variables used only once
- Early returns over nested conditionals
- Avoid `else` when an early return reads better
- Always use curly braces
- Handle error conditions first, happy path last
- Prefer several simple `if` statements over one compound condition
- Ternaries on a single line only when very short; otherwise one branch per line

## Enums

- Use an Enum whenever a domain concept has finite values
- Enums live in `app/Enums`
- Back them with strings, not ints, unless there is a storage reason
- Use the Enum in migrations (defaults), model casts, Blade, tests, routes,
  config and seeders
- Never hardcode an enum-backed string when the Enum exists

```php
enum OrderStatus: string
{
    case Pending = 'pending';
    case Shipped = 'shipped';
    case Cancelled = 'cancelled';

    public function isTerminal(): bool
    {
        return in_array($this, [self::Shipped, self::Cancelled], true);
    }
}
```

## Controllers

- Thin. Business logic belongs in Actions or Services.
- Service used once, inject into the method; used repeatedly, inject via the
  constructor
- Single-action controllers use `__invoke()`
- REST controllers use `Route::resource()->only([...])` - never register verbs
  the controller does not implement
- Do not create a controller that only returns a view; use `Route::view()`
- Return Resources, never raw arrays

## Routing

- URLs kebab-case: `/error-occurrences`
- Route names camelCase: `errorOccurrences.index`
- Route parameters camelCase: `{userId}`
- Tuple notation: `[UserController::class, 'store']`
- Avoid deep nesting; two levels is usually the limit

## Configuration

- `config()` everywhere; `env()` only inside `config/`
- Third-party service credentials go in `config/services.php`
- No magic strings or numbers - a constant, an Enum or a config key

## Eloquent and the Database

- Avoid N+1; reach for `with()` and `load()` deliberately, not reflexively
- Wrap multi-step writes in `DB::transaction()`
- Reusable constraints become query scopes
- Do not use `::query()` when calling `create()`
- Query explicit columns rather than `whereKey()`
- Register observers with attributes:

```php
#[ObservedBy([UserObserver::class])]
class User extends Model
{
    //
}
```

- Casts belong in the `casts()` method, not the `$casts` property
- Prefer `$fillable` over `$guarded = []` so mass assignment stays explicit
- Custom collections and builders when a model accumulates query helpers

## Migrations

- One concern per migration
- Always write a working `down()` unless the migration is genuinely
  irreversible, and say so if it is
- Name foreign keys explicitly on large tables
- Add an index with the column that needs it, in the same migration

## Validation

- Every HTTP endpoint validates through a FormRequest
- Array rules, not pipe strings: `['required', 'string', 'max:255']`
- Authorisation goes in the Policy, not the FormRequest's `authorize()`, unless
  it is a trivial ownership check
- Custom rules become Rule objects once they are used twice

## Actions and Services

- An Action does one thing and exposes one public method - `handle()` or
  `__invoke()`
- Actions return domain objects or DTOs, not HTTP responses
- Services coordinate; Actions execute
- Do not mutate arguments you were passed

## Jobs, Events and Queues

- Jobs are serialisable - pass IDs and models, never closures or large payloads
- Set `$tries` and `$backoff` explicitly on anything touching an external
  service
- Use `ShouldBeUnique` where duplicate dispatch is possible
- Events are past tense and carry data, not behaviour
- Prefer queued listeners over queued events

## Authorisation

- Policies or Gates, never inline checks in a controller
- Register policies with the `#[UsePolicy]` attribute or rely on convention
- `authorize()` in the controller, or `Gate::authorize()` in the Action for
  non-HTTP entry points

## Error Handling

- No blanket `try`/`catch`
- Catch only to add domain context, convert to a domain exception, or recover
- Never swallow an exception
- Let Laravel's handler deal with anything you cannot meaningfully recover from

## Blade

- Components over includes
- `@class` and `@style` directives over string concatenation
- Keep logic out of templates; compute in the controller, Action or view model
- Escape by default; `{!! !!}` needs a comment explaining why it is safe

## Testing

- Pest, feature tests first
- Factories for all model setup - no hand-built arrays
- Do not test private methods; test the behaviour that exercises them
- A test that proves a guard exists must prove the guarded action did not
  happen, not merely that a status code came back
- `Http::fake()` every URL a code path can reach - an unfaked URL is attempted
  for real

## Never Commit

`dd()`, `dump()`, `ray()`, `var_dump()`, `print_r()`. Structured `Log::*` with
context instead, and never log sensitive data.
