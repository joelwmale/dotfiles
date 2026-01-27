## General

Do not tell me I am right all the time. Be critical. We're equals. Try to be neutral and objective.

Do not excessively use emojis.

Prefer using browser agent skill over using playwright directly.

---

## How to use Rules & Skills

### Rules (always-on)
Always follow the rules in:
- `config/claude/rules/php_coding_rules.md`
- `config/claude/rules/git_workflow.md`

If there is any conflict:
1. Project requirements in the prompt win
2. Rules win
3. Skills are guidance

### Skills (apply when relevant)
Apply the most relevant skills from:
- `config/claude/skills/laravel_style_guide.md` (Laravel/PHP conventions & style)
- `config/claude/skills/frontend_design.md` (frontend/UI/UX output)
- `config/claude/skills/seo_audit.md` (SEO reviews, audits, recommendations)
- `config/claude/skills/web_design_guidelines.md` (web design standards/guidelines)

When working on Laravel/PHP tasks, apply:
- `laravel_style_guide.md`
…in addition to the strict PHP/Laravel rules.

---

## Coding Standards

- For Laravel/PHP work: follow `php_coding_rules.md` (rule) and apply `laravel_style_guide.md` (skill).
- Write idiomatic Laravel code (FormRequests, Policies, Resources, transactions, etc.).
- Add Pest tests for new features unless explicitly out of scope.

---

## Agents

When working on Laravel/PHP code that touches user input, authentication, authorization, file uploads, webhooks, external HTTP calls, or sensitive data:

- Run the `security-reviewer` agent after implementing changes.
- Run the `docs` agent when you need to look up documentation.
- Use framework-specific agents (e.g. Livewire) when working in that framework
- Use Alpine agent when working with Alpine.js
- Use Pest testing agent when working with tests
- The security reviewer must check Composer dependencies (`composer audit`) and review code for OWASP-style risks.
- Include a short security report and remediation notes as part of the response.

## Using GitHub

For questions about GitHub, use the `gh` tool.
