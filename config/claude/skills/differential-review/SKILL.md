---
name: differential-review
description: Security-focused review of a diff, PR, commit range or release (for example develop into master) in a Laravel app. Triages by risk not size, checks git history for removed guards and regressions, counts callers for blast radius, checks whether changed code is tested, and models the attacker for high-risk changes. Use before merging or releasing, when asked "what could this break", or to check a change has not reintroduced a fixed bug. For a whole-app audit use laravel-pen-test-audit; for standards and spec review use review-branch.
---

# Differential Security Review

A review of what **changed**, against the baseline it changed from. The question is not
"is this code secure" but "did this change weaken something that was secure, or open
something new". Small diffs hide the worst changes: a deleted `authorize()` is one line.

## Principles

1. **Risk first.** Classify by what the code touches, not how many lines changed.
2. **Evidence.** Every finding cites a file, a line, a commit and a concrete attack.
3. **Adapt to size.** Under 20 files, read everything and its direct dependencies. 20 to
   200, focus on high-risk files and one hop of callers. Over 200 (a release), go surgical:
   high-risk paths only, split across focused sub-agents per `agent_recovery.md`.
4. **Honest.** State what you did not cover and how confident you are. Never claim a full
   review of a partial one.
5. **Written down.** A finding said aloud and not recorded is lost. Write the report to a
   file in the scratchpad (not the repo) and summarise it in chat.

## Rationalisations to reject

| You think | Reality | Do |
|---|---|---|
| "Small PR, quick look" | Heartbleed was two lines | Classify by risk, not size |
| "Just a refactor" | Refactors break invariants | Treat as high until shown low |
| "I know this code" | Familiarity breeds blind spots | Build the baseline explicitly |
| "Git history takes too long" | History shows regressions | Never skip phase 1 |
| "The blast radius is obvious" | You miss indirect callers | Count them |
| "No tests, not my problem" | Untested changed code is higher risk | Flag it and raise the severity |

## Process

### 0. Baseline and triage

```bash
git log <base>..<head> --oneline
git diff <base>...<head> --stat
git diff <base>...<head> --name-only
```

For a release, review a **merged tree**, not the two branches: create a throwaway worktree,
merge the head into the base, and run `bin/check` there. A merge that is clean can still
break behaviour. Copy `public/build` in (or build it) or browser tests fail for reasons that
are not yours.

Risk per file:

- **High**: authentication, authorisation (policies, gates, middleware), money (checkout,
  payouts, refunds, commission), webhooks, file uploads and private storage, anything that
  takes a user-supplied path, URL or identifier, outbound HTTP, mass assignment, raw SQL,
  `{!! !!}`, queued jobs that act on user data, migrations that rewrite populated tables,
  removal of any validation.
- **Medium**: business logic, state transitions, new public routes or Livewire actions,
  new commands that change data.
- **Low**: copy, markup, styling, tests, logging.

### 1. Read each change against its baseline

For every high and medium file, read both versions. For each hunk write: before, after,
behavioural change, security consequence.

**Look at what was removed.** For each removed guard (`authorize`, `Gate::`, `can`,
`middleware`, `abort_if`, a `validated()` call, a rate limiter, a signature check, a
`whereNull`/ownership condition, a `$fillable` entry):

```bash
git log -S"<removed code>" --oneline --all
git blame <base> -- <file>
```

- Removed by or after a commit whose message says fix, security, CVE, or a pen-test item:
  **critical**. Someone closed a hole on purpose.
- Added then removed within a month: **high**.
- Previously removed, now re-added: a **regression**. Check `git log -S"<added code>" -p`.

Ask of every changed check: what attack did the old code stop, who can now call this, is the
check moved elsewhere or just gone, is the new check weaker (loose `==`, null passes).

[patterns.md](patterns.md) lists the Laravel changes worth a grep.

### 2. Is the changed code tested?

For each changed function or action, find the test that exercises it. A new public action
with no test, or changed validation with unchanged tests, **raises the risk by one level**.
A test that stayed green while the guard changed does not cover the guard; the guarded
action must be proven not to happen (see `writing-tests`).

### 3. Blast radius

Count callers of each changed high-risk function (`grep -rn "functionName(" app routes
resources`, plus Livewire views, jobs, commands and the scheduler). 1 to 5 callers is low,
6 to 20 medium, 21 to 50 high, over 50 critical. High risk with a high blast radius gets
the deepest analysis.

### 4. Context on the high-risk changes

For each, map the whole flow: entry conditions, state read and written, external calls,
what a caller can trigger, what happens on each failure path, and the invariants that must
hold (a payout is paid once, a buyer sees only their orders, a signed URL is not authority).
List assumptions the code makes that nothing enforces. "Nothing found that makes this true"
is the most useful sentence in the report.

### 5. Model the attacker (high risk only)

For each high-risk change, name the attacker (anonymous visitor, logged-in buyer, seller,
organisation member without the role, admin of another tenant, a third party sending a
webhook), what they want, and the exact steps:

```
SCENARIO:      <goal>
PRECONDITIONS: <state and role needed>
STEPS:         1. ...  2. ...  3. ...
WHY IT WORKS:  <the line or removed line that allows it>
IMPACT:        <data, money or access, and how many people>
EXPLOITABILITY: trivial | needs a specific state | needs an insider
```

Scenarios must be concrete. "An attacker could bypass authorisation" is not a finding.
Verify the exploit against the real code before ranking it; delegate this to a sub-agent only
with the files and the diff slice in the prompt.

### 6. Report

Write to the scratchpad, not the repo: summary and verdict; scope and what was **not**
covered; findings by severity with file, line, commit, scenario and a suggested fix;
test-coverage gaps; regressions found; open questions. Start with the release decision:
safe to ship, ship after these fixes, or do not ship. Then give the short version in chat.

## Red flags that go straight to phase 5

- Code removed by a security, fix or CVE commit
- A policy, gate, middleware or `authorize()` removed or relaxed
- Validation removed without a replacement
- A new external call or file read built from user input
- A high-risk change with 50 or more callers

## Not for

Greenfield code with no baseline, documentation-only changes, formatting. Use `review-branch`
for standards and spec, and `laravel-pen-test-audit` to audit a whole app.

Source: adapted from Trail of Bits' `differential-review` skill, licensed CC BY-SA 4.0,
https://github.com/trailofbits/skills. This adaptation (Laravel patterns, release-review
workflow) is shared under the same licence.
