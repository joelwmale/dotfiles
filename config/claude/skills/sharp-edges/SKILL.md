---
name: sharp-edges
description: Review an API, config schema, settings screen, helper or class interface for footguns - designs where the easy path is the insecure or destructive one. Probes zero, empty, null and negative values, dangerous defaults, silent failures, type confusion and stringly-typed security. Use when designing or reviewing a config option, an artisan command's flags, a settings form, a service's public methods, a feature flag, or anything that exposes a risky choice. Not for finding implementation bugs.
---

# Sharp Edges

Does the interface resist misuse? The aim is a **pit of success**: the secure and safe usage
is the path of least resistance. If a developer, an admin or a future agent must remember a
special rule to avoid damage, the design has failed - not the person.

This is a design lens, not a bug hunt. Type juggling, weak randomness and the like are in
`laravel-pen-test-audit`; use `differential-review` for a diff.

## Rationalisations to reject

| You think | Reality | Do |
|---|---|---|
| "It's documented" | Nobody reads docs under deadline | Make the safe choice the default or only choice |
| "Admins need flexibility" | Flexibility is where footguns live | Offer a safe high-level option and hide the primitive |
| "Nobody would set that" | Someone will, or a migration will | Validate and reject it |
| "It's just a config value" | Config ships to production | Validate config; reject dangerous combinations |
| "We need backwards compatibility" | An insecure default cannot be grandfathered | Deprecate loudly and migrate |

## The categories

### 1. Zero, empty, null and negative

The most productive probe. For every number, string and list an interface accepts, ask what
`0`, `-1`, `""`, `null` and `[]` mean.

- `consignor_hold_days = 0`: does "no hold" mean never release, or release everything now?
  (An expiry command that refuses anything under 1 does so for exactly this reason.)
- `max_attempts = 0` or `timeout = 0`: unlimited, or disabled?
- `rate_limit = 0`: blocks everyone, or switches the limiter off?
- A commission or cut percent that is negative, over 100, or `null`: free, or a credit?
- An empty allowlist: allows nothing, or everything? An empty `$fillable`, empty roles
  array, empty `only()`?
- A secret that is `null` because the env var is unset: does verification skip, or fail
  closed? (A webhook handler that skips the signature when the secret is empty is a public
  endpoint.)

Fix: validate at the boundary (a `min:1` rule, an Enum, a constructor that throws), and make
the unsafe meaning impossible to express.

### 2. Dangerous defaults

A default that is insecure, or a parameter whose default can quietly disable protection.

- A disk default that resolves to a public disk when the env var is missing
- `bool $verify = false`, `$sendNotifications = true` on a bulk command
- A destructive command that acts unless told `--dry-run`. The safe shape is the reverse:
  report by default, act only with `--force`.
- A constructor with a sensible default that accepts any bad value from a caller

### 3. Primitive obsession in security

Raw strings and ints for distinct concepts invite swaps and injection.

- Roles, scopes and statuses as free strings instead of Enums
- A user id, an organisation id and an order id all `int`, passed in the wrong order with no
  type error
- A permission list built by string concatenation
- A cents amount and a dollars amount both `float`

Fix: Enums, value objects, and named arguments at call sites that take several of the same type.

### 4. Silent failures

- A method that returns `false` or `null` on a security failure where the caller can forget
  to check, instead of throwing
- An empty `catch`, or a catch that substitutes a default, around an authorisation, payment or
  verification step
- A verification that "passes" on malformed input
- `Http` responses used without `throw()` (4xx and 5xx do not throw)
- `updateOrCreate`/`firstOrCreate` on a column with no unique index, which silently creates
  duplicates under concurrency

### 5. Configuration cliffs

One wrong value, no warning, catastrophic result.

- Booleans that turn a protection off entirely (`APP_DEBUG`, `verify_ssl`, trusted proxies `*`)
- Typos accepted silently: `'fasle'` is truthy
- Dangerous combinations accepted: auth required, plus a bypass for a health-check path that
  is `/`
- Env vars that override security settings
- A feature flag that grants access when the flag store is down or the row is missing

### 6. Easy path versus safe path

Compare the first example someone would copy with the safe one. If the first `Storage::put`,
`Model::create($request->all())`, `DB::raw`, `Http::post` or `dispatch` in the codebase is the
unsafe form, new code will copy it.

## Three people to design against

1. **The scoundrel**: controls an input or a config value. Can they disable a protection,
   downgrade a mode, or inject a value?
2. **The lazy developer** (or agent): copies the nearest example, skips the docs. Is the first
   thing they find safe?
3. **The confused one**: misunderstands the interface. Can they swap two arguments, pass the
   wrong id, or use the wrong mode, with no error?

## Process

1. **Surface**: list the security- or damage-relevant choice points - settings, flags,
   command options, public methods of a service, config keys.
2. **Probe** each one with the zero/empty/null/negative questions and the categories above.
3. **Model** the three people.
4. **Validate** each finding by writing the minimal misuse. Does it actually cause harm? If a
   finding does not survive that, drop it.

## Severity

| Level | When |
|---|---|
| Critical | The default or the obvious usage is insecure or destructive |
| High | An easy misconfiguration breaks security or deletes data |
| Medium | An unusual but possible value has an unexpected meaning |
| Low | Needs deliberate misuse |

## Before you finish

- [ ] Probed zero, empty, null, negative and over-range for every numeric and string input
- [ ] Checked each default is the safe one, and a missing value fails closed
- [ ] Looked for swappable arguments and free-string security values
- [ ] Looked at error paths: does failure bypass the check?
- [ ] Each finding has a concrete misuse, not a general worry

Source: adapted from Trail of Bits' `sharp-edges` skill, licensed CC BY-SA 4.0,
https://github.com/trailofbits/skills. This adaptation is shared under the same licence.
