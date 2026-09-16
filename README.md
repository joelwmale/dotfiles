# 🚀 Dotfiles

Personal dotfiles and scripts to configure a fresh Mac for Laravel/PHP development.

**Warning**: This will modify system settings and install applications. Review before running.

## ✨ Quick Start

```bash
git clone git@github.com:joelwmale/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
./bootstrap
```

The bootstrap script runs three main components:
- `scripts/install.sh` - Installs applications and tools
- `scripts/defaults.sh` - Configures macOS system preferences
- `scripts/dock.sh` - Sets up your Dock

## 📦 What's Installed

### Development Tools
- **Languages**: PHP (Herd), Node.js (NVM), Go, Python
- **Databases**: MySQL 8.0, Redis
- **Version Control**: Git, GitHub CLI, Fork (GUI), Lazygit (TUI)
- **Laravel**: Composer, Laravel Installer

### Terminal Setup
- **Ghostty** - Fast, GPU-accelerated terminal with split panes
- **Oh My Zsh** - Zsh framework with Spaceship theme
- **Productivity Tools**: fzf, zoxide, eza, fd, ripgrep, bat, yazi, tmux
- **Font**: JetBrains Mono Nerd Font

### Applications
- **Browsers**: Brave
- **Development**: Cursor (VS Code fork), Hyper, Warp
- **Productivity**: Alfred, Rectangle, Things, Fantastical, 1Password
- **Communication**: Slack, Discord, Telegram
- **Media**: Spotify
- **Utilities**: Setapp, BetterTouchTool, DaisyDisk, Google Drive, Dropbox

### CLI Utilities
- **File Operations**: eza (modern ls), fd (fast find), ripgrep (fast grep), bat (better cat)
- **Navigation**: zoxide (smart cd), fzf (fuzzy finder)
- **Git**: git-delta (beautiful diffs), lazygit (TUI), diff-so-fancy
- **Development**: jq, httpie, wget, tree, ncdu, htop
- **Cloud**: AWS CLI, DigitalOcean CLI

## 🎯 Key Features

### Terminal Shortcuts (fzf)
- `Ctrl+R` - Search command history
- `Ctrl+P` - Search files (like VS Code)
- `Ctrl+G` - Jump to directory

### Custom Shell Functions
- `p` - Run Pest/PHPUnit tests
- `gss` - Switch between projects
- `gho` - Open current repo in browser
- `commit [message]` - Smart git commit (generates message if empty)
- `release` - Create GitHub release with auto-generated notes
- `db` - Open Laravel .env database in GUI
- `tc` - Create/run test command

### Ghostty Terminal
- `Cmd+D` - Split pane right
- `Cmd+Shift+D` - Split pane down
- `Cmd+T` - New tab
- `Cmd+1-9` - Jump to tab
- `Cmd+K` - Clear screen
- `Cmd+F` - Search scrollback

### Navigation Tools
- `z [partial]` - Jump to directory (zoxide)
- `ll` - Beautiful ls with git status (eza)
- `lg` - Launch lazygit

## 🔧 Manual Installs Required

After bootstrap completes, manually install:

### Setapp Applications
Sign into Setapp, then install:
- CleanShot X, ForkLift, iStat Menus, Paste, PixelSnap, Session, TablePlus

### Purchased Software
- Affinity Designer/Photo/Publisher 2
- DaVinci Resolve
- Aseprite

## ⚙️ macOS Defaults Applied

The `defaults.sh` script configures:
- **Finder**: Show hidden files, extensions, path bar, disable warnings
- **Dock**: Auto-hide, no bouncing, hide recents, faster animations
- **Keyboard**: Fast key repeat, disable auto-correct/smart quotes
- **Screenshots**: Save to ~/Screenshots as PNG without shadow
- **Trackpad**: Disable natural scrolling, enable right-click
- **Performance**: Disable animations, faster window resize
- **Developer**: Show full paths, disable .DS_Store on network drives
- **Privacy**: Disable Siri, Handoff, Spotlight web search

## 📁 Directory Structure

```
~/Code/              # All projects
~/Code/cli/          # Custom CLI scripts
~/Screenshots/       # Screenshot location
~/.config/ghostty/   # Ghostty config
~/.config/claude/    # Claude Code config
```

## 🔄 Updates

To update installed tools:
```bash
brew update && brew upgrade
composer global update
npm update -g
```

## 📝 Customization

Key files to customize:
- `dotfiles/shell/.functions` - Shell functions
- `dotfiles/vendor/.zshrc` - Zsh configuration
- `config/ghostty/config` - Terminal settings
- `scripts/dock.sh` - Dock applications