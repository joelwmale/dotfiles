---
name: laravel-conventions
description: Laravel and PHP conventions - naming, structure, Eloquent, routing, validation, jobs, testing, and a security section covering private file storage, signed URLs, authorisation, webhooks, auth flows, mass assignment and exports. Use when writing or reviewing Laravel/PHP code. Complements the strict rules in rules/php_coding_rules.md, which take precedence.
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

## Security

These are the failure modes that recur in our penetration-test findings. They
are cheap to get right while writing the code and expensive to retrofit.

### Private files

**Default the filesystem disk to a private one, and fail closed.** A missing
`FILESYSTEM_DISK` must not silently resolve to a web-served disk. Ship the safe
value in `.env.example` too - a newly provisioned environment inherits whatever
that file says.

- Anything regulated, personal, financial or identity-related goes on a private
  disk. Never `public/`, never a `storage` symlink.
- **Never derive a storage path from a predictable value.** A hash of an
  auto-increment ID is not a secret - the whole keyspace is precomputable in
  seconds. Use `Str::random()` persisted against the record.
- Validate uploads on the server: MIME type, extension, size, and a per-user
  ceiling on total temporary storage. Store under a generated name, never the
  client's filename.
- Clean up. Temporary uploads, draft images and generated export files need a
  lifecycle, not indefinite residency.

**A signed URL is not authorisation.** It proves the link was minted by the
app; it says nothing about who is holding it. Every signed endpoint must still
check that *this* principal may read *this* resource.

```php
// DANGEROUS - "some session exists" is not an ownership check,
// and the path comes from unvalidated input
$user = auth('web')->user();
abort_if(! $user, 403);

return $this->streamDocument(path: $request->all()['path']);
```

- Never accept a caller-supplied storage path. Resolve the path from a record
  you looked up and authorised.
- Keep expiries short. Signed URLs leak through `Referer` headers, logs,
  forwarded email and analytics payloads.
- **Never send a signed URL to a third party.** Marketing and analytics
  platforms retain event payloads indefinitely, so a "24-hour" link becomes a
  permanent unauthenticated URL held by a vendor.

### Authorisation

- Policies and Gates, always. Hand-rolled checks scattered through controllers
  and components are how coverage gaps happen.
- **Scope through the relationship.** `Model::find($id)` with client input is
  unscoped by definition; `$parent->children()->findOrFail($id)` is not.
- **Guards must fail closed on null.** `$row->user_id !== auth()->id()` passes
  when both sides are null - and rows written by jobs, commands, webhooks and
  services have null ownership columns. Reject an absent identity explicitly.
- Compare identities with `===` against a value you have asserted is non-null.
  A loose `==` comparison against a missing secret or ID fails open.
- **Bulk actions authorise per item**, not once for the request.
- Authorise every programmatic surface - API endpoints, MCP tools, webhook
  handlers, console commands - not just the screens.

### Webhooks

Treat every inbound webhook as hostile until verified.

- Verify an HMAC over the **raw body**, using `hash_equals`
- **Fail closed when the secret is missing.** A handler that skips verification
  because the config is unset is an unauthenticated endpoint.
- Protect against replay: check timestamps and record processed event IDs
- Validate the payload as strictly as any user input - webhook content is a
  common stored-XSS vector into admin panels
- Never let a webhook mark payment, fulfilment or entitlement state without
  verification

### Authentication flows

- **Never authenticate a user on evidence the client supplied.** Looking up an
  account by a posted email address and logging it in is account takeover,
  however the flow is framed - invitation, guest checkout, subscribe link.
- Invitations use a signed, single-use, expiring token delivered out of band
- **Never store or transmit a plaintext password.** Not in the database, not in
  a log, not to a marketing platform.
- Hash reset tokens, expire them, and invalidate on use
- `session()->regenerate()` on login, password reset and privilege change;
  `session()->invalidate()` on logout
- Rate limit every authentication surface: login, registration, forgot
  password, verification codes, 2FA attempts. **Including the Livewire ones** -
  route middleware does not cover component actions.
- Avoid enumeration: identical responses and comparable timing for known and
  unknown accounts. A flow that returns a different next step for an existing
  account is an oracle.
- Generate codes and tokens with a CSPRNG - `random_int()`, `Str::random()`.
  Never `rand()`, `mt_rand()` or `uniqid()`.
- Encrypt TOTP secrets and recovery codes at rest, keep them out of search
  indexes, and require re-authentication to view or disable 2FA
- Enforce 2FA consistently in every environment. A staging carve-out becomes a
  production carve-out.
- Scope API tokens with explicit abilities and a real expiry

### Mass assignment

- **Never `Model::unguard()` globally.** It removes protection from every model
  at once.
- `$fillable` over `$guarded = []`, especially on `User` and any model carrying
  a role, permission, balance, status or price

### Output and exports

- Escape by default. `{!! !!}` and `x-html` need a comment justifying why the
  content is trusted.
- Admin panels are not a trust boundary - attacker content reaches them through
  webhooks, addresses, business names and support messages
- **Prefix CSV cells starting with `=`, `+`, `-` or `@`** to prevent spreadsheet
  formula injection in exports
- Escape LIKE wildcards consistently on user-supplied search terms

### Outbound requests

- Validate and allowlist any URL the application fetches
- **Re-validate after redirects.** A guard applied only to the initial URL is
  defeated by a redirect to an internal address; disable redirect following or
  check every hop.

### Configuration and secrets

- Never commit real data. Keep `storage/`, import directories and dumps
  gitignored - **a secret in git history cannot be rotated away, and personal
  data in history is a disclosure that has already happened.**
- Enable secret-scanning push protection
- Configure trusted proxies. Without it, client IP comes from a spoofable
  header, and every rate limit and audit log keyed on it is fiction.
- Force the session cookie `Secure` flag rather than deriving it from an
  environment variable that may be unset
- State-changing operations are never `GET`
- Set security response headers and a Content-Security-Policy
- Pin third-party scripts to a version with Subresource Integrity
- Keep development tooling out of production requirements

### Concurrency

Financial operations need a lock or a database constraint, not a read-then-write
check. Concurrent refunds, redemptions and stock allocations will exceed their
limits under load if the guard is a `SELECT` followed by an `UPDATE`.

### CI

A test suite that does not run on pull requests is documentation. Require it as
a status check, protect the default branches, and run `composer audit` and
`npm audit` in the same workflow.

## Never Commit

`dd()`, `dump()`, `ray()`, `var_dump()`, `print_r()`. Structured `Log::*` with
context instead, and never log sensitive data.
