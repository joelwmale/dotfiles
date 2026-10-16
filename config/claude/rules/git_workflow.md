# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

Note: Attribution disabled globally via ~/.claude/settings.json.

## Branches and Pushing

- Run `git branch --show-current` before the first commit. On `master`, `main` or `develop`,
  create a feature branch first unless the project's CLAUDE.md says to commit there.
- Start a branch from a fresh base: `git fetch`, then branch from `origin/<base>`. A stale local
  base silently reverts work that landed since.
- Push a feature branch when the work is finished. Push a long-lived branch only where the
  project's CLAUDE.md says that is the workflow, or when asked. A hotfix the user calls out is
  the user's override.
- Match the recent log's ticket prefix (`PX-1234 feat: ...`) when the repo uses one.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Push with `-u` flag if new branch

## Feature Implementation Workflow

1. **Testing**
   - Tier the change per `testing_policy.md` and say which tier
   - Tier 1 (auth, money, irreversible effects, security and bug fixes):
     test first - RED, GREEN, refactor
   - Tier 2: test in the same commit, after implementing
   - Tier 3 (copy, markup, one-off commands, config): no test
   - No coverage target

2. **Code Review**
   - Review per `review_policy.md`: tier the task, and always run one final review of the finished work and the code it touched before pushing, on the session's own model
   - Address CRITICAL and HIGH issues; fix MEDIUM issues when possible

3. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format