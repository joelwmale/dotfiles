# PHP / Laravel Coding Rules (Strict)

These rules override generic programming advice and must be followed unless explicitly instructed otherwise.

---

## Core Principle

Follow **Laravel conventions first**.  
If Laravel has a documented or idiomatic way to do something, use it.

---

## Architecture & Structure

- Thin controllers, no business logic
- Domain logic lives in Actions / Services
- Organize code by feature or domain
- Prefer small, focused classes and methods
- Avoid deep nesting (>4 levels)

---

## Immutability (Preferred, Not Absolute)

- Prefer immutability for:
  - DTOs
  - Value objects
  - Arrays passed between services
- Do not silently mutate input arguments
- **Eloquent models may be mutated** inside:
  - Transactions
  - Dedicated Actions or Services
- Mutations must be explicit and localized

---

## Validation

- ALL external input must be validated
- Use `FormRequest` for HTTP endpoints
- Never trust raw `$request->input()`
- Internal validation via DTO constructors or validators when needed

---

## Error Handling

- Do NOT blanket `try/catch`
- Let Laravel handle unhandled exceptions
- Catch only to:
  - Add domain context
  - Convert to domain exceptions
  - Recover safely
- Never swallow exceptions

---

## Database & Eloquent

- Use `DB::transaction()` for multi-step writes
- Avoid N+1 queries
- Use `with()` / `load()` deliberately
- Prefer query scopes for reusable constraints

---

## HTTP & APIs

- Controllers return Resources (`JsonResource`)
- Never return raw arrays from controllers
- Use proper HTTP status codes

---

## Authorization

- Use Policies or Gates
- Never inline authorization logic in controllers

---

## Debugging & Logging

The following must NEVER exist in committed code:
- `dd()`
- `dump()`
- `ray()`
- `var_dump()`
- `print_r()`

Use `Log::*` with structured context only.  
Never log sensitive data.

---

## Constants & Configuration

- No magic strings or numbers
- Prefer enums, constants, or config values
- Use `config()` — never `env()` outside config files

---

## Types & Quality

- Use `declare(strict_types=1);` in new files
- Prefer typed properties and return types
- Use early returns over `else`
- Always use curly braces
- Code should pass PHPStan/Psalm (≈ level 6 quality)

---

## Testing

- Use Pest or PHPUnit
- Prefer feature tests
- Use factories
- Do not test private methods

---

## Completion Checklist

Before marking work complete:
- Laravel conventions followed
- Controllers thin
- All input validated
- Errors handled appropriately
- No debug artefacts
- No magic values
- Clear naming and intent
