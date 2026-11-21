# Dotfiles

Scripts and config to set up a Mac for Laravel and PHP development. Review before running: it changes system settings and installs software.

## Quick start

```bash
git clone git@github.com:joelwmale/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
./bootstrap
```

`bootstrap` shows a checklist of steps. Each step then asks about its own choices, so nothing is installed or changed without a yes.

| Flag | Effect |
|---|---|
| `--dry-run` | Print every command, change nothing |
| `--yes` | Accept every default without asking |
| `--only packages,dock` | Run just these steps |
| `--list` | List the steps |

Steps: `system`, `defaults`, `shell`, `git`, `packages`, `dev`, `claude`, `repos`, `dock`. Each is also a script in `scripts/` you can run on its own.

## Packages

Homebrew tools, casks and Mac App Store apps are listed in `config/packages/*.list`, one per line as `name|group|default|description`. The installer shows the groups, lets you toggle them, and can review item by item. Groups with default `0` are suggestions and stay off until you pick them.

To add or remove a package, edit the list.

## Local files

Personal details are never committed. These files live on the machine and are gitignored or outside the repo:

| File | Holds | Written by |
|---|---|---|
| `~/.gitconfig.local` | Git name, email, signing key | `scripts/git.sh` |
| `~/.zshrc.local` | Machine-specific shell config | you |
| `~/.config/dotfiles/repos` | Repositories to clone, one `owner/repo` per line | `scripts/clone.sh` |

## What is configured

- **Shell**: zsh, oh-my-zsh, Spaceship prompt, fzf, zoxide, eza, bat. Config is symlinked from `dotfiles/`; anything already there is moved to `~/.dotfiles-backup/`.
- **Terminal**: Ghostty, config in `config/ghostty/`.
- **Languages**: PHP, Composer and Node via Herd and nvm.
- **macOS**: keyboard, Finder, Dock, screenshots and privacy defaults in `scripts/defaults.sh`, grouped so you can skip any.
- **Claude Code**: rules, skills and settings in `config/claude/`, symlinked into `~/.claude`.
- **CLI**: `cli/displays` (BetterDisplay layouts) and `cli/ghboard` (GitHub status dashboard).

## Updating

```bash
brew update && brew upgrade
```

## Third-party

Some Claude skills are copied from MIT-licensed repositories. Notices are in `config/claude/skills/THIRD_PARTY_LICENSES.md`.
