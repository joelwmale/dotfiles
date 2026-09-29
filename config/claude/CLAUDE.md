## General

Do not tell me I am right all the time. Be critical. We're equals. Be neutral and objective.

Do not excessively use emojis.

Prefer the claude-in-chrome skill over calling the Playwright MCP tools directly.

Use hyphens (-) instead of em dashes (—) in all copy and content. Em dashes read as AI-generated.

---

## How to use Rules & Skills

### Rules (always-on)
Always follow the rules in:
- `~/.claude/rules/php_coding_rules.md`
- `~/.claude/rules/git_workflow.md`
- `~/.claude/rules/review_policy.md`
- `~/.claude/rules/testing_policy.md`
- `~/.claude/rules/code_comments.md`

If there is any conflict:
1. Project requirements in the prompt win
2. Rules win
3. Skills are guidance

Personal skills here win over framework-shipped guidance (Laravel Boost, plugin skills)
where they disagree.

### Skills (apply when relevant)
Skills in `~/.claude/skills/` are auto-discovered by name and description -
they do not need listing here. The house conventions are:

- `laravel-conventions` (Laravel/PHP naming, structure, Eloquent, testing)
- `livewire-conventions` (Livewire components; v4, with v3 differences flagged)
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

When Laravel/PHP changes touch user input, authentication, authorization, file uploads,
webhooks, external HTTP calls, or sensitive data, run the `security-reviewer` agent
afterwards. It checks `composer audit` and OWASP-style risks; include its short report and
remediation notes in your response.

The `docs`, `livewire`, `alpine` and `pest` agents are available for documentation
lookups and framework-specific work.

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