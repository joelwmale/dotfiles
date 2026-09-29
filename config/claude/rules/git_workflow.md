# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

Note: Attribution disabled globally via ~/.claude/settings.json.

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
   - Review per `review_policy.md`: tier the task, and always run a whole-branch review before pushing
   - Address CRITICAL and HIGH issues; fix MEDIUM issues when possible

3. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format