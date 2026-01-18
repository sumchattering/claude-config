#!/bin/bash

# Bootstrap script to set up Claude Config based on bootstrap-config.json

set -e

# Dynamically determine the directory where this script is located
CLAUDE_CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CONFIG_FILE="$CLAUDE_CONFIG_DIR/bootstrap-config.json"

echo "🚀 Bootstrapping Claude Config..."

# Check for jq (required for parsing JSON config)
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not found. Install it with: brew install jq"
    exit 1
fi

# Check config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# ============================================================================
# CCSTATUSLINE
# ============================================================================
echo ""
echo "📊 Setting up ccstatusline..."
if command -v ccstatusline &> /dev/null; then
    echo "  ✓ ccstatusline already installed"
else
    echo "  Installing ccstatusline..."
    npm install -g ccstatusline
    echo "  ✓ ccstatusline installed"
fi

# Symlink ccstatusline config
CCSTATUSLINE_CONFIG_DIR="$HOME/.config/ccstatusline"
mkdir -p "$CCSTATUSLINE_CONFIG_DIR"
rm -f "$CCSTATUSLINE_CONFIG_DIR/settings.json"
ln -sf "$CLAUDE_CONFIG_DIR/ccstatusline-settings.json" "$CCSTATUSLINE_CONFIG_DIR/settings.json"
echo "  ✓ ccstatusline config symlinked"

# Helper function to expand $HOME in paths
expand_path() {
    echo "${1//\$HOME/$HOME}"
}

# ============================================================================
# SETTINGS
# ============================================================================
echo ""
echo "🔧 Configuring Claude permissions..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CONFIG_SETTINGS="$CLAUDE_CONFIG_DIR/settings.json"

if [ -f "$CONFIG_SETTINGS" ]; then
    if [ -f "$SETTINGS_FILE" ]; then
        jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$CONFIG_SETTINGS" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "✓ Merged permissions into existing settings.json"
    else
        cp "$CONFIG_SETTINGS" "$SETTINGS_FILE"
        echo "✓ Created settings.json with Claude permissions"
    fi
else
    echo "⚠️  settings.json not found in config directory"
fi

# ============================================================================
# CREDENTIAL SYMLINKS
# ============================================================================
echo ""
echo "🔗 Setting up credential symlinks..."

# Slack credentials
if [ -f "$CLAUDE_CONFIG_DIR/slack-credentials.json" ]; then
    if [ -L "$HOME/.slack-mcp-tokens.json" ]; then
        echo "✓ Slack credentials symlink already exists"
    elif [ -e "$HOME/.slack-mcp-tokens.json" ]; then
        echo "⚠️  ~/.slack-mcp-tokens.json exists but is not a symlink"
    else
        ln -sf "$CLAUDE_CONFIG_DIR/slack-credentials.json" "$HOME/.slack-mcp-tokens.json"
        echo "✓ Created Slack credentials symlink"
    fi
else
    echo "- Slack credentials not found, skipping"
fi

# Jira credentials
if [ -f "$CLAUDE_CONFIG_DIR/jira-credentials.json" ]; then
    if [ -L "$HOME/.jira-mcp-credentials.json" ]; then
        echo "✓ Jira credentials symlink already exists"
    elif [ -e "$HOME/.jira-mcp-credentials.json" ]; then
        echo "⚠️  ~/.jira-mcp-credentials.json exists but is not a symlink"
    else
        ln -sf "$CLAUDE_CONFIG_DIR/jira-credentials.json" "$HOME/.jira-mcp-credentials.json"
        echo "✓ Created Jira credentials symlink"
    fi
else
    echo "- Jira credentials not found, skipping"
fi

# Iterable credentials
if [ -f "$CLAUDE_CONFIG_DIR/iterable-credentials.json" ]; then
    if [ -L "$HOME/.iterable-mcp-credentials.json" ]; then
        echo "✓ Iterable credentials symlink already exists"
    elif [ -e "$HOME/.iterable-mcp-credentials.json" ]; then
        echo "⚠️  ~/.iterable-mcp-credentials.json exists but is not a symlink"
    else
        ln -sf "$CLAUDE_CONFIG_DIR/iterable-credentials.json" "$HOME/.iterable-mcp-credentials.json"
        echo "✓ Created Iterable credentials symlink"
    fi
else
    echo "- Iterable credentials not found, skipping"
fi

# ============================================================================
# COMMANDS
# ============================================================================
echo ""
echo "📝 Setting up commands..."

# Global commands - symlink to ~/.claude/commands/
GLOBAL_COMMANDS_DIR="$CLAUDE_DIR/commands"
mkdir -p "$GLOBAL_COMMANDS_DIR"

# Remove existing symlinks in global commands dir (to refresh)
find "$GLOBAL_COMMANDS_DIR" -maxdepth 1 -type l -delete 2>/dev/null || true

# Symlink global commands
GLOBAL_COMMANDS=$(jq -r '.commands.global // [] | .[]' "$CONFIG_FILE")
for cmd in $GLOBAL_COMMANDS; do
    if [ -f "$CLAUDE_CONFIG_DIR/commands/$cmd" ]; then
        ln -sf "$CLAUDE_CONFIG_DIR/commands/$cmd" "$GLOBAL_COMMANDS_DIR/$cmd"
        echo "✓ Global command: $cmd"
    else
        echo "⚠️  Command not found: $cmd"
    fi
done

# Repository-specific commands
REPO_PATHS=$(jq -r '.commands.repositories // {} | keys[]' "$CONFIG_FILE")
for repo_path_raw in $REPO_PATHS; do
    repo_path=$(expand_path "$repo_path_raw")

    if [ ! -d "$repo_path" ]; then
        echo "⚠️  Skipping missing project: $repo_path"
        continue
    fi

    REPO_COMMANDS_DIR="$repo_path/.claude/commands"
    mkdir -p "$REPO_COMMANDS_DIR"

    # Remove existing symlinks (to refresh)
    find "$REPO_COMMANDS_DIR" -maxdepth 1 -type l -delete 2>/dev/null || true

    # Symlink repository-specific commands
    REPO_COMMANDS=$(jq -r --arg path "$repo_path_raw" '.commands.repositories[$path] // [] | .[]' "$CONFIG_FILE")
    for cmd in $REPO_COMMANDS; do
        if [ -f "$CLAUDE_CONFIG_DIR/commands/$cmd" ]; then
            ln -sf "$CLAUDE_CONFIG_DIR/commands/$cmd" "$REPO_COMMANDS_DIR/$cmd"
            echo "✓ $(basename "$repo_path"): $cmd"
        else
            echo "⚠️  Command not found: $cmd"
        fi
    done

    # Add .claude to .gitignore if not already there
    if [ -f "$repo_path/.gitignore" ]; then
        if ! grep -q "^\.claude/$" "$repo_path/.gitignore" 2>/dev/null; then
            echo ".claude/" >> "$repo_path/.gitignore"
        fi
    fi
done

# ============================================================================
# MCP SERVERS
# ============================================================================
echo ""
echo "📦 Setting up MCP servers..."

# Function to add or update MCP in global settings.json
add_mcp_to_global() {
    local mcp_name="$1"
    local mcp_json="$2"

    if [ -f "$SETTINGS_FILE" ]; then
        # Check if mcpServers key exists, if not create it
        if jq -e '.mcpServers' "$SETTINGS_FILE" > /dev/null 2>&1; then
            # Merge with existing mcpServers
            jq --arg name "$mcp_name" --argjson mcp "$mcp_json" \
                '.mcpServers[$name] = $mcp' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        else
            # Add mcpServers key
            jq --arg name "$mcp_name" --argjson mcp "$mcp_json" \
                '. + {mcpServers: {($name): $mcp}}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        fi
    else
        # Create new settings file with mcpServers
        echo "{\"mcpServers\": {\"$mcp_name\": $mcp_json}}" | jq '.' > "$SETTINGS_FILE"
    fi
}

# Function to add or update MCP in a repository's .mcp.json
add_mcp_to_repo() {
    local repo_path="$1"
    local mcp_name="$2"
    local mcp_json="$3"

    local mcp_file="$repo_path/.mcp.json"

    if [ -f "$mcp_file" ]; then
        # Merge with existing
        jq --arg name "$mcp_name" --argjson mcp "$mcp_json" \
            '.mcpServers[$name] = $mcp' "$mcp_file" > "$mcp_file.tmp" && mv "$mcp_file.tmp" "$mcp_file"
    else
        # Create new
        echo "{\"mcpServers\": {\"$mcp_name\": $mcp_json}}" | jq '.' > "$mcp_file"
    fi

    # Add .mcp.json to .gitignore if not already there
    if [ -f "$repo_path/.gitignore" ]; then
        if ! grep -q "^\.mcp\.json$" "$repo_path/.gitignore" 2>/dev/null; then
            echo ".mcp.json" >> "$repo_path/.gitignore"
        fi
    fi
}

# Get list of MCP server names
MCP_NAMES=$(jq -r '.mcpServers // {} | keys[]' "$CONFIG_FILE")

for mcp_name in $MCP_NAMES; do
    echo ""
    echo "  Setting up $mcp_name MCP..."

    # Get MCP config
    MCP_COMMAND=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].command' "$CONFIG_FILE")
    MCP_INSTALL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].install // ""' "$CONFIG_FILE")

    # Check if package is installed (skip for npx commands since they auto-install)
    if [ "$MCP_COMMAND" != "npx" ]; then
        if command -v "$MCP_COMMAND" &> /dev/null; then
            echo "    ✓ $MCP_COMMAND already installed"
        else
            echo "    ⚠️  $MCP_COMMAND not found"
            if [ -n "$MCP_INSTALL" ] && [ "$MCP_INSTALL" != "null" ]; then
                read -p "    Install with '$MCP_INSTALL'? [y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "    Installing $mcp_name..."
                    eval "$MCP_INSTALL"
                    if command -v "$MCP_COMMAND" &> /dev/null; then
                        echo "    ✓ $MCP_COMMAND installed successfully"
                    else
                        echo "    ❌ Installation failed. Please install manually: $MCP_INSTALL"
                    fi
                else
                    echo "    Skipped. Install manually with: $MCP_INSTALL"
                fi
            else
                echo "    No install command configured. Add 'install' field to config."
            fi
        fi
    else
        echo "    ✓ Uses npx (auto-installs on first run)"
    fi
    MCP_ARGS=$(jq -c --arg name "$mcp_name" '.mcpServers[$name].args // []' "$CONFIG_FILE")
    MCP_ENV_FILE_RAW=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].envFile // ""' "$CONFIG_FILE")
    MCP_GLOBAL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].global // false' "$CONFIG_FILE")
    MCP_REPOS=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].repositories // [] | .[]' "$CONFIG_FILE")

    # Build environment object
    ENV_OBJ="{}"

    # If envFile is specified, read env vars from that file
    if [ -n "$MCP_ENV_FILE_RAW" ] && [ "$MCP_ENV_FILE_RAW" != "null" ]; then
        ENV_FILE_PATH=$(expand_path "$MCP_ENV_FILE_RAW")
        if [ -f "$ENV_FILE_PATH" ]; then
            ENV_OBJ=$(cat "$ENV_FILE_PATH")
        fi
    fi

    # Merge inline env vars from config
    INLINE_ENV=$(jq -c --arg name "$mcp_name" '.mcpServers[$name].env // {}' "$CONFIG_FILE")
    # Expand $HOME in inline env values
    INLINE_ENV_EXPANDED=$(echo "$INLINE_ENV" | sed "s|\\\$HOME|$HOME|g")
    ENV_OBJ=$(echo "$ENV_OBJ" "$INLINE_ENV_EXPANDED" | jq -s 'add')

    # Build the MCP server JSON
    MCP_JSON=$(jq -n \
        --arg type "stdio" \
        --arg command "$MCP_COMMAND" \
        --argjson args "$MCP_ARGS" \
        --argjson env "$ENV_OBJ" \
        '{type: $type, command: $command, args: $args, env: $env}')

    # If global, add to ~/.claude/settings.json
    if [ "$MCP_GLOBAL" = "true" ]; then
        add_mcp_to_global "$mcp_name" "$MCP_JSON"
        echo "    ✓ Added $mcp_name globally to ~/.claude/settings.json"
    fi

    # Install MCP in each repository
    for repo_path_raw in $MCP_REPOS; do
        repo_path=$(expand_path "$repo_path_raw")

        if [ ! -d "$repo_path" ]; then
            echo "    ⚠️  Skipping missing project: $repo_path"
            continue
        fi

        add_mcp_to_repo "$repo_path" "$mcp_name" "$MCP_JSON"
        echo "    ✓ Added $mcp_name to $(basename "$repo_path")"
    done
done

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Configuration loaded from: $CONFIG_FILE"
