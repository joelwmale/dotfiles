---
name: pull-requests
description: Use when writing a pull request description or replying to review comments on one. Triggers on "make a PR", "open a pull request", "create a PR", "reply to the review", "respond to that comment", or after finishing work that's ready for review.
---

# Pull Requests

A PR is dev to dev. The reviewer is about to read the diff — the description
just tells them what changed and anything that would bite them. No essays.

Everything posted to a PR, description and replies alike, goes out under Joel's
name. Write as him: first person, plain, brief. Not a report, not a status
update from an assistant.

(Business-facing framing belongs in `creating-clickup-tickets`, not here.)

---

## Writing the description

```markdown
## Summary

- One line per thing that changed. Two if the why isn't obvious.

## Notes

- Only if there's something to say.
```

**Summary** — bullets, 1-3 lines each. One per change, grouped by what it does,
not commit by commit. Say the mechanism in a clause ("switched X to Y", "now
keyed by shipment") rather than explaining the feature from first principles.

**Notes** — only what affects merging or running the branch:

- migrations, especially destructive or needing a backfill
- pre-existing failures, so a red suite isn't read as this branch's fault
- known issues left in deliberately, and follow-ups worth a ticket
- anything needing a config or env change to work

Drop the section entirely when there's nothing. Don't pad it.

**No Test plan section**, even if a template suggests one. If verification is
worth mentioning, it's one line in Notes.

### Keep / Drop

| Keep                                          | Drop                                 |
| --------------------------------------------- | ------------------------------------ |
| Component names (checkout page, billing job)  | Line-by-line narration               |
| The mechanism, in a clause                    | Stack traces, raw error text         |
| Migrations, pre-existing failures, follow-ups | Every touched file listed            |
| One line of verification, if it matters       | Config or diffs pasted inline        |

### Test

Would a reviewer know what to expect without opening the diff? If they'd have
to open it to understand a bullet, add the mechanism. If a bullet runs past
three lines, it's an essay — cut it.

### Example

<Bad — essay, explains the feature from scratch>
Returns are now scoped to a shipment. An order shipped in two parts is invoiced
twice, but the return flow only ever worked on the order as a whole — so a
return spanning both shipments could be requested and then never completed.
`Cin7Service::invoiceForReturn()` throws unless the items map to one invoiced
shipment, and the admin just saw "Failed to create Cin7 sale credit note" with
no way forward. Returnable items are now grouped by the shipment that carried
them on both the pharmacy and admin screens, and...
</Bad>

<Good>

## Summary

- Returns are now split by shipment. Cin7 credits against one invoice, so a
  return covering two shipments could be raised but never completed.
- Adjustment notices show their shipment and invoice number, matching the tax
  invoice.
- Fixed three credit bugs: quantity capped at ordered rather than remaining,
  discounts deducted by every adjustment, and caps trusted from client-writable
  Livewire properties.

## Notes

- Two migrations, nullable and additive. No backfill.
- Discount apportionment is still wrong — returning 10% of an order deducts the
  whole discount. Pre-existing, worth its own ticket.
</Good>

---

## Replying to review comments

Two short paragraphs, usually. Tag the reviewer, answer, done.

1. **Answer the question first.** Agree plainly when they're right — "Good catch
   @handle you're right!". Say so just as plainly when they're not, with the
   reason in a sentence.
2. **Say what changed and where.** The commit SHA plus the mechanism in one
   sentence. That's the whole fix summary.

### Always

- Tag the reviewer by GitHub handle.
- Write it as Joel — first person, casual, contractions.
- One idea per paragraph, and rarely more than two paragraphs.

### Never

- Walk through the reproduction. They reported it; they don't need it re-proved
  at them with figures.
- Narrate the process — mutation testing, how the baseline was verified, what
  was tried first. That's working-out, not an answer.
- Volunteer follow-ups, caveats or adjacent problems nobody asked about. If it
  needs a ticket, raise a ticket.
- Open with "You're absolutely right" or thank them for their thoroughness.

### Example

<Bad — re-proves the bug, narrates process, tacks on a follow-up>
Good catch — you're right, and there's no other part of the workflow stopping
it. Reproduced it before fixing. Return A pending with 50000c of credit, Return
B completed for 40000c against a 30000c order discount:

- B completes → A has reserved the whole discount → `credit_total` stored as 44000c
- A is rejected → reprinting B's adjustment applies the full discount → 11000c

A 33000c disagreement with the credit note already raised in Cin7.

Fixed in 6eb9eb4a. [...] Worth noting the freeze does more than the allowance
change alone. I mutation-tested it and the allowance fix by itself kept your
scenario green [...] Still not fixed, and pre-existing: the apportionment itself
is wrong [...]
</Bad>

<Good>
Good catch @rcscatapang you're right!

Fixed in 6eb9eb4. Only an issued adjustment consumes the discount now: the
applied figure is frozen on the return as `discount_total` when the credit note
is raised, the allowance is the order discount less what other *issued*
adjustments took, and `details()` reads the frozen figure back instead of
recomputing.
</Good>

---

## When to Break This

If the user asks for a fully technical PR (an audit trail), a stakeholder-facing
one, or wants a Test plan section back, match that instead. This is the default,
not a hard rule.
