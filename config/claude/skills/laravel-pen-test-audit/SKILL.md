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

Read this file first, then `WORKFLOW.md`. Everything else is reference material loaded per task
(see "Files" below). Do not read all the phase files yourself in one sitting; that is what the
slices are for.

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
  the repo, so code review alone cannot clear them. See `phases/7-dependencies-and-operations.md`
  (External Passive Validation).
- **Only confirmed findings get a severity.** Everything else is `needs_validation` or `rejected`,
  and hardening gaps go in their own section. See `WORKFLOW.md`.

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

# Files

| File | Read when |
|---|---|
| `WORKFLOW.md` | Always, straight after this file. The procedure: slices, hunters, refuters, coverage critic, verdicts. |
| `phases/1-recon.md` | Phase 0-2. Always, to build the architecture note and route inventory. |
| `phases/2-authentication.md` | Phase 3-8. Login, codes, reset, verification, passwords, sessions and cookies. |
| `phases/3-authorisation-and-livewire.md` | Phase 9-15. IDOR, tenancy, channels, type juggling, mass assignment, Livewire, Inertia. |
| `phases/4-files-and-browser.md` | Phase 16-23. Uploads, downloads, signed URLs, XSS, CSP, SRI, CSRF, headers. |
| `phases/5-crypto-secrets-config.md` | Phase 24-30. Crypto, randomness, secrets, PII, config, tooling, debug output. |
| `phases/6-integrations-and-logic.md` | Phase 31-37. API tokens, webhooks, SSRF, injection, redirects, business logic, races. |
| `phases/7-dependencies-and-operations.md` | Phase 38-47. Dependencies, support status, repo, deploy, logging, security.txt, live checks. |
| `REMEDIATE.md` | Only when fixing (not report-only): regression tests, verification, fix workflow. |
| `CHECKLIST.md` | At the end: the adversarial checklist and the severity scale. |
| `REPORT.md` | Writing the report. |
| `PDF.md` | Only when producing the PDF. |

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
