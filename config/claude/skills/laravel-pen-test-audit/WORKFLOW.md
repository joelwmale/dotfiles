# Audit Workflow

The procedure for a run. `SKILL.md` gives the rules; this file says what to do and in what order.

Hunting and verifying are separate jobs done by separate readers. The agent that finds a problem
is the worst placed to judge it, so every candidate is attacked by someone who did not write it.

---

## 1. Recon (you, the parent)

Read `phases/1-recon.md` and do Phase 0-2. Write `security-reports/work/architecture.md` (under
~800 words): stack and versions, roles and tenants, entry surfaces, where untrusted data lands, what
the live URLs are, what you could not see (production env, proxy config).

Build the **unit list**. A unit is one slice file crossed with one entry surface, for example
"phases/3 x Livewire components under app/Livewire/Supplier". Write it to
`security-reports/work/units.md` as a table: unit, files in scope, status. Statuses are `planned`,
`covered`, `candidate`, `deferred`, `blocked`. Never drop a unit silently; an unassigned unit is
`deferred` with a reason.

## 2. Hunt

One hunter per slice file in `phases/2` to `phases/7`, each scoped to specific directories. Prefer
running them as read-only subagents in the background (see `rules/agent_recovery.md`: small
scopes, paths in the prompt, `Monitor`, timeouts). Hunters only read and probe; they never edit
code. If subagents are unavailable, do the slices yourself one at a time and still keep the refute
step separate (section 3).

Give each hunter:

- its slice file path and the architecture note path
- the directories it owns and what to ignore
- the **Hunter brief** below, verbatim
- an output file: `security-reports/work/candidates-<slice>.md`

### Hunter brief

> You are looking for boundary failures, not style problems. For each thing you suspect, follow the
> input from where it enters (route, Livewire argument, request field, webhook, queue payload)
> through parsing, identity, authorisation, normalisation, state, derived copies and the final sink.
>
> Rules:
>
> - Build every inventory your slice file demands (tables with a verdict per row). "Reviewed" with
>   no table means you did not do it.
> - **Compare sibling controls for equivalence, not presence.** When one profile screen, role,
>   download route, signing site or limiter has a guard, open its siblings and check they have the
>   same one. Copies drift; the bug is usually in the copy.
> - Compare canonicalisation at every handoff: case, `/` versus `\`, dot segments, encoding, string
>   versus int, request body versus query string.
> - Check the sad paths: absent, empty, negative, duplicate, stale, revoked, expired, concurrent.
> - Chains: if a finding needs a prerequisite (a stored-XSS write, a leaked id), confirm the
>   prerequisite exists. Do not assume a downstream effect.
> - A flag is not a finding. Trace the impact before reporting.
> - Return nothing rather than something speculative.
>
> Wildcards, do these last: read the weirdest, most copy-pasted or least-tested file in your scope;
> `git log -p -S` for removed or reverted security checks; list which methods and routes have no test
> that calls them as a lower-privileged user.

### Candidate record (what a hunter writes)

One block per candidate, all fields required:

```text
ID:            temp id, e.g. auth-3
Title:
Lower-trust principal:   who attacks (anonymous, pharmacy user, supplier, ...)
Entry:         route / Livewire method / field, with file:line
Trace:         entrypoint -> propagation -> sink, each hop with file:line
Intended control:   what should have stopped it
Strongest visible control on the path:   what is there and why it does not stop it
Boundary crossed:   what the attacker gets that they should not
Evidence:      command/output, test, or "code only"
Blockers:      facts you could not establish (live config, prod env)
```

Same root cause reached by several entry paths is **one** candidate with the strongest trace.

## 3. Refute (fresh reader per candidate)

For each candidate, a reader who did not write it tries to **disprove** it from source and bounded
local evidence. Use a fresh subagent per candidate or per small group of related ones; inline, switch
roles explicitly and re-read from scratch rather than from the hunter's summary.

### Refuter brief

> You did not write this candidate. Try to refute it. Re-read every cited line. Reconstruct the
> controls on the path: middleware, policies, scoped queries, validation, `#[Locked]`, casts,
> signature checks, rate limiters, framework behaviour. If you can run a safe test (a Pest test,
> `Livewire::test()`, a tinker call on a local database), do. Return one verdict:
>
> - `confirmed` - a boundary failure with a demonstrated or fully traced result
> - `needs_validation` - plausible, but a named fact is missing
> - `rejected` - a control stops it, or no boundary is crossed (give the control, file:line)

### Verdict gates

- **confirmed** needs a full trace, the strongest control accounted for, and either a reproduced
  result or code evidence so direct that no live fact could change it. A same-principal action
  (a user doing something to their own data) is not a boundary crossing.
- **needs_validation** must name the specific missing fact (for example "effective REDIS_URL scheme
  in production"). It is not a parking place for a speculative idea; if you cannot name the fact,
  it is `rejected`.
- **rejected** records the control that defeats it, so the next run does not re-raise it.
- **Defence-in-depth gaps are not vulnerabilities.** Missing CSP, Permissions-Policy, security.txt,
  an out-of-date but unaffected package, a version-floor constraint: these go in the **Hardening**
  section of the report with their own severity, never mixed into confirmed findings.
- **Severity needs demonstrated impact.** Only `confirmed` findings get a severity from
  `CHECKLIST.md`, and it cannot exceed what was demonstrated. A crash is not code execution.
- Do not inflate: a flaw whose result fully defeats a control is HIGH or above; one that only
  weakens a control is MEDIUM or below.

Where a fix is needed and not in report-only mode, go to `REMEDIATE.md` for each `confirmed` one.

## 4. Coverage critic (fresh reader, once per wave)

After the hunters and refuters, a fresh reader gets: `units.md`, the candidate files, the refuter
verdicts, and read access to the repo. It does **not** re-hunt. It answers, in a short list:

1. Which entry surfaces or components exist in the repo that appear in no unit (grep
   `app/Livewire`, `routes/`, `app/Http/Controllers`, `resources/views` for things nobody listed)?
2. For each inventory the slices required, is it complete? Count the rows against a fresh grep.
   A Livewire action table with 40 rows when the code has 90 public methods is a failure.
3. Which `deferred` or `blocked` units can now be done?
4. Anything the wildcard step should have caught.

The parent turns its answers into new units and runs one more hunt-and-refute pass on them. Stop
when the critic returns nothing new, or after two extra waves; say so in the report if you stopped
on the limit.

Never claim the run exhausted the target. State the units covered and the units deferred.

## 5. Report

Follow `REPORT.md`. Structure the findings as:

- **Confirmed** - with severity, ordered most severe first
- **Needs validation** - each with the single fact needed and who can supply it
- **Hardening** - defence-in-depth and hygiene items, with their own severity
- **Rejected** - one line each with the control, so reviewers see what was checked
- **Coverage** - units covered, deferred, blocked, and the live URLs checked or not checked

Finish with `CHECKLIST.md`; every answer needs evidence.

## If you are tight on context

Keep only `SKILL.md`, `WORKFLOW.md` and the slice you are working in loaded. Write results to the
`security-reports/work/` files and re-read them rather than carrying them in conversation. Do not
load `PDF.md` until the report is final.
