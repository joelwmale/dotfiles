---
name: creating-clickup-tickets
description: Use when creating a ClickUp ticket to document completed or planned work. Triggers on "make a ticket", "make a CU ticket", "log this in ClickUp", "create a ClickUp task", or after finishing a technical task/fix/infra change that needs a ticket.
---

# Creating ClickUp Tickets

Write for a product owner or non-technical project manager, not a future engineer.
The commit message and code already hold the technical detail — the ticket doesn't
need to repeat it. A reader with zero codebase context should understand what
changed and why it matters within one skim.

## Workflow

1. Identify what actually changed and why it matters, from the recent
   conversation, diff, or commits — not just the literal code edit.
2. Find the right workspace/list: search ClickUp for an existing ticket sharing
   this project's ticket prefix (e.g. `clickup_search` for "PX-" or whatever
   prefix recent commits use) and reuse its `list_id`/`workspace_id`. Ask the
   user if none is found — never guess a list.
3. Translate to plain language using the checklist below.
4. Create the task.
5. Report back the ticket number/title/link. If the user is about to commit,
   offer the ticket number for the commit message prefix.

## Translation Checklist

| Strip                                     | Keep                                                                                      |
| ----------------------------------------- | ----------------------------------------------------------------------------------------- |
| File paths, function/class/variable names | What capability or behavior changed                                                       |
| Code blocks, config, YAML, env vars       | What the user or business now experiences differently                                     |
| Conditionals/logic ("if X then Y")        | Why it matters: security, reliability, speed, cost, risk, compliance, customer experience |
| Library/package/tool names, commit SHAs   | Plain outcome language a stakeholder already uses                                         |
| Error messages, stack traces              | —                                                                                         |

If a term is something the user themselves used in plain speech (e.g. "GitHub
releases"), it's fine to keep — the bar is "would a non-technical stakeholder
already know this word," not "is this word ever technical."

## Title Formula

`<Action>` + `<outcome>`, one line, no jargon.

- Bad: "Gate production deploys behind published GitHub Releases instead of master pushes"
- Good: "Move code releases to work off of GitHub releases for better security and stability"

## Description Formula

1–4 short sentences. What changed, why it matters, nothing else. No code, no
step-by-step technical mechanics.

<Bad>
Previously, `deploy-production` in `.github/workflows/tests.yml` fired on every
successful `Tests` run for a push to `master`. Changed to only deploy off a
published GitHub Release (`release: types: [published]` trigger,
`deploy-production` now conditions on `github.event_name == 'release'`
instead of `github.ref == 'refs/heads/master'`)...
</Bad>

<Good>
Production deployments now only happen when we publish an official release,
instead of automatically on every code change pushed to the main branch. This
adds a deliberate checkpoint before anything reaches customers, reducing the
risk of an unintended change going live and making it easier to know exactly
what shipped when.
</Good>

## When to Break This

If the user explicitly asks for technical detail in the ticket (e.g. "include
the code" or "make it detailed for the dev team"), include it. Non-technical is
the default, not a hard rule.
