# ghboard — Design Spec

**Date:** 2026-05-27
**Status:** Approved

## Overview

`ghboard` is a PHP-TUI terminal dashboard for monitoring GitHub repository health across a digital agency's client portfolio. It displays CI/Actions status, Dependabot alerts (by severity), open PRs, and open issues in a scrollable table — one row per repo.

## Goals

- Quick at-a-glance health check across 30+ client repos
- Works left running in a terminal (auto-refresh) or as a quick snapshot
- Zero friction to ignore noise repos from the TUI itself
- Opens any repo in GitHub with a single keypress

## Non-Goals

- Does not write to GitHub (no closing issues, merging PRs, etc.)
- Does not manage secrets or GitHub tokens (delegates to `gh` CLI)
- Does not support non-GitHub remotes

---

## Architecture

### Language & Framework

- **PHP 8.2+** via Laravel Herd (already installed)
- **[php-tui/php-tui](https://php-tui.github.io/php-tui/)** for terminal rendering, layout, keyboard events, and tick loop
- **`gh` CLI** via `proc_open` subprocess calls for all GitHub data

### File Location

```
dotfiles/
  cli/
    ghboard          ← executable PHP script (chmod +x, shebang #!/usr/bin/env php)
```

Symlinked to `/usr/local/bin/ghboard` during dotfiles bootstrap.

### Config File

`~/.ghboard.json` — created automatically on first run with defaults.

```json
{
  "ignored": [],
  "refresh_interval": 60,
  "base_dir": "~/Code"
}
```

| Field              | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| `ignored`          | Array of repo names to exclude from the dashboard                  |
| `refresh_interval` | Seconds between auto-refreshes (default: 60)                       |
| `base_dir`         | Directory scanned for repos in multi-repo mode (default: `~/Code`) |

---

## Entry Modes

### Multi-repo mode (default)

Run `ghboard` from any directory that is not itself a git repo. Scans `base_dir` for subdirectories that contain a `.git` folder and have a GitHub remote. Excludes repos in the `ignored` list.

### Single-repo mode

Run `ghboard` from inside a git repo directory (or any subdirectory within one). Detected via `git rev-parse --show-toplevel` — if it succeeds, single-repo mode activates using that repo root. Shows only that repo in the table (same UI, one row). Useful for focusing on a project mid-work.

---

## UI Layout

```
▶ ghboard  ·  32 repos tracked                    last refresh: 18s ago · [r] refresh [i] ignore [q] quit

 REPO              WORKFLOWS                        DEPENDABOT              PRS    ISSUES
──────────────────────────────────────────────────────────────────────────────────────────────────
▶ pixel            ✓ CI  ⟳ Tests  ✓ Deploy         ● 2 crit  ● 1 high      2      5
  rethread         ✓ CI  ✗ Deploy                  —                        0      1
  dotfiles         ✓ Lint                           —                        0      0
  client-invoicing ✓ CI  ✓ Tests  ✓ Deploy         ● 1 high                 1      0
  marketing-site   ✓ CI                             —                        0      0
  ...

  ↕ j/k to scroll · [enter] open in GitHub · auto-refresh in 42s
```

### Columns

| Column     | Content                                                                                           |
| ---------- | ------------------------------------------------------------------------------------------------- |
| REPO       | Repo name. Highlighted with cursor indicator when selected.                                       |
| WORKFLOWS  | Each workflow as a named badge with status icon. Multiple workflows shown inline.                 |
| DEPENDABOT | Severity counts for open alerts. Only critical/high/medium shown (low omitted). `—` if no alerts. |
| PRS        | Open PR count. Dimmed if zero.                                                                    |
| ISSUES     | Open issue count. Dimmed if zero.                                                                 |

### Status Icons

| Icon | Colour | Meaning                           |
| ---- | ------ | --------------------------------- |
| `✓`  | Green  | Last run passed                   |
| `⟳`  | Yellow | Currently running                 |
| `✗`  | Red    | Last run failed                   |
| `—`  | Dim    | No data (no workflows, no alerts) |

### Dependabot Severity Colours

| Severity | Colour    |
| -------- | --------- |
| critical | Red       |
| high     | Yellow    |
| medium   | Dim white |
| low      | Omitted   |

---

## Keyboard Bindings

| Key            | Action                                                                    |
| -------------- | ------------------------------------------------------------------------- |
| `j` / `↓`      | Move selection down                                                       |
| `k` / `↑`      | Move selection up                                                         |
| `r`            | Force refresh immediately                                                 |
| `i`            | Add selected repo to `ignored` in `~/.ghboard.json` and remove from table |
| `Enter`        | Open selected repo in browser via `gh repo view --web`                    |
| `q` / `Ctrl-C` | Quit                                                                      |

---

## Data Fetching

All data is fetched via `gh` CLI subprocesses. This means no API token management — `gh auth` handles it.

### Calls per repo

| Data              | Command                                                                  |
| ----------------- | ------------------------------------------------------------------------ |
| Workflow runs     | `gh run list --repo owner/repo --limit 10 --json name,status,conclusion` |
| Dependabot alerts | `gh api repos/owner/repo/dependabot/alerts?state=open&per_page=100`      |
| Open PRs          | `gh pr list --repo owner/repo --state open --json number`                |
| Open issues       | `gh issue list --repo owner/repo --state open --json number`             |
| Repo remote       | `git remote get-url origin` (to resolve owner/repo from local path)      |

### Workflow deduplication

Only the most recent run per workflow name is shown. If "CI" ran 3 times, only the latest appears as a badge.

### Polling

PHP-TUI's tick loop fires every ~100ms. A frame counter tracks elapsed time. When elapsed seconds >= `refresh_interval`, all `gh` calls fire sequentially via `proc_open`, results are merged into application state, and the table re-renders. A "last refresh" timestamp in the header updates after each cycle.

On first launch, data loads immediately before the first render. With 30+ repos (4 `gh` calls each), the initial load and each refresh cycle may take 15-30 seconds. The header shows a `refreshing...` indicator during the cycle, and the table retains stale data until the new fetch completes so the UI never goes blank.

---

## Config Management

`~/.ghboard.json` is read on startup and written when the user presses `i` to ignore a repo. The ignore write:

1. Reads current config from disk
2. Appends the repo name to `ignored`
3. Writes back atomically (write to temp file, rename)
4. Removes the repo from in-memory state
5. Re-renders the table immediately

---

## Repo Discovery (Multi-repo Mode)

1. Expand `base_dir` (resolves `~`)
2. List immediate subdirectories
3. Filter: must contain `.git/`
4. Filter: must have a GitHub remote (`git remote get-url origin` contains `github.com`)
5. Filter: name not in `ignored`
6. Sort: alphabetically (failures float to top in future enhancement)

---

## Bootstrap Integration

The dotfiles `scripts/install.sh` will need two additions:

1. Install `php-tui/php-tui` globally via Composer: `composer global require php-tui/php-tui`
2. Symlink `cli/ghboard` → `/usr/local/bin/ghboard`

`~/.ghboard.json` is created automatically by `ghboard` itself on first run — no bootstrap step needed.

---

## Out of Scope (v1)

- Sorting/filtering within the TUI (future: sort by failure, filter by name)
- Notification alerts (future: desktop notification when a run fails)
- Non-GitHub remotes (GitLab, Bitbucket)
- PR/issue detail view
- Branch protection status
