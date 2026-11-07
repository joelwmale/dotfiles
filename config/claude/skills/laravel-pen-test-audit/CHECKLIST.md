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
