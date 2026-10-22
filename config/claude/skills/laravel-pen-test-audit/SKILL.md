---
name: laravel-pen-test-audit
description: >
  Adversarial penetration-test readiness review for Laravel applications,
  including Livewire and Vue/Inertia projects. Enumerates the complete attack
  surface, actively attempts safe exploitation in an authorised local or
  staging environment, identifies vulnerabilities, fixes confirmed issues,
  adds regression tests, validates deployment and repository security, and
  produces an evidence-based pentest-readiness report.
---

# Laravel Penetration Test Readiness

## Defaults

Apply these unless the user says otherwise:

- **Report-only.** Make no code changes. Skip steps 3 to 5 below and list each fix in the report.
- **Finding IDs** are severity plus a counter: C1, C2, H1, H2, M1, L1. Keep them stable across
  the JSON, Markdown and PDF outputs.
- **Copy the PDF to `~/Desktop`** as well as `security-reports/`.
- **Inventories, not impressions.** For Livewire actions, signed-URL sites, stored strings that
  reach a browser sink, TLS-verification settings, and live cookies and headers, write out a table
  of every instance with a verdict. A phase that says "reviewed" with no table did not happen.
  Independent pentests find these by exhaustive enumeration; sampling misses them.
- **Check the live response when any URL is available** (staging, or production passively).
  Cookie flags, security headers and `security.txt` often live in the proxy or host config, not in
  the repo, so code review alone cannot clear them. See Phase 46.

You are acting as a senior Laravel application security engineer immediately before an independent penetration test.

Your objective is NOT merely to perform static analysis or produce a security checklist.

Your objective is to answer:

> "If I were an external penetration tester with the application URL and normal user access, how would I compromise this application?"

Actively investigate that question.

Then:

1. reproduce vulnerabilities safely
2. determine root cause
3. implement appropriate remediation
4. write regression tests
5. attempt the attack again
6. run the project's complete verification suite
7. report what remains

Assume the external tester will use techniques and tooling comparable to:

- Burp Suite Proxy
- Burp Repeater
- Burp Intruder
- automated web vulnerability scanners
- direct HTTP requests
- modified JSON payloads
- browser console manipulation
- JavaScript bundle inspection
- route enumeration
- parameter fuzzing
- ID substitution
- authentication abuse
- file upload manipulation
- websocket/broadcast subscription manipulation
- Git repository and history inspection
- dependency vulnerability scanning

Do not assume Laravel protects something automatically.

Verify that the application uses Laravel's protections correctly.

---

# Primary Security Principle

Frontend behaviour is NEVER an authorisation boundary.

Assume the attacker does not use the application UI.

They can directly call:

- controllers
- API endpoints
- Livewire methods
- Livewire update endpoints
- Inertia endpoints
- broadcast authentication
- signed URLs
- webhooks
- upload endpoints
- download endpoints
- internal-looking routes

Buttons being hidden, Vue components not rendering, Livewire conditions, JavaScript route guards and undocumented URLs provide no security.

Security must exist server-side.

---

# Safety and Authorisation

This skill is intended only for applications the user is authorised to test.

Prefer:

1. code analysis
2. automated tests
3. isolated local environments
4. dedicated staging environments
5. safe proof-of-concept attacks

Before active remote testing:

- Prefer localhost automatically when available.
- If the project exposes an obviously designated development or staging URL, it may be tested when the user has invoked this skill for that project.
- Never actively attack a production URL merely because it appears in configuration.
- If the only available remote target appears to be production, perform passive/code-level analysis and explicitly request authorisation before active exploitation.

Never:

- attack unrelated systems
- attack third-party providers
- deliberately corrupt production data
- perform destructive denial-of-service attacks
- send email/SMS floods
- exfiltrate real customer data
- expose secrets in reports
- create persistent backdoors

Use harmless proof payloads whenever possible.

---

# Phase 0 - Establish Architecture and Threat Model

Before investigating vulnerabilities, understand the application.

Inspect:

```text
composer.json
composer.lock
package.json
package-lock.json / pnpm-lock.yaml / yarn.lock
routes/*
config/*
bootstrap/*
app/Providers/*
app/Http/Middleware/*
app/Policies/*
app/Livewire/*
app/Http/Controllers/*
app/Http/Requests/*
app/Models/*
resources/js/*
resources/views/*
```

Determine:

- Laravel version
- PHP version
- Livewire version
- Inertia version
- Vue version
- authentication implementation
- MFA implementation
- API authentication
- session storage
- queue infrastructure
- broadcasting infrastructure
- tenancy model
- admin systems
- payment providers
- S3/object storage
- email providers
- webhooks
- OAuth integrations
- external APIs

Identify trust levels such as:

```text
Anonymous
Guest
Authenticated User
Organisation Member
Organisation Administrator
Internal Staff
Administrator
Super Administrator
API Client
Webhook Provider
Queue Worker
Scheduled Process
```

Identify sensitive information:

- personal information
- healthcare information
- financial information
- documents
- prescriptions
- credentials
- private messages
- exports
- API tokens
- commercially sensitive information

For multi-tenant applications explicitly answer:

> What prevents Tenant A from accessing Tenant B?

Do not proceed until this boundary is understood.

---

# Phase 1 - Complete Route Enumeration

Do not inspect only `routes/web.php`.

Laravel applications may define important attack surfaces in:

```text
routes/web.php
routes/api.php
routes/channels.php
routes/console.php
custom route files
package routes
Livewire update endpoints
broadcast authentication endpoints
Horizon
Telescope
Pulse
health routes
Fortify routes
Sanctum routes
```

Generate the route table:

```bash
php artisan route:list --json
```

Fall back to:

```bash
php artisan route:list
```

Classify every meaningful route:

```text
PUBLIC
GUEST
AUTHENTICATED
ADMIN
API
WEBHOOK
SIGNED
UPLOAD
DOWNLOAD
AUTHENTICATION
PASSWORD RESET
VERIFICATION
INVITATION
OAUTH
BROADCASTING
INTERNAL TOOLING
DEBUG
HEALTH
```

Search specifically for:

```text
login
logout
register
password
forgot
reset
verify
verification
mfa
otp
2fa
magic
invite
accept
upload
attachment
media
document
file
import
export
download
admin
impersonate
webhook
callback
oauth
broadcasting
horizon
telescope
pulse
debug
health
preview
signed
temporary
```

Every route that mutates state must be investigated.

---

# Phase 2 - Dangerous GET Requests

GET and HEAD requests should retrieve information.

Search for GET routes which:

- delete data
- update data
- approve data
- log users out
- modify settings
- trigger payments
- send emails
- resend tokens
- perform imports
- perform exports
- execute actions

A GET request may be:

- preloaded
- crawled
- followed by scanners
- opened automatically
- triggered cross-site

State-changing operations should generally use:

```text
POST
PUT
PATCH
DELETE
```

with appropriate CSRF protection and authorisation.

Add regression tests where changing GET semantics represents a security boundary.

---

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

# Phase 9 - Authorization, IDOR and Tenant Isolation

This is one of the highest-priority phases.

For every endpoint containing a resource identifier, attempt substitution.

Examples:

```text
/projects/123
/users/123
/orders/123
/documents/123
/organisations/123
```

Test:

```text
GET
POST
PATCH
PUT
DELETE
custom actions
downloads
exports
```

Attempt:

```text
another user's record
another tenant's record
administrator-only record
archived record
deleted record
record with discovered ULID
record with guessed UUID
```

UUIDs and ULIDs are NOT authorisation.

Search:

```php
find(
findOrFail(
firstWhere(
where('id'
resolveRouteBinding(
```

Verify every sensitive operation uses:

- policies
- gates
- scoped route binding
- explicit ownership validation
- tenant-scoped queries

Where possible prefer obvious authorisation at the route/action boundary.

The test suite should contain explicit negative tests proving:

```text
Tenant A cannot read Tenant B
Tenant A cannot update Tenant B
Tenant A cannot delete Tenant B
normal user cannot perform admin action
```

---

# Phase 10 - Missing Authorization Test Strategy

For every protected controller/action/component method, ask:

> What automated test proves an unauthorised user cannot perform this?

Do not be satisfied only by happy-path tests.

A secure feature generally needs both:

```text
authorised user succeeds
unauthorised user fails
```

For tenant applications:

```text
same tenant succeeds
different tenant fails
```

For admin systems:

```text
admin succeeds
ordinary user fails
```

---

# Phase 11 - Broadcast Channel Authorization

Treat `routes/channels.php` as security-sensitive code.

Inspect every broadcast channel callback.

Example:

```php
Broadcast::channel('users.{id}', function ($user, $id) {
    ...
});
```

Attempt to subscribe to another user's channel.

Review:

```text
private channels
presence channels
Echo subscriptions
broadcast authentication
Reverb
Pusher-compatible infrastructure
```

Look for:

```php
==
!=
```

between user-controlled channel parameters and identifiers.

Use strict comparisons or explicitly cast both operands before comparison.

The Canary audit discovered a critical broadcast authorisation issue caused by PHP type juggling, allowing users to subscribe to another user's private channel.

Test:

```text
own channel succeeds
another user's channel fails
modified identifier fails
unexpected JSON/scalar types fail
```

---

# Phase 12 - Type Juggling

Search security-sensitive comparisons.

Look for:

```php
==
!=
```

especially involving:

```text
user IDs
tenant IDs
API keys
tokens
verification codes
secrets
signatures
broadcast parameters
request JSON
Livewire properties
```

Remember JSON input can represent:

```text
string
integer
boolean
array
null
```

Do not assume request values are strings.

Prefer:

```php
===
!==
```

after normalising expected types.

For secret strings use:

```php
hash_equals()
```

where appropriate.

Attempt inputs such as:

```json
true
false
0
1
null
[]
{}
```

where type confusion may influence authentication or authorisation.

---

# Phase 13 - Mass Assignment and Hidden Parameters

Ignore what the UI sends.

Send additional fields manually.

Look for:

```php
$request->all()
request()->all()
fill()
create()
update()
forceFill()
```

Attempt injection of:

```text
id
user_id
organisation_id
tenant_id
owner_id
role
permissions
is_admin
is_super_admin
status
approved
approved_at
email_verified_at
balance
credit
price
amount
discount
subscription
created_at
updated_at
```

Validation alone is not authorisation.

Determine whether the current actor should be allowed to set each field.

---

# Phase 14 - Livewire Attack Review

Livewire public properties must be treated like browser-submitted form values.

They are NOT trusted server-side state merely because they are PHP properties.

For every Livewire component inspect:

```text
public properties
#[Locked]
mount()
hydrate/dehydrate behaviour
actions
validation
computed properties
file uploads
model binding
```

Attempt to modify public properties manually through Livewire requests.

Attack:

```text
model IDs
tenant IDs
ownership IDs
role
status
price
permissions
tokens
hidden booleans
workflow state
```

For example, if the component contains:

```php
public int $userId;
```

assume the attacker can attempt another value unless it is locked or independently authorised.

Do not rely on:

```text
disabled input
hidden input
wire:show
conditional button
Vue/Alpine state
```

Every Livewire action that modifies protected data should independently enforce its security boundary.

Securing Laravel specifically highlights the danger of treating public Livewire properties as trusted internal state.

## Action inventory (mandatory)

Every public method on a Livewire component is an HTTP endpoint. Build a table of **all** of them:

```bash
rg -n "public function \w+\(" app/Livewire
```

Columns: component, method, what it writes or reveals, authorisation inside the method (policy,
gate, role check, scoped query, or none), and the client-writable properties it reads.

Rules for the verdict:

- Authorisation in `mount()`, in a Blade `@if`/`@can`, or in a `$user->can_x` flag on a button does
  **not** cover the method. Grep the views for the permission flags they check, then confirm the
  action method repeats the same check. A rule that exists only in the template is a finding.
- **Dead actions count.** A method with no button, or whose inputs are `disabled`/`readonly` in the
  view, is still callable with `$wire.$call()` / `$wire.$set()`. A save method for fields the UI
  shows as read-only is a privilege escalation, and a stored-XSS or data-integrity vector.
- A component mounted in a shared layout (cart, notifications, search) is reachable by **every**
  authenticated role, so its actions need role checks even though the page "belongs" to one role.
- Validation is not authorisation. `rules()` proving a field is a string under 255 characters says
  nothing about whether this user may write it.
- Public properties that carry ids, paths, or prices into an action must be `#[Locked]` or
  re-derived server-side. Properties that hold arrays of records (stocks, documents, line items) are
  client-writable all the way down, including nested keys.

### Middleware does not follow Livewire updates

Livewire replays only its **persistent middleware** (by default auth and `can`-style) on
`/livewire/update`. Check:

```bash
rg "addPersistentMiddleware|isLivewireRequest|routeIs\('livewire|is\('livewire|expectsJson" app bootstrap
```

- Custom role/status/onboarding middleware not registered via `Livewire::addPersistentMiddleware()`
  does not run on actions.
- Middleware that lets Livewire requests through (`isLivewireRequest()`, `is('livewire/*')`)
  provides no protection on those requests.
- Middleware that skips its check when `$request->expectsJson()` can be bypassed by sending
  `Accept: application/json`. Test with that header.

Prove each gap by calling the action as a lower role with `Livewire::test()->call()` and asserting
the data is unchanged.

---

# Phase 15 - Inertia / Vue Data Exposure

Inspect:

```text
Inertia::render()
Inertia::share()
HandleInertiaRequests
JsonResource
ResourceCollection
toArray()
```

Remember:

> A value does not need to appear visually on the page to be exposed.

Anything provided as an Inertia prop is available to the browser.

Search for exposure of:

```text
password hashes
remember tokens
API tokens
private notes
internal IDs
PII
other tenant data
permissions
signed URLs
secrets
private storage paths
```

Inspect shared props especially carefully because they may be included on every response.

Frontend permission checks are UX only.

Repeat protected requests directly without Vue.

---

# Phase 16 - File Upload Security

Treat every upload endpoint as potentially CRITICAL.

Find:

```bash
rg "WithFileUploads|UploadedFile|storeAs|storePublicly|storePubliclyAs|putFile|putFileAs|mimes:|mimetypes:|File::types|image:" app routes resources
```

Inspect:

- controllers
- Form Requests
- Livewire uploads
- rich-text editors
- avatars
- document uploads
- import systems
- CSV uploads
- admin uploads
- temporary uploads

Determine:

1. Who can upload?
2. What files can they upload?
3. Is validation server-side?
4. Is MIME/content validated?
5. Is extension validated?
6. Is the filename attacker-controlled?
7. Where is the file stored?
8. Can the web server execute it?
9. Can the browser render active content?
10. Can files overwrite existing files?
11. Are private files actually private?
12. Can tenant boundaries be bypassed?

Attempt harmless variants:

```text
test.php
test.phtml
test.phar
test.php5
test.pht
test.php.jpg
test.jpg.php
test.PHP
```

Safe content:

```php
<?php echo 'SECURITY_TEST'; ?>
```

Also test:

```text
spoofed Content-Type
double extensions
uppercase extensions
oversized files
HTML files
SVG containing scripts
path traversal filenames
Unicode filenames
duplicate filenames
```

Do NOT create a functional webshell.

The objective is simply to prove executable files cannot be uploaded and invoked.

Search:

```bash
find public storage/app/public -type f \
  \( -iname "*.php" -o -iname "*.phtml" -o -iname "*.phar" -o -iname "*.php5" -o -iname "*.pht" \)
```

User-controlled uploads should ideally never be executable by PHP.

---

# Phase 17 - File Downloads, Exports and Public Storage

Find:

```php
Storage::download
Storage::response
response()->download
response()->file
temporaryUrl
temporarySignedRoute
```

Inspect all:

```text
exports
CSV files
reports
documents
PDFs
temporary files
backups
```

Never assume a filename is secure because it contains:

```text
timestamp
UUID
random-looking identifier
username
date
```

Check whether the directory itself is public.

The Canary audit previously identified admin exports placed in a publicly accessible directory using predictable filenames.

Attempt:

```text
unauthenticated download
different user's download
different tenant's download
expired URL
modified URL
guessed URL
```

Prefer private storage with authorised access or appropriately scoped temporary URLs.

For every download endpoint also check:

- **Path normalisation.** A prefix guard such as `str_starts_with($path, 'exports/')` is bypassed by
  `exports\file`, `./exports/`, `a/../exports/`, or encoded variants, because Flysystem normalises
  after the guard ran. Normalise (`/` and `\`, dot segments) and resolve before checking, then
  allow-list directories rather than deny-listing them.
- **Per-file authorisation.** A valid signature or "user is logged in" is not permission to read a
  specific file. Check that the route authorises the requester against the file's owning record, and
  that sensitive categories (identity documents, registration certificates, exports) have their own
  gate.
- Prefer signing an **identifier** (record id) and resolving the path server-side, never signing a
  path string.

---

# Phase 18 - Signed URL Security

Do not assume a signed URL means the underlying action is safe.

Inspect every:

```php
signedRoute()
temporarySignedRoute()
hasValidSignature()
hasValidRelativeSignature()
```

Investigate whether ALL security-relevant parameters are included in the signature.

Look for cases where an unsigned query parameter can change:

```text
user
tenant
resource
redirect destination
permission
operation
```

Verify:

```text
modified parameters fail
expired URL fails
resource substitution fails
tenant substitution fails
```

Also determine whether a signed link should be:

```text
single-use
multi-use
revocable
time-limited
```

A cryptographically valid URL does not replace business-level authorisation.

## Signature versus input source

The `signed` middleware and `hasValidSignature()` verify the **query string only**. `$request->all()`,
`$request->input()` and `$request->get()` prefer the **request body**, including a JSON body on a
`GET`. An attacker holding any one valid signed URL can replay it with a body that overrides the
signed parameter, and the signature still passes.

```bash
rg -n "'signed'|signed\b|hasValidSignature" routes app
```

For every signed route, open the handler and flag any use of `$request->all()`, `input()`,
`get()`, `only()`, `validated()` or magic property access (`$request->path`) for a signed
parameter. Signed values must come from `$request->query('x')` or a route parameter. Test it:

```text
GET <valid signed url>
Content-Type: application/json
{"path":"<other file>"}
```

and assert the response is still the originally signed resource (or a 4xx), and that the other file
was not returned.

## Signing oracles

Search for every place the application **creates** a signed URL from a value it did not generate:

```bash
rg -n "temporarySignedRoute|signedRoute|temporaryUrl" app resources
```

If the signed value (a path, filename, document id) comes from a client-writable source (a Livewire
public property or array, a request field, a form-submitted JSON blob), any user can set it to a
file they should not see and let the application hand back a signed link. The app has become a
signing oracle. Check also that every generator adds the same permission/scope parameters as the
others; one generator that omits the gate defeats the gate on all links.

Build an inventory of every signing site with: value source, is the source client-writable,
parameters signed, and what the download handler authorises.

---

# Phase 19 - XSS and Browser Injection

Search:

```bash
rg '\{!!|v-html|innerHTML|HtmlString' app resources
```

Review all locations where untrusted data enters HTML.

Pay particular attention to unusual attacker-controlled strings:

```text
User-Agent
Referer
filename
CSV content
webhook fields
support messages
names
addresses
admin notes
HTTP headers
error messages
```

Attackers deliberately target values developers do not normally think of as "user input".

The Canary audit found stored XSS because an attacker-controlled User-Agent string was rendered unescaped in an administrative interface. That could have led to admin account takeover.

Test harmless payloads such as:

```html
<img src="x" onerror="alert(1)" />
<script>
  alert(1);
</script>
```

Where HTML is intentionally supported, sanitise rather than blindly escape.

Review rich-text editors carefully.

## JavaScript library sinks

`{{ }}` escaping does not protect a value handed to a JavaScript library. Libraries such as
ApexCharts, Chart.js, DataTables, Select2, Tom Select, tippy.js, Flatpickr and Tiptap render labels,
categories, tooltips, legends, option text and titles through `innerHTML` unless configured not to.
Escaped-in-Blade, JSON-encoded, then rendered unescaped by the library is still stored XSS.

Find them:

```bash
rg -n "categories:|labels:|tooltip|formatter|series:|x-data|Js::from|@json|wire:ignore|new (Apex)?Chart|DataTable\(" resources app
```

For each place a **stored string** feeds a chart, table, tooltip, autocomplete or select:

1. Identify the field and every role that can write it (supplier names, product names, org names,
   usernames, categories, notes). Include fields the UI shows as disabled but a Livewire action
   still saves (Phase 14).
2. Identify who views it: other tenants, admins, and "log in as" / impersonation sessions. Low
   privilege writing, high privilege reading is the critical shape.
3. Check the **pinned library version's** own source for the sink, for example
   `rg "innerHTML" node_modules/<lib>/src` around tooltip and label code. Do not assume a library
   escapes because its docs say nothing.
4. Fix by escaping or plain-text-normalising the labels server-side (`e()`, `strip_tags`), and by
   configuring the library to render text (custom `formatter` using `textContent`, or the option
   that disables HTML). Update the library where a patched version exists.

Prove it with a harmless payload (`<img src=x onerror=...>`) and a hover or click; tooltips only
render on interaction, so a static page load will not reveal them.

---

# Phase 20 - Content Security Policy

Review whether CSP exists.

If not, report it as defence-in-depth rather than pretending CSP substitutes for fixing XSS.

Prefer an application-specific policy.

Consider:

```text
default-src
script-src
style-src
img-src
font-src
connect-src
frame-src
frame-ancestors
form-action
base-uri
object-src
```

Pay special attention to:

```text
base-uri
object-src
frame-ancestors
```

Avoid broad:

```text
*
unsafe-eval
unsafe-inline
```

unless genuinely required.

Where a full policy cannot safely be introduced immediately, consider:

```text
Content-Security-Policy-Report-Only
```

first.

Absence of a CSP is a reportable finding (LOW) in its own right, not a footnote. Confirm it from the
live response (Phase 46) and from code (`rg -i "content-security-policy|csp" app config bootstrap
public`), including reverse-proxy and host config. A CSP with `unsafe-inline` in `script-src` does
not stop injected inline scripts. Note that Alpine's default build needs `unsafe-eval`; the
CSP-compatible Alpine build and nonces are the route to a strict policy.

---

# Phase 21 - Third-Party Browser Assets / SRI

Enumerate externally loaded:

```text
<script>
<link rel="stylesheet">
```

from third-party CDNs.

Where the asset is immutable/versioned, consider:

```text
integrity=
crossorigin=
```

Subresource Integrity can prevent a compromised CDN asset from silently changing.

Do not require SRI for third-party scripts intentionally designed to change dynamically where it would break their supported integration.

The previous Canary audit specifically identified static third-party assets without SRI.

---

# Phase 22 - CSRF and CORS

Review all state-changing browser endpoints.

Inspect CSRF exclusions.

Broad CSRF exemptions require justification.

Review CORS:

```text
allowed_origins
allowed_methods
allowed_headers
supports_credentials
```

Be extremely cautious combining:

```text
supports_credentials=true
wildcard/overly broad origins
SameSite=None session cookies
```

Test cross-origin behaviour rather than assuming configuration is correct.

---

# Phase 23 - Security Headers

Inspect actual HTTP responses.

Evaluate:

```text
Strict-Transport-Security
Content-Security-Policy
X-Content-Type-Options
Referrer-Policy
Permissions-Policy
frame-ancestors
```

Report each missing header as its own line item, with the severity below, instead of omitting it for
being "only hardening":

```text
Content-Security-Policy missing        LOW
Permissions-Policy missing             INFORMATIONAL
Strict-Transport-Security missing      LOW (MEDIUM if cookies also lack Secure)
X-Content-Type-Options / Referrer-Policy missing   INFORMATIONAL
```

Suggest a concrete `Permissions-Policy` that disables features the app does not use, for example
`camera=(), microphone=(), geolocation=(), payment=(), usb=()`, adjusted for what the app needs
(a payment page needs `payment`).

Do not assign inflated severity to missing defence-in-depth headers.

Assess practical impact.

For HSTS, do not immediately enable:

```text
includeSubDomains
preload
```

unless all relevant subdomains support HTTPS.

---

# Phase 24 - Cryptography

Search for custom cryptography.

Look for:

```text
openssl_encrypt
openssl_decrypt
sodium
AES
cipher
encrypt
decrypt
IV
nonce
key derivation
```

Strongly prefer established Laravel or reputable cryptography libraries.

Avoid custom encryption schemes.

## Disabled TLS verification

Search config and code for switched-off certificate or hostname checks:

```bash
rg -n -i "verify_peer|verify_peer_name|allow_self_signed|verify.?=>\s*false|withoutVerifying|CURLOPT_SSL_VERIFY|SSL_VERIFY_SERVER_CERT|'verify'\s*=>|sslmode|ssl_mode|stream_context" config app bootstrap
```

Typical hits:

```text
config/database.php   redis 'context' => ['ssl' => ['verify_peer' => false, 'verify_peer_name' => false]]
config/database.php   MySQL PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false, Postgres sslmode=require
config/mail.php       SMTP stream options with verify_peer false
Http::withoutVerifying(), Guzzle 'verify' => false
```

These are often copied from a managed-Redis tutorial to make a self-signed or hostname-mismatched
endpoint "just work". With verification off, TLS gives no protection against an active
man-in-the-middle, and for Redis that includes cache and **queue** payloads (PHP-serialised job
objects), which makes tampering a deserialisation concern. Rate it LOW unless the network path is
untrusted or the data is sensitive, state what you could not establish (effective URL, whether TLS
is used at all, network isolation), and recommend enabling verification with the provider's CA
bundle and the correct hostname. Never leave `Http::withoutVerifying()` in non-test code.

Check:

- random IV/nonce per encryption operation
- authenticated encryption
- key storage
- key rotation
- deterministic encryption only where explicitly required

The Canary audit identified a custom encryption implementation that derived and reused an IV from an MD5 hash, undermining the intended encryption properties.

If encrypted data must be searchable, investigate appropriate cryptographic indexing rather than reusing IVs or creating deterministic encryption without understanding the security trade-offs.

---

# Phase 25 - Secure Randomness

Search:

```bash
rg 'md5\(|sha1\(|uniqid\(|rand\(|mt_rand\(|tempnam\(|str_shuffle\(|shuffle\(|array_rand\(' app routes
```

These functions are not automatically vulnerabilities.

Determine whether the value is security-sensitive.

Security-sensitive randomness includes:

```text
verification codes
passwords
API keys
reset tokens
invite tokens
secret URLs
recovery codes
nonces
```

Prefer:

```php
random_int()
Str::random()
Str::password()
random_bytes()
```

as appropriate.

The previous Canary audit found `rand(100000, 999999)` being used for verification codes.

---

# Phase 26 - Secrets and Git History

Scanning the current working tree is NOT enough.

Inspect Git history.

Use tooling such as:

```text
Gitleaks
TruffleHog
```

where available.

Look for:

```text
API keys
database credentials
AWS keys
OAuth secrets
email provider credentials
payment secrets
JWT secrets
private keys
.env files
.env.example
service-account files
```

Report locations without printing secret values.

A secret removed from the current branch may remain available in Git history.

If a real secret was ever committed:

1. treat it as compromised
2. rotate/revoke it
3. remove it from current code
4. consider Git history cleanup where appropriate

The Canary audit found active credentials in repository history, including credentials originally committed in `.env.example`.

---

# Phase 27 - PII and Production Data in Source Control

Search repositories for information that looks like:

```text
customer exports
CSV imports
SQL dumps
email lists
phone numbers
addresses
prescriptions
health data
test fixtures copied from production
database snapshots
```

Production PII should not be casually copied into:

```text
Git
development
staging
fixtures
CI artifacts
developer laptops
```

The Canary audit found sensitive information inside a committed CSV file.

Review both current files and Git history.

---

# Phase 28 - Configuration Exposure

Validate security-critical configuration during application boot where appropriate.

Look for:

```text
missing signing secrets
blank webhook keys
placeholder API secrets
incorrect environment
unsafe defaults
```

A production application should fail clearly rather than silently run with missing critical security configuration.

Never print secret configuration values.

---

# Phase 29 - Internal Laravel Tooling

Explicitly enumerate:

```text
/horizon
/telescope
/pulse
/_ignition
debugbar
health endpoints
queue dashboards
admin dashboards
```

Test as:

```text
unauthenticated user
ordinary authenticated user
wrong tenant
administrator
```

The Canary audit previously found Horizon accessible to ordinary authenticated users, exposing queued jobs and potentially sensitive data.

Do not rely solely on:

```text
APP_ENV
IP restrictions
security through obscurity
```

Verify actual authorisation.

---

# Phase 30 - Error and Debug Information

Trigger safe errors.

Test:

```text
invalid model IDs
invalid JSON
invalid enums
bad file uploads
bad signatures
expired tokens
missing records
invalid webhook payloads
```

Production responses must not expose:

```text
stack traces
database queries
filesystem paths
environment variables
credentials
internal network addresses
secrets
```

Check:

```text
APP_DEBUG=false
APP_ENV=production
```

but also test actual responses.

---

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

# Phase 38 - Dependency Security

Run:

```bash
composer audit --locked
npm audit
composer outdated --direct --locked
npm outdated
```

Investigate:

```text
known vulnerabilities
abandoned packages
unsupported packages
unmaintained dependencies
```

Do not blindly upgrade.

Determine whether the vulnerable code path is reachable.

Run the audits fresh against the lockfile, and cover **both ecosystems**. Advisories are published
daily, so a clean result from an earlier run is not evidence. Also run `composer audit --abandoned`
and `npm audit --omit=dev` alongside the full `npm audit`.

Report in a form the owner can act on:

- one line per vulnerable package with installed version, advisory id, severity and title
  (framework packages, `league/commonmark`, `league/flysystem`, `axios`, `moment`, build tooling)
- direct versus transitive, and runtime versus dev-only
- counts of outdated direct and transitive packages, plus the notable ones that are majors behind
- for front-end libraries, whether the vulnerable feature is reachable (a Node-only axios adapter
  issue is not exploitable in the browser; a markdown renderer bypass on user content is)

Rate by reachability, not by the advisory's headline severity. A dependency finding that is purely
unpatched-but-unreachable is LOW; a reachable XSS, deserialisation or auth issue is not.

---

# Phase 39 - Supply Chain Security

Treat package installation itself as a security boundary.

Before adding a new dependency, verify:

```text
exact package name
maintainer
repository
download/adoption history
recent releases
whether project is abandoned
```

Be especially cautious when an AI assistant suggests a package.

Do NOT automatically install an unfamiliar package simply because its name sounds plausible.

This protects against package-name hallucinations and slopsquatting attacks.

Prefer minimal dependencies.

For small/simple functionality, consider whether a dependency is justified.

Do not assume a newer dependency release is automatically safer; inspect suspicious ownership, tag or repository changes where risk warrants it.

Securing Laravel has recently highlighted both AI-driven slopsquatting and dependency/tag supply-chain risks.

---

# Phase 40 - PHP / Framework Support Status

Determine:

```text
PHP version
Laravel version
Livewire version
Node version
major security-relevant packages
```

Check whether each is actively supported.

Do not rely merely on the minimum version in `composer.json`.

Confirm what production actually runs where possible.

Flag unsupported runtimes.

Read the **constraints**, not only the installed versions:

```bash
jq '.require | {php, "laravel/framework", "livewire/livewire"}' composer.json
php -v; php artisan --version
```

A floor such as `"php": "^8.2"` or `"laravel/framework": "^12.0"` permits every release down to that
version, so it is a finding if that floor is out of active support, even when the server happens to
run something newer. Recommend raising the floor so no environment can run an old version.

Compare against the **current** support tables, fetched at audit time, not recalled:

```text
https://www.php.net/supported-versions.php
https://laravel.com/docs/releases#support-policy
```

Rules of thumb for the date maths: PHP gets about 2 years of active support then 2 years of security
fixes; Laravel gets about 18 months of bug fixes then security fixes to roughly 24 months after
release. Use today's date, and state in the report the release date, the date bug fixes ended, the
date security fixes end, and the current supported version.

```text
security-only support (no bug fixes)     LOW   - plan the upgrade, give the end date
end of life (no security fixes)          HIGH  (MEDIUM if internet-facing exposure is limited)
```

Do the same for Livewire, the major front-end framework, and Node in CI/build.

---

# Phase 41 - Repository Security

Security does not stop at application code.

Review repository controls when information is available.

Check:

```text
branch protection
required pull requests
required reviews
required CI checks
force-push restrictions
administrator bypass
signed commits where applicable
GitHub organisation MFA
repository visibility
```

Production branches should not ordinarily accept arbitrary direct pushes.

The previous audit specifically recommended branch protection because malicious changes pushed directly into production branches may otherwise bypass review.

---

# Phase 42 - Deployment Keys

Review how production servers access source repositories.

Avoid broad personal SSH keys with access to every repository.

Prefer:

```text
repository-specific deploy keys
read-only access
minimum required permissions
```

Where Forge or another platform installs global provider keys, verify the key cannot unnecessarily:

```text
read unrelated repositories
write to repositories
push malicious commits
```

The Canary audit specifically recommended repository-specific read-only deploy keys for this reason.

---

# Phase 43 - Security Monitoring and Honeytokens

For high-risk applications, consider whether compromise detection exists.

Potential techniques include:

```text
canary credentials
canary files
fake database dumps
honeytokens
alerts on unexpected use
```

These are operational recommendations, not substitutes for application security.

Do not implement external canary services automatically without authorisation.

The previous assessment recommended Canary Tokens as an early-warning mechanism for repository/server compromise.

---

# Phase 44 - Logging

Review security-relevant logging.

Ensure sufficient audit information exists for:

```text
authentication
password changes
MFA changes
admin actions
privilege changes
sensitive exports
failed authorisation
critical configuration changes
```

Do NOT log:

```text
passwords
reset tokens
MFA codes
access tokens
API keys
private healthcare information unnecessarily
```

Review log retention and access boundaries where applicable.

---

# Phase 45 - `security.txt`

Check:

```text
/.well-known/security.txt
```

For public/high-risk systems, consider exposing an appropriate security contact using RFC 9116.

Treat absence as informational, not an exploitable vulnerability. Still report it, with the exact
URLs checked (`/.well-known/security.txt` and `/security.txt`) and on every app domain, not only the
marketing site.

A usable file needs `Contact:` and `Expires:` (RFC 9116 requires both). Serve it from
`public/.well-known/security.txt` and confirm the web server does not block dotfile paths.

---

# Phase 46 - External Passive Validation

When an authorised staging or production URL is available, perform passive checks.

Useful checks may include:

```text
SecurityHeaders
Laravel-specific public scanners
TLS configuration scanners
```

Do not rely on scanner results alone.

Investigate every finding manually.

Whenever a staging or production hostname is known (config, CI, README, `APP_URL`), run these
read-only checks and record the raw output as evidence. They are what an external tester reports
first, and none can be settled from the repo:

```bash
curl -sI https://<host>/                         # security headers
curl -sI https://<host>/login | grep -i '^set-cookie'   # every cookie and its flags
curl -s -o /dev/null -w '%{http_code}\n' https://<host>/.well-known/security.txt
curl -sI http://<host>/                          # HTTP redirects to HTTPS, HSTS present
```

Tabulate: each header present or missing, each cookie with Secure/HttpOnly/SameSite, security.txt
status. If no URL is known, say so in the report and mark these as unverified rather than passing
them.

The previous Canary assessment combined source review, passive production checks, automated Burp scanning and manual staging exploitation.

---

# Phase 47 - Active Staging Pentest

If an isolated authorised staging environment is available, behave like a penetration tester.

Do not restrict testing to existing feature tests.

Use manual HTTP requests to probe:

```text
route manipulation
IDOR
parameter tampering
authentication brute-force protection
Livewire manipulation
broadcast subscriptions
uploads
downloads
signed URLs
webhooks
XSS
redirects
error handling
```

Where tooling is available, Burp Suite or equivalent can be used.

Automated scans are supplementary.

Every meaningful scanner result must be manually validated before being reported as a vulnerability.

---

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

# Required Adversarial Checklist

Before completion explicitly answer each:

```text
Can anonymous users access protected resources?

Can one user access another user's data?

Can Tenant A access Tenant B?

Can a normal user perform an admin action?

Can I subscribe to another user's private broadcast channel?

Can I manipulate a Livewire public property to change ownership, price,
permissions or resource identity?

Can I expose sensitive information through Inertia props?

Can I upload PHP or another executable file?

Can uploaded HTML/SVG execute script?

Can I retrieve another user's uploaded files?

Can I guess public exports?

Can I brute-force login?

Can I brute-force password resets?

Can I brute-force verification codes?

Can I bypass throttling by changing IP?

Can I bypass throttling by changing email casing?

Can I enumerate users?

Can I reuse password-reset tokens?

Can I reuse verification tokens?

Can I modify signed URL parameters?

Can I reuse sensitive signed URLs?

Can I forge or replay a webhook?

Can I exploit loose PHP comparisons?

Can I manipulate JSON types?

Can I inject privileged mass-assignment fields?

Can I cause stored XSS through unusual inputs such as User-Agent?

Can I inject SQL?

Can I trigger shell commands?

Can I cause SSRF?

Can I exploit an open redirect?

Can I access Horizon?

Can I access Telescope?

Can I access Pulse?

Can I expose stack traces?

Can I retrieve .env, logs, SQL dumps or backups?

Are secrets present anywhere in Git history?

Is real PII present anywhere in Git history?

Are insecure random-number functions generating secrets?

Is custom cryptography being used?

Are password-reset tokens short-lived and single-use?

Are API/JWT tokens appropriately expiring?

Are cookies Secure, HttpOnly and appropriately SameSite?

Are dangerous state changes performed using GET?

Are browser credentialed CORS rules safe?

Are third-party static assets protected appropriately?

Are packages vulnerable, abandoned or suspicious?

Could a hallucinated package name be installed?

Can production branches be modified without meaningful review?

Do production deployment credentials have excessive Git access?

Can important business operations be replayed?

Can race conditions create duplicate sensitive actions?

Does every public Livewire method authorise inside itself, including methods
the UI never calls and fields it renders disabled?

Does custom middleware actually run on Livewire update requests, and does any
of it skip checks for Livewire or Accept: application/json requests?

Can a signed URL parameter be overridden with a request body or JSON on a GET?

Can the application be made to sign a URL for a file I should not see?

Can a path guard be bypassed with backslashes, dot segments or encoding?

Can a stored name or label reach a chart, tooltip, select or table library
that renders it as HTML, and who views it?

Can I choose a discount, promotion or other price-affecting option the server
did not offer me, or whose conditions I do not meet?

Does any endpoint trust a client-reported result, or validate a number before
casting it?

Do sign-in code attempts reach a cumulative, account-level lockout across
code replacements, and does passwordless onboarding expire?

Does every email, password, MFA and API-token change require the current
password, on every role's screen, and notify the old address?

Does every live Set-Cookie carry Secure (and HttpOnly where applicable)?

Are CSP, Permissions-Policy and security.txt present on the live app domain?

Is TLS certificate or hostname verification disabled for Redis, database,
mail or HTTP clients?

Do the composer.json PHP and Laravel constraints permit versions that are
security-only or end-of-life?
```

No item should be marked verified without evidence.

---

# Severity

## CRITICAL

Examples:

```text
remote code execution
executable arbitrary file upload
authentication bypass
administrator account takeover
major cross-tenant data compromise
production credential compromise
arbitrary filesystem access to secrets
payment manipulation with major impact
```

## HIGH

Examples:

```text
significant IDOR
privilege escalation
stored XSS reaching administrators (CRITICAL when it executes in an admin or impersonated session)
private file disclosure, including signed-URL bypass or signing oracles
client-chosen discount or price option applied without eligibility checks
missing authorisation on critical actions
serious password reset weakness
SSRF with meaningful internal access
webhook forgery causing significant actions
broadcast channel data leakage involving sensitive data
```

## MEDIUM

Examples:

```text
meaningful account enumeration
missing throttling
limited reflected XSS
session configuration weakness (session cookie missing Secure)
Livewire actions missing server-side authorisation (HIGH where they reach money, admin data or other tenants)
open redirect
limited information disclosure
security-sensitive dependency vulnerability
```

## LOW

Examples:

```text
minor information disclosure
limited hardening gaps
missing Content-Security-Policy
sensitive email/password change without re-authentication
code-guessing limits that reset on replacement
disabled TLS verification (Redis, database, mail)
PHP or Laravel constraint permitting security-only versions
vulnerable Composer or npm packages (rated by reachability)
```

## INFORMATIONAL

Examples:

```text
security.txt
missing Permissions-Policy
defence-in-depth improvements
operational recommendations
```

Severity must reflect realistic exploitability and impact.

Do not inflate findings.

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

# Required Final Report

# Security / Pentest Readiness Report

## Executive Summary

```text
Overall risk: LOW / MEDIUM / HIGH / CRITICAL
Pentest readiness:
READY
READY WITH KNOWN RISKS
NOT READY
```

Explain the assessment.

---

## Scope

Record:

```text
repository reviewed
branch/commit
Laravel version
PHP version
frontend stack
testing environment
domains tested
user roles tested
```

---

## Attack Surface

Provide counts where practical:

```text
routes
public endpoints
authentication endpoints
API endpoints
Livewire components
broadcast channels
uploads
downloads
webhooks
signed URLs
admin interfaces
```

---

## Findings

Use:

```text
[C-01] Finding

Severity:
CVSS if calculated:
Affected area:
Attack prerequisite:
Impact:
Evidence:
Safe reproduction:
Root cause:
Remediation:
Regression test:
Status:
```

Repeat for:

```text
Critical
High
Medium
Low
Informational
```

---

## Security Controls Verified

Example:

```text
✓ Tenant isolation tested
✓ IDOR attempts rejected
✓ Login throttling tested
✓ Verification throttling tested
✓ Password reset expiry tested
✓ Password reset single-use tested
✓ Broadcast channels tested
✓ Livewire property manipulation tested
✓ Executable uploads rejected
✓ Private downloads authorised
✓ Webhook signatures tested
✓ Git history secret scan completed
✓ Production debug protections verified
```

Only mark controls verified when actually tested.

---

## Automated Verification

Record actual output summary:

```text
Application tests:
Security regression tests:
PHPStan:
Pint:
Composer Audit:
NPM Audit:
Frontend tests:
TypeScript:
Production build:
Secret scan:
```

---

## External Surface

Record results from:

```text
security headers
TLS
cookies
public files
production debug behaviour
```

---

## Remaining Risks

Identify anything:

```text
outside repository scope
requiring production verification
requiring infrastructure access
requiring third-party access
accepted by business
not safely testable
```

---

## Pentest Handoff

Document for the external pentester:

```text
authentication architecture
roles
tenant boundaries
APIs
uploads
downloads
broadcasting
Livewire usage
webhooks
external integrations
sensitive workflows
```

Do not conceal known weaknesses from the external tester.

---

---

# Phase 50 - Generate Formal PDF Security Report

A completed security review MUST produce a professional PDF report.

The Markdown/console summary is not the final deliverable.

The required outputs are:

```text
security-reports/
├── security-pentest-report.md
└── security-pentest-report.pdf
```

Create the directory if required.

The Markdown report is the canonical editable source.

The PDF is the formal deliverable suitable for:

- client delivery
- internal review
- external penetration tester handoff
- compliance evidence
- project records

---

# PDF Requirements

The PDF should be professional and readable rather than a raw terminal dump.

It should contain:

1. Cover page
2. Executive summary
3. Scope
4. Testing methodology
5. Architecture / attack-surface summary
6. Risk summary
7. Detailed findings
8. Security controls successfully verified
9. Automated verification results
10. Remaining risks
11. Pentest handoff notes
12. Appendix where useful

Do NOT include:

- plaintext secrets
- passwords
- API credentials
- private keys
- reset tokens
- session cookies
- access tokens
- sensitive production data

Redact sensitive evidence.

---

# Cover Page

The first page should include:

```text
Security & Penetration Test Readiness Report

Application: <project name>
Assessment Date: <date>
Repository: <repository name where safe>
Branch / Commit: <branch and short commit hash>
Assessment Type: Pre-Penetration Test Security Review
Overall Risk: <LOW / MEDIUM / HIGH / CRITICAL>
Pentest Readiness: <READY / READY WITH KNOWN RISKS / NOT READY>
```

Where available also include:

```text
Prepared For: <client/project>
Prepared By: Pixel
```

Do not fabricate client names or company details.

---

# Executive Risk Summary

Include a summary table:

| Severity      | Open | Fixed | Accepted |
| ------------- | ---: | ----: | -------: |
| Critical      |    X |     X |        X |
| High          |    X |     X |        X |
| Medium        |    X |     X |        X |
| Low           |    X |     X |        X |
| Informational |    X |     X |        X |

The counts MUST match the findings in the report.

Do not manually estimate these values if they can be generated programmatically.

---

# Finding Format

Every vulnerability should use a consistent structure.

Example:

```markdown
## H-02 - Cross-Tenant Document Access

**Severity:** High
**Status:** Fixed
**Affected Area:** Document download endpoint
**Attack Prerequisite:** Authenticated user

### Description

Explain the vulnerability.

### Impact

Explain realistic consequences.

### Evidence

Describe what was observed.

Do not include real customer data or secrets.

### Safe Reproduction

Explain the minimum steps used to demonstrate the issue.

### Root Cause

Explain why the vulnerability existed.

### Remediation

Explain the implemented correction.

### Regression Test

Document the test proving the vulnerability remains fixed.

### Verification

State how the exploit was attempted again and the resulting behaviour.
```

---

# Evidence Handling

Screenshots and request/response snippets may be included where they materially improve the report.

Before including evidence:

- remove session cookies
- remove bearer tokens
- remove CSRF tokens where sensitive
- remove API keys
- redact email addresses where unnecessary
- redact healthcare or customer data
- redact private internal URLs where necessary

Never sacrifice confidentiality merely to make a finding easier to demonstrate.

Use synthetic identifiers wherever possible.

---

# Report Generation

Generate:

```text
security-reports/security-pentest-report.md
```

first.

Then convert that document into:

```text
security-reports/security-pentest-report.pdf
```

Prefer existing project tooling if a suitable document/PDF generator is already available.

Do NOT permanently add a PDF package to the application's Composer dependencies merely for report generation.

If no suitable tooling already exists, a temporary package runner such as CPX may be used.

CPX is preferred over adding one-off report-generation dependencies to the application.

Example pattern:

```bash
cpx <trusted-package> <command> ...
```

The exact package and command may differ depending on available tooling.

---

# PDF Tool Supply-Chain Rule

Do not blindly execute a package suggested from memory.

Before running a CPX package:

1. verify the package exists
2. verify the exact package name
3. inspect its Packagist/repository metadata where tooling allows
4. confirm it is actively maintained or otherwise trustworthy
5. confirm the expected executable name
6. avoid suspicious typo-similar packages
7. prefer established packages with a clear upstream repository

This is especially important because CPX executes third-party Composer package code.

Do not undermine the security review itself by executing an unverified package.

---

# Preferred Conversion Strategy

Prefer, in order:

1. existing project/report tooling
2. an already-installed system PDF/document converter
3. a known and verified PHP package executed through CPX
4. another available trusted local conversion mechanism

Do not modify application runtime dependencies purely to produce the report.

Do not require the client application itself to expose a PDF-generation route.

The report generation process should occur locally or within the authorised development environment.

---

# Report Generation Isolation

Files created solely for the security assessment MUST NOT be committed to the client application unless explicitly requested.

Prefer a local-only ignore mechanism for:

```text
security-reports/
```

such as `.git/info/exclude` or an appropriate global Git ignore, rather than modifying the project's committed `.gitignore` solely for the audit.

Temporary PDF-generation packages, binaries, downloaded tools and caches must not become application dependencies or committed project files.

Before completion, run `git status --short` and verify the audit itself has not unintentionally introduced report artefacts, temporary tools or unrelated files into the application's tracked changes.

---

# Report Accuracy Validation

Before creating the final PDF, verify automatically where possible that:

- every finding has an ID
- every finding has a severity
- every finding has a status
- severity totals match the executive summary
- fixed findings describe verification
- critical/high findings reference regression tests where practical
- no placeholder text remains
- no known secrets are present
- no obviously sensitive values are present

Search the generated report for patterns resembling:

```text
BEGIN PRIVATE KEY
AWS_SECRET
AWS_ACCESS_KEY
Authorization: Bearer
password=
token=
secret=
SESSION=
STRIPE_SECRET
```

This search is a safety check only.

Do not print matched sensitive values to the terminal or report.

If a suspected secret is detected, redact it before PDF generation.

---

# Report Versioning

Record the exact Git state assessed.

Use:

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git status --short
```

Include:

```text
Branch:
Commit:
Working Tree:
```

If the working tree is dirty, explicitly state:

> The assessment was performed with uncommitted changes present.

Do not imply the report applies exactly to a production commit when it does not.

---

# Assessment Timestamp

Record:

```text
Assessment started:
Assessment completed:
Report generated:
```

Use an unambiguous timestamp including timezone where practical.

---

# Reassessment After Fixes

The final report should distinguish:

```text
Found
Fixed During Assessment
Open
Accepted Risk
Unable To Verify
```

Do NOT simply remove findings after fixing them.

A client-quality report should show that the issue:

1. existed
2. was identified
3. was remediated
4. was retested

This provides useful evidence of the review process.

---

# PDF Final Verification

After PDF generation verify:

```text
security-reports/security-pentest-report.pdf
```

exists and is non-empty.

Where PDF inspection tooling is available:

- confirm page count is greater than zero
- confirm the title is present
- confirm the executive summary is present
- confirm findings appear in the document
- confirm no conversion error page was generated

If PDF generation fails:

1. retain the Markdown report
2. diagnose the generation failure
3. try another trusted local conversion method
4. do not declare the security assessment complete until either:
   - the PDF is successfully produced, or
   - the environment genuinely prevents PDF creation and this limitation is explicitly reported

---

# Required Completion Outputs

A completed run MUST leave:

```text
security-reports/
├── security-pentest-findings.json
├── security-pentest-report.md
└── security-pentest-report.pdf
```

`security-pentest-findings.json` is the canonical structured record of findings.

`security-pentest-report.md` is the canonical human-readable report source.

`security-pentest-report.pdf` is the formal client deliverable.

Generate the Markdown report from the structured findings wherever practical rather than independently reconstructing finding counts and statuses.

The JSON output should contain structured finding data such as:

```json
{
  "summary": {
    "overall_risk": "HIGH",
    "pentest_readiness": "READY WITH KNOWN RISKS"
  },
  "findings": [
    {
      "id": "H-01",
      "severity": "HIGH",
      "status": "FIXED",
      "title": "Example vulnerability"
    }
  ]
}
```

This can be used to generate the summary tables automatically and reduces inconsistencies between the report and the findings.

---

# Final Deliverable Message

At completion explicitly report the paths:

```text
Security review complete.

Structured findings:
security-reports/security-pentest-findings.json

Markdown report:
security-reports/security-pentest-report.md

PDF report:
security-reports/security-pentest-report.pdf
```

Also state:

- overall risk
- pentest readiness
- number of open Critical findings
- number of open High findings
- whether the full test suite passed
- whether dependency audits passed

Do not bury open Critical or High risks inside the PDF only.

---

# Final Rule

Never state:

> "The application is secure."

Never state:

> "No vulnerabilities exist."

Instead:

> "No additional vulnerabilities were identified within the code, configuration, environments and attack paths tested."

Security is a point-in-time assessment.

The objective is to find serious weaknesses internally before an independent penetration tester finds them.
