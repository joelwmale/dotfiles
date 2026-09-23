---
name: fix-failing-tests
description: Use when the user says "tests are failing", "CI is failing", "fix the tests", "tests broke", "build is red", or asks why tests aren't passing. Checks GitHub Actions for test failures, reads logs, and works through fixes systematically.
---

# Fix Failing Tests

## Overview

Diagnose and fix test failures by reading GitHub Actions logs first, then reasoning about causes before touching code.

## Phase 1: Check GitHub Actions

```bash
# Are Actions configured?
ls .github/workflows/

# What's the current state?
gh run list --limit 10 --json status,conclusion,name,headBranch,workflowName,createdAt
```

If no `.github/workflows/` directory exists, stop and ask the user if they want one created.

If runs exist, identify the most recent failing run on the current branch.

## Phase 2: Get Failure Details

```bash
# Get the failing run ID and its jobs
gh run view <run-id> --json jobs,name,conclusion,status

# For each failing job, get its logs
gh run view <run-id> --log-failed
```

Read the full log output. Look for:

- The **actual error** (not just the step name that failed)
- **Line numbers** and file paths in stack traces
- **Assertion failures** - what was expected vs what got returned
- **Setup failures** - env vars missing, services not starting, migrations failing
- **Dependency issues** - package install errors, version conflicts

## Phase 3: Classify the Failure

| Failure Type        | Symptoms                                 | Action                                |
| ------------------- | ---------------------------------------- | ------------------------------------- |
| Test logic error    | Assertion mismatch, wrong expected value | Fix the test or implementation        |
| Environment issue   | Missing env var, service timeout         | Check workflow config / fixtures      |
| Dependency failure  | npm/composer install errors              | Check lockfile or version constraints |
| Schema drift        | Migration failures, column not found     | Run / write missing migrations        |
| Flaky test          | Passes locally, fails randomly in CI     | Add retry logic or fix race condition |
| Code broke the test | Recent commit changed behavior           | Fix implementation to match spec      |

## Phase 4: Reproduce Locally

Before changing code, confirm the failure is reproducible:

```bash
# PHP / Pest
php artisan test --filter="TestClassName"

# Node / Vitest
npx vitest run path/to/test

# Node / Jest
npx jest --testPathPattern="test-name"
```

If it fails locally, read the stack trace carefully — it usually points directly to the broken line.

## Phase 5: Fix Systematically

**One failure at a time.** Fix the first failing test, run the suite, then move to the next.

Before writing a fix:

1. Read the test to understand **what it asserts**
2. Read the implementation to understand **what it does**
3. Determine which one is wrong - the test or the code
4. If the test is outdated, update it. If the code is wrong, fix the code.

After each fix:

```bash
# Run only the file you touched
php artisan test --filter="TestClass"
npx vitest run path/to/specific.test.ts
```

Run the full suite only once all targeted tests pass.

## Phase 6: Verify in CI

After pushing the fix:

```bash
# Watch the run
gh run watch

# Or check status after a minute
gh run list --limit 3 --json status,conclusion,name,headBranch
```

If CI still fails after your fix, go back to Phase 2 - there may be a second failure hidden behind the first.

## Common Pitfalls

- **Don't fix the test to make it pass if the code is wrong.** A test that describes broken behavior isn't a test.
- **Don't delete tests.** If a test no longer applies, understand why before removing it.
- **Don't assume local = CI.** CI often has a clean environment; local may have leftover state.
- **Environment-only failures:** If tests pass locally but fail in CI only, check the workflow for missing env vars or services (database, redis, etc.) that the test depends on.
