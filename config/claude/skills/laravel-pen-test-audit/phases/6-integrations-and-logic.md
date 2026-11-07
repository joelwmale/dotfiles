# Phase 31 - API and Token Security

If APIs exist, inspect:

```text
Sanctum
Passport
JWT
API keys
personal access tokens
OAuth
```

Test:

```text
missing token
invalid token
revoked token
expired token
different user's token
insufficient abilities/scopes
cross-tenant access
```

JWTs must have an appropriate lifetime.

Explicitly investigate JWTs lacking an expiration claim or equivalent server-side expiry/revocation strategy.

Never assume a long random token is acceptable indefinitely.

---

# Phase 32 - Webhooks

For every webhook test:

```text
missing signature
incorrect signature
modified body
valid signature
old timestamp
replayed request
duplicate event
```

Review:

- HMAC verification
- constant-time comparison
- timestamp tolerance
- idempotency
- replay protection
- payload validation

A difficult-to-guess webhook path is not authentication.

---

# Phase 33 - SSRF

Find functionality accepting URLs.

Examples:

```text
image import
URL preview
webhook tester
PDF generation
remote attachment import
metadata fetch
avatar fetch
integration test
callback validation
```

Search:

```text
Http::
Guzzle
curl_
file_get_contents(
```

where input may be user-controlled.

Test safely for access attempts toward:

```text
127.0.0.1
localhost
private IPv4 ranges
IPv6 localhost
cloud metadata ranges
```

Consider:

```text
redirect chains
DNS rebinding
alternative IP encodings
```

Do not attack real internal services.

---

# Phase 34 - SQL and Command Injection

Search:

```text
DB::raw
selectRaw
whereRaw
havingRaw
orderByRaw
statement
unprepared
exec(
shell_exec(
system(
passthru(
Process::
```

Investigate whether untrusted input reaches these APIs.

Pay particular attention to user-controlled sorting.

Whitelist:

```text
column names
sort direction
command options
```

rather than interpolating arbitrary strings.

---

# Phase 35 - Open Redirects

Identify redirects using user-supplied destinations.

Examples:

```text
?redirect=
?next=
?return=
?returnUrl=
```

Test external URLs and encoded forms.

Authentication flows are especially sensitive because open redirects can facilitate phishing and token leakage.

---

# Phase 36 - Business Logic Attacks

Attempt sequences the UI normally prevents.

Examples:

```text
approve own request
accept expired invitation
use invite twice
refund twice
redeem credit twice
change checkout price
skip payment
reuse coupon
modify completed record
cancel fulfilled record
change ownership
change workflow state
```

Ask:

> Which rules only work because users normally click buttons in the expected order?

Those rules need server-side enforcement.

## Client-chosen selectors for price-affecting options

Find every request or Livewire argument by which the client **selects** something that changes
money or entitlement: discount, promotion, coupon, concession, plan, tier, shipping method, tax
status, credit, points, reward.

```bash
rg -n -i "discount|promo|coupon|voucher|concession|credit|reward|loyalty|tier|plan" app/Livewire app/Http
```

For each selector:

1. Where is it matched? Matching by id alone (`"type_{$discount->id}" === $request->type`) means the
   client can name any option that exists, including ones not offered to it.
2. Does the server **re-derive eligibility when applying it**: targeting, enabled/date window,
   promotion type, and the stored conditions (minimum quantity, minimum spend, product scope,
   first-order-only, customer group)? Checking a subset (for example only "targeted at this
   account") lets a client apply a discount whose conditions it does not meet, or reuse one type's
   discount through another type's code path.
3. Is eligibility checked again at checkout and order placement, not only when the cart is built?
4. Oracle check: if the UI does not offer the option to this account, can the request still apply
   it? Compare cart and checkout totals with the baseline value versus the substituted value.

Tamper the Livewire `__dispatch` / `callMethod` payload or form value and diff the totals. The
Livewire snapshot checksum protects state, not the arguments of a call.

## Client-reported outcomes

Any endpoint that accepts `passed`, `score`, `won`, `correct`, `completed`, `paid`, `approved` or
similar from the client and grants a reward or state change on that basis is broken. The server must
re-derive the outcome from stored answers or server-held state.

## Validate after the cast

A numeric bound checked while the value is still a string or float, then cast to `int`, can wrap on
64-bit platforms and pass the check as a negative number. A negative amount inverts the arithmetic
and credits the account the operation was meant to debit. Cast to the final type first, validate the
cast value, reject negatives explicitly, bound both sides, and re-assert the invariant inside the
transaction that applies the change.

---

# Phase 37 - Race Conditions

Identify actions where concurrent requests matter:

```text
payments
refunds
bookings
stock
credits
discounts
one-time tokens
invitation acceptance
workflow transitions
```

Where practical, attempt safe concurrent duplicate requests.

Look for:

- missing transactions
- missing locks
- non-idempotent callbacks
- duplicate side effects

---
