#!/bin/bash
#
# Standalone Claude Code installation script
# Can be run independently or as part of full dotfiles setup

set -e

# Determine the dotfiles root directory
# This works whether the script is run directly or sourced from bootstrap
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Calculate ROOT if not already set
if [ -z "$ROOT" ]; then
    # If ROOT isn't set, figure it out based on script location
    if [ -f "$SCRIPT_DIR/../helpers.sh" ]; then
        # We're in the scripts directory, go up one level
        ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    else
        # Assume current directory is the root
        ROOT="$(pwd)"
    fi
fi

# Save the ROOT we calculated before sourcing helpers (which might override it)
DOTFILES_ROOT="$ROOT"

# Load helpers if available (when run from bootstrap)
if [ -f "$DOTFILES_ROOT/helpers.sh" ]; then
    source "$DOTFILES_ROOT/helpers.sh"
fi

# Restore ROOT if helpers.sh overwrote it
ROOT="$DOTFILES_ROOT"

# Define helper functions for standalone use
# helpers.sh provides: ok, bot, running, action, warn, error, ask, say
# We need: step, success, warn (already in helpers.sh), error (already in helpers.sh)

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Define step and success (not in helpers.sh)
if ! type -t step >/dev/null 2>&1; then
    step() { echo ""; echo -e "${BLUE}➜${NC} $1"; }
fi

if ! type -t success >/dev/null 2>&1; then
    success() { echo -e "${GREEN}✓${NC} $1"; }
fi

# Define warn and error as fallbacks (if helpers.sh wasn't loaded)
if ! type -t warn >/dev/null 2>&1; then
    warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fi

if ! type -t error >/dev/null 2>&1; then
    error() { echo -e "${RED}✗${NC} $1"; exit 1; }
fi

echo ""
echo "Claude Code Installation"
echo "========================"
echo ""

# Install Claude Code
step "Installing Claude Code CLI"
if command -v claude &>/dev/null; then
    warn "Claude Code already installed"
else
    # Find Homebrew in standard locations
    BREW_PATH=""
    if command -v brew &>/dev/null; then
        BREW_PATH="brew"
    elif [ -x "/opt/homebrew/bin/brew" ]; then
        BREW_PATH="/opt/homebrew/bin/brew"
    elif [ -x "/usr/local/bin/brew" ]; then
        BREW_PATH="/usr/local/bin/brew"
    fi

    # Try Homebrew first (modern)
    if [ -n "$BREW_PATH" ]; then
        $BREW_PATH install --cask claude-code || warn "Claude Code installation failed"
    else
        # Fallback to curl installer
        warn "Homebrew not found, using curl installer"
        curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code installation failed"
    fi
fi
success "Claude Code processed"

# Claude configuration
if [ -d "$ROOT/config/claude" ]; then
    step "Setting up Claude Code configuration"
    mkdir -p ~/.claude

    # Symlink configuration files
    ln -sf "$ROOT/config/claude/CLAUDE.md" ~/.claude/CLAUDE.md
    ln -sf "$ROOT/config/claude/settings.json" ~/.claude/settings.json

    # Symlink entire rules directory if it exists
    if [ -d "$ROOT/config/claude/rules" ]; then
        rm -rf ~/.claude/rules
        ln -sf "$ROOT/config/claude/rules" ~/.claude/rules
    fi

    # Symlink entire skills directory if it exists
    if [ -d "$ROOT/config/claude/skills" ]; then
        rm -rf ~/.claude/skills
        ln -sf "$ROOT/config/claude/skills" ~/.claude/skills
    fi

    # Symlink entire agents directory if it exists
    if [ -d "$ROOT/config/claude/agents" ]; then
        rm -rf ~/.claude/agents
        ln -sf "$ROOT/config/claude/agents" ~/.claude/agents
    fi

    success "Claude Code configured"
else
    warn "Claude configuration directory not found at $ROOT/config/claude, skipping configuration"
fi

# Agent Skills (included in dotfiles)
# All skills are version-controlled in config/claude/skills/
# No need to install them - they're symlinked from the dotfiles repo

# Done
echo ""
success "Claude Code setup complete!"
echo ""
step "Next steps:"
echo "  • Start using: claude"
echo "  • Discover more skills: https://skills.sh"
echo ""
