## General

Do not tell me I am right all the time. Be critical. We're equals. Try to be neutral and objective.

Do not excessively use emojis.

Prefer using browser agent skill over using playwright directly.

Use hyphens (-) instead of em dashes (—) in all copy and content. Em dashes read as AI-generated.

---

## How to use Rules & Skills

### Rules (always-on)
Always follow the rules in:
- `config/claude/rules/php_coding_rules.md`
- `config/claude/rules/git_workflow.md`
- `config/claude/rules/review_policy.md`
- `config/claude/rules/testing_policy.md`
- `config/claude/rules/code_comments.md`

If there is any conflict:
1. Project requirements in the prompt win
2. Rules win
3. Skills are guidance

### Skills (apply when relevant)
Skills in `config/claude/skills/` are auto-discovered by name and description -
they do not need listing here. The house conventions are:

- `laravel-conventions` (Laravel/PHP naming, structure, Eloquent, testing)
- `livewire-conventions` (Livewire 3 components)
- `inertia-react-conventions` (React as the Laravel view layer, via Inertia)
- `react-native-conventions` (mobile)
- `tailwind-conventions` (Tailwind v4)
- `web-design-guidelines` (UI review against Web Interface Guidelines)
- `seo-audit` (SEO reviews and audits)

Apply the conventions skill for whatever stack the work touches, in addition to
the strict rules above. Rules win on any conflict.

---

## Coding Standards

- For Laravel/PHP work: follow `php_coding_rules.md` (rule) and apply `laravel-conventions` (skill).
- Write idiomatic Laravel code (FormRequests, Policies, Resources, transactions, etc.).
- Test proportionately per `testing_policy.md`. Test what can break silently;
  do not test copy changes, markup, config or one-off commands.

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

## Committing

When you have finished working on a request, commit the changes and push them to the remote repository.

Write a commit message that makes sense for the changes you have made. Always prefix the commit message with the type of change you have made, for example:

- feat: add new feature
- fix: fix bug
- refactor: refactor code
- docs: update documentation
- test: add tests
- chore: miscellaneous changes
- perf: performance improvements
- ci: continuous integration changes
- style: formatting changes
- build: build system changes
- revert: revert previous commit