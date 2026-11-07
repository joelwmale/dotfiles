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
