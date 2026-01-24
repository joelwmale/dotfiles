#!/bin/bash
#
# Standalone Claude Code installation script
# Can be run independently or as part of full dotfiles setup

set -e

# Load helpers if available (when run from bootstrap)
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"
fi

# Set ROOT if not already set (from helpers.sh)
if [ -z "$ROOT" ]; then
    ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo "Claude Code Installation"
echo "========================"
echo ""

# Install Claude Code
step "Installing Claude Code CLI"
if command -v claude &>/dev/null; then
    warn "Claude Code already installed"
else
    # Try Homebrew first (modern)
    if command -v brew &>/dev/null; then
        brew install --cask claude-code || warn "Claude Code installation failed"
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
    ln -sf "$ROOT/config/claude/laravel-php-guidelines.md" ~/.claude/laravel-php-guidelines.md
    ln -sf "$ROOT/config/claude/settings.json" ~/.claude/settings.json

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
