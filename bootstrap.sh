#!/bin/bash

# Bootstrap script to set up Claude Config symlinks and MCP servers

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

# Symlink Slack MCP tokens
if [ -L "$HOME/.slack-mcp-tokens.json" ]; then
    echo "✓ Slack MCP tokens symlink already exists"
elif [ -e "$HOME/.slack-mcp-tokens.json" ]; then
    echo "⚠️  ~/.slack-mcp-tokens.json exists but is not a symlink. Please remove it manually."
    exit 1
else
    if [ -f "$CLAUDE_CONFIG_DIR/slack-credentials.json" ]; then
        ln -sf "$CLAUDE_CONFIG_DIR/slack-credentials.json" "$HOME/.slack-mcp-tokens.json"
        echo "✓ Created Slack MCP tokens symlink"
    else
        echo "⚠️  slack-credentials.json not found, skipping Slack credentials symlink"
    fi
fi

# Install MCP servers via claude mcp add
echo ""
echo "📦 Installing MCP servers..."

# Check if slack-mcp-server is installed
if ! command -v slack-mcp-server &> /dev/null; then
    echo "⚠️  slack-mcp-server not found. Install it with: npm install -g @teamsparta/mcp-server-slack"
else
    # Add Slack MCP server
    if claude mcp list 2>/dev/null | grep -q "slack:"; then
        echo "✓ Slack MCP server already configured"
    else
        claude mcp add slack slack-mcp-server -e SLACK_TOKEN_FILE="$HOME/.slack-mcp-tokens.json"
        echo "✓ Added Slack MCP server"
    fi
fi

# Add Jira MCP server
if claude mcp list 2>/dev/null | grep -q "jira:"; then
    echo "✓ Jira MCP server already configured"
else
    claude mcp add jira -- npx -y mcp-jira-stdio
    echo "✓ Added Jira MCP server"
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Symlinks created:"
echo "  ~/.claude/commands -> ~/.claude-config/commands"
echo "  ~/.slack-mcp-tokens.json -> ~/.claude-config/slack-credentials.json"
echo ""
echo "MCP servers installed:"
claude mcp list
