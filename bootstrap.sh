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

# Symlink Jira credentials
if [ -L "$HOME/.jira-mcp-credentials.json" ]; then
    echo "✓ Jira MCP credentials symlink already exists"
elif [ -e "$HOME/.jira-mcp-credentials.json" ]; then
    echo "⚠️  ~/.jira-mcp-credentials.json exists but is not a symlink. Please remove it manually."
    exit 1
else
    if [ -f "$CLAUDE_CONFIG_DIR/jira-credentials.json" ]; then
        ln -sf "$CLAUDE_CONFIG_DIR/jira-credentials.json" "$HOME/.jira-mcp-credentials.json"
        echo "✓ Created Jira MCP credentials symlink"
    else
        echo "⚠️  jira-credentials.json not found, skipping Jira credentials symlink"
    fi
fi

# Symlink Slab credentials
if [ -L "$HOME/.slab-mcp-credentials.json" ]; then
    echo "✓ Slab MCP credentials symlink already exists"
elif [ -e "$HOME/.slab-mcp-credentials.json" ]; then
    echo "⚠️  ~/.slab-mcp-credentials.json exists but is not a symlink. Please remove it manually."
    exit 1
else
    if [ -f "$CLAUDE_CONFIG_DIR/slab-credentials.json" ]; then
        ln -sf "$CLAUDE_CONFIG_DIR/slab-credentials.json" "$HOME/.slab-mcp-credentials.json"
        echo "✓ Created Slab MCP credentials symlink"
    else
        echo "⚠️  slab-credentials.json not found, skipping Slab credentials symlink"
    fi
fi

# Install MCP servers via claude mcp add (system-wide with --scope user)
echo ""
echo "📦 Installing MCP servers (system-wide)..."

# Check if slack-mcp-server is installed
if ! command -v slack-mcp-server &> /dev/null; then
    echo "⚠️  slack-mcp-server not found. Install it with: npm install -g @teamsparta/mcp-server-slack"
else
    # Add Slack MCP server
    if claude mcp list 2>/dev/null | grep -q "slack:"; then
        echo "✓ Slack MCP server already configured"
    else
        claude mcp add --scope user slack slack-mcp-server -e SLACK_TOKEN_FILE="$HOME/.slack-mcp-tokens.json"
        echo "✓ Added Slack MCP server"
    fi
fi

# Add Jira MCP server with credentials if available
if claude mcp list 2>/dev/null | grep -q "jira:"; then
    echo "✓ Jira MCP server already configured"
else
    if [ -f "$HOME/.jira-mcp-credentials.json" ]; then
        # Read credentials from JSON file
        JIRA_BASE_URL=$(grep -o '"JIRA_BASE_URL"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.jira-mcp-credentials.json" | sed 's/.*: "\(.*\)"/\1/')
        JIRA_EMAIL=$(grep -o '"JIRA_EMAIL"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.jira-mcp-credentials.json" | sed 's/.*: "\(.*\)"/\1/')
        JIRA_API_TOKEN=$(grep -o '"JIRA_API_TOKEN"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.jira-mcp-credentials.json" | sed 's/.*: "\(.*\)"/\1/')
        
        # Only add with credentials if they are not placeholder values
        if [[ "$JIRA_BASE_URL" != "https://your-domain.atlassian.net" && "$JIRA_EMAIL" != "your-email@example.com" && -n "$JIRA_API_TOKEN" ]]; then
            claude mcp add --scope user jira -e JIRA_BASE_URL="$JIRA_BASE_URL" -e JIRA_EMAIL="$JIRA_EMAIL" -e JIRA_API_TOKEN="$JIRA_API_TOKEN" -- npx -y mcp-jira-stdio
            echo "✓ Added Jira MCP server with credentials"
        else
            claude mcp add --scope user jira -- npx -y mcp-jira-stdio
            echo "⚠️  Added Jira MCP server without credentials (update jira-credentials.json and re-run)"
        fi
    else
        claude mcp add --scope user jira -- npx -y mcp-jira-stdio
        echo "✓ Added Jira MCP server (no credentials configured)"
    fi
fi

# Add Slab MCP server with credentials if available
if claude mcp list 2>/dev/null | grep -q "slab:"; then
    echo "✓ Slab MCP server already configured"
else
    if [ -f "$HOME/.slab-mcp-credentials.json" ]; then
        # Read credentials from JSON file
        SLAB_API_TOKEN=$(grep -o '"SLAB_API_TOKEN"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.slab-mcp-credentials.json" | sed 's/.*: "\(.*\)"/\1/')
        
        # Only add with credentials if they are not placeholder values
        if [[ "$SLAB_API_TOKEN" != "your-slab-api-token-here" && -n "$SLAB_API_TOKEN" ]]; then
            claude mcp add --scope user --transport sse slab http://kagent-mcp.stg-itbl.co/slab -H "Authorization: Bearer $SLAB_API_TOKEN"
            echo "✓ Added Slab MCP server with credentials"
        else
            claude mcp add --scope user --transport sse slab http://kagent-mcp.stg-itbl.co/slab
            echo "⚠️  Added Slab MCP server without credentials (update slab-credentials.json and re-run)"
        fi
    else
        claude mcp add --scope user --transport sse slab http://kagent-mcp.stg-itbl.co/slab
        echo "✓ Added Slab MCP server (no credentials configured)"
    fi
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Symlinks created:"
echo "  ~/.claude/commands -> ~/.claude-config/commands"
echo "  ~/.slack-mcp-tokens.json -> ~/.claude-config/slack-credentials.json"
if [ -L "$HOME/.jira-mcp-credentials.json" ]; then
    echo "  ~/.jira-mcp-credentials.json -> ~/.claude-config/jira-credentials.json"
fi
if [ -L "$HOME/.slab-mcp-credentials.json" ]; then
    echo "  ~/.slab-mcp-credentials.json -> ~/.claude-config/slab-credentials.json"
fi
echo ""
echo "MCP servers installed (system-wide):"
claude mcp list
