---
name: github-issues
description: Fetch and format open GitHub issues for the current repository as a compact one-line-per-issue list. Use when asked to list, review, triage or summarise open issues.
---

# GitHub Issues

Fetch open issues for the current repo and present them compactly.

## Command

```bash
gh issue list --state open --limit 200 \
  --json number,title,state,body \
  --jq '.[] | "#\(.number) | \(.title) | \(.state) | \((.body // "" | gsub("[\r\n]+";" ") | .[0:200]))"'
```

## Output

- One issue per line
- Format exactly: `#<number> | <title> | <state> | <description>`
- Description is the first 200 characters of the body, newlines collapsed to
  spaces. If the body is empty, leave the field empty.

## Notes

- Raise `--limit` only when the repo genuinely has more than 200 open issues;
  the output is meant to stay scannable
- Add `--label` or `--assignee` filters when the user asks for a subset rather
  than filtering the output afterwards
