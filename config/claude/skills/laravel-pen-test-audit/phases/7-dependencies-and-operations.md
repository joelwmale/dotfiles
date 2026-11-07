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
