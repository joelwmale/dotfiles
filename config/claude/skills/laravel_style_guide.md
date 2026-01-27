# Laravel Style Guide (Skill)

This skill provides Laravel- and PHP-specific coding guidance.
It is applied when writing Laravel code.
Strict rules take precedence over this guide.

---

## Core Principle

Follow Laravel conventions first.
If Laravel provides a documented or idiomatic solution, use it unless there is a clear reason not to.

---

## PHP Standards

- Follow PSR-1, PSR-2, and PSR-12
- Use `declare(strict_types=1);` in new files
- Prefer typed properties over docblocks
- Always specify return types, including `void`
- Use short nullable syntax: `?Type` instead of `Type|null`
- Prefer `match` over `switch`

---

## Class & File Structure

- Prefer small, focused classes
- Use constructor property promotion when possible
- One trait per line
- Avoid temporary variables used only once
- Prefer early returns over nested conditionals
- Avoid `else` when an early return is clearer
- Always use curly braces

---

## Control Flow

- Handle error conditions first, happy path last
- Prefer multiple simple `if` statements over compound conditions
- Ternaries:
  - Single-line only if very short
  - Otherwise, each branch on its own line

---

## Enums

- Always use Enums when a domain concept has finite values
- Enums live in `app/Enums`
- Use Enum values in:
  - Migrations (defaults)
  - Models (casts)
  - Blade templates
  - Tests
  - Routes, configs, seeds
- Never hardcode enum-backed strings when an Enum exists

---

## Laravel Conventions

### Controllers

- Thin controllers only
- Business logic belongs in Services / Actions
- If a Service is used:
  - Once → inject into the method
  - Multiple times → inject via constructor
- Single-action controllers should use `__invoke()`
- REST controllers should use `Route::resource()->only([...])`
- Do not create controllers that only return `view()`
  - Use `Route::view()` instead

---

### Routing

- URLs: kebab-case (`/error-occurrences`)
- Route names: camelCase
- Route params: camelCase (`{userId}`)
- Prefer tuple notation: `[Controller::class, 'method']`
- Avoid deep nesting

---

### Configuration

- Config files: kebab-case
- Config keys: snake_case
- Use `config()` helper
- Never use `env()` outside config files
- Add service config to `config/services.php`

---

### Eloquent & Database

- Avoid N+1 queries
- Use `with()` / `load()` intentionally
- Use transactions for multi-step writes
- Don’t use `::query()` when calling `create()`
- Don’t use `whereKey()` — query explicit columns
- Register Observers using PHP Attributes:
  ```php
  #[ObservedBy([UserObserver::class])]
