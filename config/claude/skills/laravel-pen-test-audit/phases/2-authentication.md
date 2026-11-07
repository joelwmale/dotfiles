# Phase 3 - Authentication Attack Surface

Review every mechanism relating to account access.

Include:

- login
- registration
- password reset request
- password reset completion
- email verification
- verification resend
- MFA
- OTP
- recovery codes
- magic links
- invitations
- account activation
- OAuth login
- impersonation
- admin login
- staff login
- API authentication

## Rate Limiting

Rate limiting is mandatory on guessable or abuse-prone authentication mechanisms.

Investigate:

```text
login
registration
forgot password
password reset
verification-code submission
verification-code resend
MFA submission
OTP submission
magic-link request
invitation code
account recovery
```

Do not merely check for the presence of `throttle`.

Determine the limiter key.

IP-only throttling may be bypassed using rotating IP addresses.

Prefer appropriately scoped keys involving:

```text
normalised email
username
user ID
account ID
IP + identifier
```

depending on the endpoint.

Test case-insensitive bypasses:

```text
USER@example.com
User@example.com
user@example.com
```

Where relevant, verify multiple IPs cannot trivially bypass an account-level limiter.

Automated tests should prove abuse eventually receives:

```text
429 Too Many Requests
```

or equivalent protection.

## Low-Entropy Codes

Identify:

- 4-digit PINs
- 6-digit verification codes
- 6-digit MFA codes
- numeric invitation codes
- short recovery tokens

Assume the attacker knows the format.

Calculate whether the rate limit makes exhaustive search impractical.

A six-digit verification code with no meaningful throttling should be treated as a serious vulnerability.

The previous Canary assessment demonstrated that a six-digit registration verification code could be brute-forced through the Livewire endpoint when no limiter existed.

A per-code attempt limit is not a rate limit on guessing. Check what happens when the code is
exhausted:

- If exhausting attempts **burns the code and issues a replacement**, the attacker gets a fresh
  allowance each cycle. Compute guesses per day across replacement cycles (for example 3 wrong
  guesses per code, 3 codes per 15 minutes = about 9 guesses per 15 minutes, indefinitely).
- Look for a **cumulative failure counter keyed on the account** that survives code replacement and
  ends in a lockout or an admin/re-invite step. A counter that resets on every new code is not one.
- Check that the onboarding state that permits code sign-in (invited, no password set, passwordless
  first login) **expires**. Open-ended eligibility turns a slow guess rate into a certain eventual
  success.
- Prefer a high-entropy single-use link over a short code for first sign-in.

Test it by driving the full burn-and-replace loop, not one code.

---

# Phase 4 - Password Reset Lifecycle

Do not merely verify that password reset URLs are random.

Test the entire lifecycle.

Verify tokens:

- expire within a reasonable period
- become invalid after use
- become invalid after password change where appropriate
- cannot be reused
- belong to the intended account
- cannot be substituted between users
- are compared safely
- are not logged
- are not leaked to analytics or third-party services

The Canary audit specifically identified password-reset tokens that were looked up without enforcing expiry.

Add tests:

```text
valid reset token succeeds
expired reset token fails
used reset token fails
token for another user fails
modified token fails
```

---

# Phase 5 - Email Verification

Treat unverified email addresses as attacker-controlled.

Review flows where an email address is entered before verification.

Ask:

- Can an attacker register another person's email?
- Is the account usable before verification?
- Can the email access tenant invitations before verification?
- Can verification codes be brute-forced?
- Can verification codes be replayed?
- Do old codes remain valid after resending?
- Does changing email invalidate previous verification state?

If verification codes are regenerated, confirm old codes become invalid where expected.

---

# Phase 6 - Account Enumeration

Compare valid and invalid identifiers across:

```text
login
forgot password
registration
MFA
email verification
invitation
API authentication
```

Compare:

- HTTP status
- response body
- validation response
- redirect
- response length
- timing differences
- Inertia props
- Livewire responses

Do not leak account existence unless deliberately required.

Where enumeration cannot reasonably be avoided, document the accepted risk.

---

# Phase 7 - Password Security

Review password requirements.

Where appropriate consider Laravel's compromised password protection:

```php
Password::min(...)->uncompromised()
```

Do not automatically force extremely complicated composition rules.

Check:

- minimum length
- compromised-password protection
- password confirmation for sensitive operations
- hashing configuration
- legacy hashes
- password migration behaviour

Never log plaintext passwords.

Search logs, debugging code and events for accidental password capture.

## Re-authentication for sensitive changes

Enumerate every code path that changes the primary email, the password, MFA settings, recovery
codes, or creates an API token. Include Livewire profile actions, Fortify/Breeze overrides, admin
and supplier/staff profile screens, and any "update profile" method that saves `email` alongside
harmless fields.

```bash
rg "'email' =>|->email =|update\(\[.*email|updateProfile|updatePassword|updateEmail" app
```

For each, verify it requires the current password (`current_password` rule, `password.confirm`
middleware, or `Hash::check`) or an existing MFA challenge, and that it does so on every role's
variant of the screen, not just the main one. A stolen session cookie, an unattended device, shared
logins, or a stored-XSS payload otherwise becomes full account takeover: a new email redirects
password resets, a new password locks the owner out.

Also verify:

- the new email must be verified before it replaces the old one (see Phase 5)
- the **previous** email address is notified of the change
- other sessions are invalidated after a password change

The three profile screens (customer, supplier, admin) in one real app each had their own copy of
this gap. Check every copy.

---

# Phase 8 - Session and Cookie Security

Review:

```text
SESSION_SECURE_COOKIE
SESSION_HTTP_ONLY
SESSION_SAME_SITE
SESSION_DOMAIN
SESSION_LIFETIME
```

Production authentication cookies should normally:

- use Secure
- use HttpOnly
- use an appropriate SameSite policy
- use appropriate domain/path scope

Do not automatically assume:

```text
SameSite=None
```

is safe.

If `SameSite=None` is used, investigate why.

Particularly investigate applications combining:

```text
browser session authentication
API requests
SameSite=None
credentialed cross-origin requests
```

because incorrectly combining these controls can reopen cross-site request attacks.

Verify session IDs regenerate after authentication.

Verify logout invalidates the session.

Investigate long-lived remember-me behaviour.

For sensitive actions consider password confirmation or re-authentication.

The Canary audit previously found a session cookie without the Secure flag enabled.

Do not clear this from `config/session.php` alone. `'secure' => env('SESSION_SECURE_COOKIE')`
resolves to `null` when the variable is unset, and Laravel then only sets Secure if it believes the
request is HTTPS. Behind a TLS-terminating proxy or load balancer with trusted proxies not
configured, it believes the request is HTTP and omits the flag.

Request a real response and list **every** `Set-Cookie`:

```bash
curl -sI https://<host>/login | grep -i '^set-cookie'
```

Check each cookie, not just the session cookie:

```text
XSRF-TOKEN
<app>_session
remember_web_<hash>
any custom cookie set with Cookie::make / response()->cookie / setcookie
```

Each must carry `Secure` and, except `XSRF-TOKEN` (which JavaScript legitimately reads), `HttpOnly`,
with an explicit `SameSite`. Set `'secure'` explicitly (`true`, or `env(..., true)` with a safe
default) outside local development, configure trusted proxies, and combine with HSTS. Missing Secure
on a session cookie is MEDIUM.

---
