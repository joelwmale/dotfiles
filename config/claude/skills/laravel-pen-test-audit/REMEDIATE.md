# Phase 48 - Security Regression Tests

Every confirmed vulnerability gets a regression test, written before the fix per `rules/testing_policy.md` (Tier 1).

Examples:

```php
it('rejects cross tenant access', function () {
    //
});

it('prevents subscribing to another users private channel', function () {
    //
});

it('throttles verification code attempts', function () {
    //
});

it('rejects executable uploads', function () {
    //
});

it('prevents reuse of password reset tokens', function () {
    //
});

it('prevents ordinary users viewing horizon', function () {
    //
});
```

Each security test proves the malicious operation did not happen (unchanged row, call count, `Http::assertNotSent`), not just a status code.

Confirm it by removing the guard, watching the test fail, then restoring it.

---

# Phase 49 - Verification

Run the project's actual quality gates.

Typical Laravel stack:

```bash
composer audit --locked
npm audit
vendor/bin/pint --test
vendor/bin/phpstan analyse
php artisan test
npm test
npm run type-check
npm run build
```

Do not assume these exact commands exist.

Inspect:

```text
composer.json scripts
package.json scripts
CI configuration
```

and use project-native commands.

---

---

# Remediation Workflow

Unless explicitly running in report-only mode:

```text
DISCOVER
    ↓
UNDERSTAND
    ↓
REPRODUCE
    ↓
ASSESS IMPACT
    ↓
WRITE FAILING REGRESSION TEST
    ↓
FIX
    ↓
REPEAT ATTACK
    ↓
VERIFY FAILURE
    ↓
RUN FULL TEST SUITE
```

Avoid unrelated refactoring.

Security fixes should be small, understandable and reviewable.

---
