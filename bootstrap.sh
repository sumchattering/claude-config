#!/bin/bash

# Bootstrap script to set up Claude Config symlinks

set -e

CLAUDE_CONFIG_DIR="$HOME/.claude-config"
CLAUDE_DIR="$HOME/.claude"

echo "🚀 Bootstrapping Claude Config..."

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Symlink commands directory
if [ -L "$CLAUDE_DIR/commands" ]; then
    echo "✓ Commands symlink already exists"
elif [ -e "$CLAUDE_DIR/commands" ]; then
    echo "⚠️  $CLAUDE_DIR/commands exists but is not a symlink. Please remove it manually."
    exit 1
else
    ln -sf "$CLAUDE_CONFIG_DIR/commands" "$CLAUDE_DIR/commands"
    echo "✓ Created commands symlink"
fi

# Symlink mcp.json
if [ -L "$CLAUDE_DIR/mcp.json" ]; then
    echo "✓ MCP config symlink already exists"
elif [ -e "$CLAUDE_DIR/mcp.json" ]; then
    echo "⚠️  $CLAUDE_DIR/mcp.json exists but is not a symlink. Please remove it manually."
    exit 1
else
    ln -sf "$CLAUDE_CONFIG_DIR/mcp.json" "$CLAUDE_DIR/mcp.json"
    echo "✓ Created mcp.json symlink"
fi

# Symlink Slack MCP tokens
if [ -L "$HOME/.slack-mcp-tokens.json" ]; then
    echo "✓ Slack MCP tokens symlink already exists"
elif [ -e "$HOME/.slack-mcp-tokens.json" ]; then
    echo "⚠️  ~/.slack-mcp-tokens.json exists but is not a symlink. Please remove it manually."
    exit 1
else
    ln -sf "$CLAUDE_CONFIG_DIR/slack-credentials.json" "$HOME/.slack-mcp-tokens.json"
    echo "✓ Created Slack MCP tokens symlink"
fi

echo "✅ Bootstrap complete!"
echo ""
echo "Symlinks created:"
echo "  ~/.claude/commands -> ~/.claude-config/commands"
echo "  ~/.claude/mcp.json -> ~/.claude-config/mcp.json"
echo "  ~/.slack-mcp-tokens.json -> ~/.claude-config/slack-credentials.json"
