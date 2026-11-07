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
