#!/bin/bash

# Bootstrap script to set up Claude Config based on bootstrap-config.json

set -e

# ============================================================================
# COLORS (using tput for terminal portability)
# ============================================================================
if [ -t 1 ] && command -v tput &> /dev/null && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD=$(tput bold)
    DIM=$(tput dim)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    RESET=$(tput sgr0)
else
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    RESET=""
fi

# Dynamically determine the directory where this script is located
CLAUDE_CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CONFIG_FILE="$CLAUDE_CONFIG_DIR/bootstrap-config.json"

echo "${BOLD}${BLUE}Bootstrapping Claude Config...${RESET}"

# Check for jq (required for parsing JSON config)
if ! command -v jq &> /dev/null; then
    echo "${RED}jq is required but not found. Install it with: brew install jq${RESET}"
    exit 1
fi

# Check config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "${RED}Config file not found: $CONFIG_FILE${RESET}"
    exit 1
fi

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# ============================================================================
# UPDATE CLAUDE CODE
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Updating Claude Code...${RESET}"
if command -v claude &> /dev/null; then
    CURRENT_VERSION=$(claude --version 2>/dev/null | head -1)
    echo "  ${DIM}Current version: $CURRENT_VERSION${RESET}"
    claude update 2>&1 | tail -3
    NEW_VERSION=$(claude --version 2>/dev/null | head -1)
    if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
        echo "  ${GREEN}✓ Claude Code is already up to date ($NEW_VERSION)${RESET}"
    else
        echo "  ${GREEN}✓ Claude Code updated to $NEW_VERSION${RESET}"
    fi
else
    echo "  ${YELLOW}⚠️  Claude Code not found. Install it:${RESET}"
    echo "    ${DIM}curl -fsSL https://cli.anthropic.com/install.sh | sh${RESET}"
fi

# ============================================================================
# CCSTATUSLINE
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Setting up ccstatusline...${RESET}"
if command -v ccstatusline &> /dev/null; then
    echo "  ${GREEN}✓ ccstatusline already installed${RESET}"
else
    echo "  ${DIM}Installing ccstatusline...${RESET}"
    npm install -g ccstatusline
    echo "  ${GREEN}✓ ccstatusline installed${RESET}"
fi

# Symlink ccstatusline config
CCSTATUSLINE_CONFIG_DIR="$HOME/.config/ccstatusline"
mkdir -p "$CCSTATUSLINE_CONFIG_DIR"
rm -f "$CCSTATUSLINE_CONFIG_DIR/settings.json"
ln -sf "$CLAUDE_CONFIG_DIR/ccstatusline-settings.json" "$CCSTATUSLINE_CONFIG_DIR/settings.json"
echo "  ${GREEN}✓ ccstatusline config symlinked${RESET}"

# Helper function to expand $HOME in paths
expand_path() {
    echo "${1//\$HOME/$HOME}"
}

# ============================================================================
# SETTINGS
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Configuring Claude permissions...${RESET}"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CONFIG_SETTINGS="$CLAUDE_CONFIG_DIR/settings.json"

if [ -f "$CONFIG_SETTINGS" ]; then
    if [ -f "$SETTINGS_FILE" ]; then
        jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$CONFIG_SETTINGS" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "  ${GREEN}✓ Merged permissions into existing settings.json${RESET}"
    else
        cp "$CONFIG_SETTINGS" "$SETTINGS_FILE"
        echo "  ${GREEN}✓ Created settings.json with Claude permissions${RESET}"
    fi
else
    echo "  ${YELLOW}⚠️  settings.json not found in config directory${RESET}"
fi

# ============================================================================
# HOOKS
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Setting up hooks...${RESET}"
HOOKS_DIR="$CLAUDE_CONFIG_DIR/hooks"

if [ -d "$HOOKS_DIR" ]; then
    # Copy hooks to global ~/.claude/hooks/
    GLOBAL_HOOKS_DIR="$CLAUDE_DIR/hooks"
    mkdir -p "$GLOBAL_HOOKS_DIR"
    cp -r "$HOOKS_DIR"/* "$GLOBAL_HOOKS_DIR/" 2>/dev/null || true
    echo "  ${GREEN}✓ Hooks copied to ~/.claude/hooks/${RESET}"
else
    echo "  ${DIM}- No hooks directory found, skipping${RESET}"
fi

# ============================================================================
# CREDENTIAL SYMLINKS
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Setting up credential symlinks...${RESET}"

# Helper function to create or fix credential symlinks
# Handles broken symlinks by recreating them
setup_credential_symlink() {
    local source_file="$1"
    local target_path="$2"
    local name="$3"

    if [ ! -f "$source_file" ]; then
        echo "  ${DIM}- $name credentials not found, skipping${RESET}"
        return
    fi

    # Check if symlink exists and is valid
    if [ -L "$target_path" ]; then
        if [ -e "$target_path" ]; then
            echo "  ${GREEN}✓ $name credentials symlink already exists${RESET}"
        else
            # Broken symlink - remove and recreate
            rm "$target_path"
            ln -sf "$source_file" "$target_path"
            echo "  ${GREEN}✓ Fixed broken $name credentials symlink${RESET}"
        fi
    elif [ -e "$target_path" ]; then
        echo "  ${YELLOW}⚠️  $target_path exists but is not a symlink${RESET}"
    else
        ln -sf "$source_file" "$target_path"
        echo "  ${GREEN}✓ Created $name credentials symlink${RESET}"
    fi
}

setup_credential_symlink "$CLAUDE_CONFIG_DIR/slack-credentials.json" "$HOME/.slack-mcp-tokens.json" "Slack"
setup_credential_symlink "$CLAUDE_CONFIG_DIR/jira-credentials.json" "$HOME/.jira-mcp-credentials.json" "Jira"
setup_credential_symlink "$CLAUDE_CONFIG_DIR/iterable-credentials.json" "$HOME/.iterable-mcp-credentials.json" "Iterable"

# ============================================================================
# COMMANDS
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Setting up commands...${RESET}"

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
        echo "  ${GREEN}✓ Global command: $cmd${RESET}"
    else
        echo "  ${YELLOW}⚠️  Command not found: $cmd${RESET}"
    fi
done

# Repository-specific commands
REPO_PATHS=$(jq -r '.commands.repositories // {} | keys[]' "$CONFIG_FILE")
for repo_path_raw in $REPO_PATHS; do
    repo_path=$(expand_path "$repo_path_raw")

    if [ ! -d "$repo_path" ]; then
        echo "  ${YELLOW}⚠️  Skipping missing project: $repo_path${RESET}"
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
            echo "  ${GREEN}✓ $(basename "$repo_path"): $cmd${RESET}"
        else
            echo "  ${YELLOW}⚠️  Command not found: $cmd${RESET}"
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
echo "${BOLD}${CYAN}Setting up MCP servers...${RESET}"

# Function to add or update MCP in global ~/.claude.json (user scope)
add_mcp_to_global() {
    local mcp_name="$1"
    local mcp_json="$2"
    local claude_json="$HOME/.claude.json"

    if [ -f "$claude_json" ]; then
        # Check if mcpServers key exists, if not create it
        if jq -e '.mcpServers' "$claude_json" > /dev/null 2>&1; then
            # Merge with existing mcpServers
            jq --arg name "$mcp_name" --argjson mcp "$mcp_json" \
                '.mcpServers[$name] = $mcp' "$claude_json" > "$claude_json.tmp" && mv "$claude_json.tmp" "$claude_json"
        else
            # Add mcpServers key
            jq --arg name "$mcp_name" --argjson mcp "$mcp_json" \
                '. + {mcpServers: {($name): $mcp}}' "$claude_json" > "$claude_json.tmp" && mv "$claude_json.tmp" "$claude_json"
        fi
    else
        # Create new file with mcpServers
        echo "{\"mcpServers\": {\"$mcp_name\": $mcp_json}}" | jq '.' > "$claude_json"
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
    echo "  ${BOLD}Setting up $mcp_name MCP...${RESET}"

    # Get MCP config - check type first
    MCP_TYPE=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].type // "stdio"' "$CONFIG_FILE")
    MCP_GLOBAL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].global // false' "$CONFIG_FILE")
    MCP_REPOS=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].repositories // [] | .[]' "$CONFIG_FILE")

    # Handle http-type MCP servers differently
    if [ "$MCP_TYPE" = "http" ]; then
        MCP_URL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].url' "$CONFIG_FILE")
        echo "    ${GREEN}✓ HTTP MCP server: $MCP_URL${RESET}"

        # Build the MCP server JSON for http type
        MCP_JSON=$(jq -n \
            --arg type "http" \
            --arg url "$MCP_URL" \
            '{type: $type, url: $url}')
    else
        # stdio type - original logic
        MCP_COMMAND=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].command' "$CONFIG_FILE")
        MCP_INSTALL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].install // ""' "$CONFIG_FILE")

        # Check if package is installed (skip for npx commands since they auto-install)
        if [ "$MCP_COMMAND" != "npx" ]; then
            if command -v "$MCP_COMMAND" &> /dev/null; then
                echo "    ${GREEN}✓ $MCP_COMMAND already installed${RESET}"
            else
                echo "    ${YELLOW}⚠️  $MCP_COMMAND not found${RESET}"
                if [ -n "$MCP_INSTALL" ] && [ "$MCP_INSTALL" != "null" ]; then
                    read -p "    Install with '$MCP_INSTALL'? [y/N] " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        echo "    ${DIM}Installing $mcp_name...${RESET}"
                        eval "$MCP_INSTALL"
                        if command -v "$MCP_COMMAND" &> /dev/null; then
                            echo "    ${GREEN}✓ $MCP_COMMAND installed successfully${RESET}"
                        else
                            echo "    ${RED}Installation failed. Please install manually: $MCP_INSTALL${RESET}"
                        fi
                    else
                        echo "    ${DIM}Skipped. Install manually with: $MCP_INSTALL${RESET}"
                    fi
                else
                    echo "    ${DIM}No install command configured. Add 'install' field to config.${RESET}"
                fi
            fi
        else
            echo "    ${GREEN}✓ Uses npx (auto-installs on first run)${RESET}"
        fi
        MCP_ARGS=$(jq -c --arg name "$mcp_name" '.mcpServers[$name].args // []' "$CONFIG_FILE")
        MCP_ENV_FILE_RAW=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].envFile // ""' "$CONFIG_FILE")

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

        # Build the MCP server JSON for stdio type
        MCP_JSON=$(jq -n \
            --arg type "stdio" \
            --arg command "$MCP_COMMAND" \
            --argjson args "$MCP_ARGS" \
            --argjson env "$ENV_OBJ" \
            '{type: $type, command: $command, args: $args, env: $env}')
    fi

    # If global, add to ~/.claude.json (user scope)
    if [ "$MCP_GLOBAL" = "true" ]; then
        add_mcp_to_global "$mcp_name" "$MCP_JSON"
        echo "    ${GREEN}✓ Added $mcp_name globally to ~/.claude.json${RESET}"
    fi

    # Install MCP in each repository
    for repo_path_raw in $MCP_REPOS; do
        repo_path=$(expand_path "$repo_path_raw")

        if [ ! -d "$repo_path" ]; then
            echo "    ${YELLOW}⚠️  Skipping missing project: $repo_path${RESET}"
            continue
        fi

        add_mcp_to_repo "$repo_path" "$mcp_name" "$MCP_JSON"
        echo "    ${GREEN}✓ Added $mcp_name to $(basename "$repo_path")${RESET}"
    done
done

# ============================================================================
# SHELL CONFIGURATION (claude function & killall-orphan-claude)
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Setting up shell configuration...${RESET}"

# Prompt for --dangerously-skip-permissions
echo ""
echo "  Claude can run with ${BOLD}--dangerously-skip-permissions${RESET} to skip all permission prompts."
echo "  We do have some safety built in with the ${GREEN}dangerous command blocker${RESET}, but there are"
echo "  some risks. Either way, you can always use ${BOLD}claude --sandbox${RESET} to run with"
echo "  --dangerously-skip-permissions inside a sandboxed environment, which is much safer."
echo ""
read -p "  Use --dangerously-skip-permissions by default? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SKIP_PERMISSIONS="true"
    echo "  ${GREEN}✓ Will use --dangerously-skip-permissions${RESET}"
else
    SKIP_PERMISSIONS="false"
    echo "  ${GREEN}✓ Will use standard permissions${RESET}"
fi

# Generate ~/.claude-sandbox-settings.json for sandbox mode
SANDBOX_SETTINGS="$HOME/.claude-sandbox-settings.json"
cat > "$SANDBOX_SETTINGS" << 'SANDBOXEOF'
{
  "sandbox": {
    "enabled": true,
    "mode": "auto-allow"
  }
}
SANDBOXEOF
echo "  ${GREEN}✓ Generated ~/.claude-sandbox-settings.json${RESET}"

# Generate ~/.claude-shell-config.sh
SHELL_CONFIG="$HOME/.claude-shell-config.sh"

if [ "$SKIP_PERMISSIONS" = "true" ]; then
    CLAUDE_FLAGS=' --dangerously-skip-permissions'
else
    CLAUDE_FLAGS=''
fi

# Write the static part (single-quoted heredoc to avoid expansion)
cat > "$SHELL_CONFIG" << 'SHELLEOF'
# Claude shell configuration
# Generated by claude-config bootstrap - do not edit manually

# Remove any claude alias that would conflict (e.g. from .extra)
unalias claude 2>/dev/null

# Kill orphaned Claude processes (detached from terminal)
killall-orphan-claude() {
    local current_pid=$$
    local parent_pid=$PPID
    local pids=$(ps aux | grep -E '[c]laude' | awk '$7 == "??" {print $2}' | grep -v "^${current_pid}$" | grep -v "^${parent_pid}$")
    if [ -z "$pids" ]; then
        return 0
    fi
    local count=$(echo "$pids" | wc -l | tr -d ' ')
    echo "Killing $count orphaned Claude processes..."
    echo "$pids" | xargs kill 2>/dev/null
}
SHELLEOF

# Append the claude function with the correct flags baked in (double-quoted heredoc for variable expansion)
cat >> "$SHELL_CONFIG" << EOF

# Claude wrapper function
# Usage: claude [args]          - normal mode
#        claude --sandbox [args] - sandboxed mode (uses macOS Seatbelt / Linux bubblewrap)
claude() {
    if [ "\$1" = "--sandbox" ]; then
        shift
        killall-orphan-claude
        clear
        command claude --dangerously-skip-permissions --settings ~/.claude-sandbox-settings.json "\$@"
    else
        killall-orphan-claude
        clear
        command claude${CLAUDE_FLAGS} "\$@"
    fi
}
EOF

echo "  ${GREEN}✓ Generated ~/.claude-shell-config.sh${RESET}"

# Add source line to .bashrc and .zshrc (at the end, so it runs after .bash_profile/.extra)
MANAGED_START="# >>> claude-config >>>"
MANAGED_END="# <<< claude-config <<<"

for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ ! -f "$rc_file" ]; then
        continue
    fi

    # Resolve symlinks for sed compatibility (sed -i fails on symlinks on macOS)
    real_rc_file="$rc_file"
    if [ -L "$rc_file" ]; then
        real_rc_file="$(readlink "$rc_file")"
        # Handle relative symlinks
        if [[ "$real_rc_file" != /* ]]; then
            real_rc_file="$(dirname "$rc_file")/$real_rc_file"
        fi
    fi

    # Remove any existing alias claude= lines from rc file
    if grep -q "^alias claude=" "$real_rc_file" 2>/dev/null; then
        sed -i '' '/^alias claude=/d' "$real_rc_file"
        echo "  ${GREEN}✓ Removed old claude alias from $(basename "$rc_file")${RESET}"
    fi

    # Remove existing managed block if present
    if grep -q "$MANAGED_START" "$real_rc_file" 2>/dev/null; then
        sed -i '' "/$MANAGED_START/,/$MANAGED_END/d" "$real_rc_file"
    fi

    # Append managed block
    {
        echo ""
        echo "$MANAGED_START"
        echo "# Managed by claude-config bootstrap - do not edit manually"
        echo '[ -f ~/.claude-shell-config.sh ] && source ~/.claude-shell-config.sh'
        echo "$MANAGED_END"
    } >> "$real_rc_file"

    echo "  ${GREEN}✓ Added claude config to $(basename "$rc_file")${RESET}"
done

# ============================================================================
# RUN TESTS
# ============================================================================
echo ""
echo "${BOLD}${CYAN}Running tests...${RESET}"
echo ""

TEST_SCRIPT="$CLAUDE_CONFIG_DIR/test.sh"
if [ -f "$TEST_SCRIPT" ] && [ -x "$TEST_SCRIPT" ]; then
    if "$TEST_SCRIPT"; then
        echo ""
        echo "${BOLD}${GREEN}Bootstrap complete!${RESET}"
        echo ""
        echo "${DIM}Configuration loaded from: $CONFIG_FILE${RESET}"
    else
        echo ""
        echo "${BOLD}${RED}Bootstrap completed but tests failed!${RESET}"
        echo "${RED}Please review the errors above and fix them.${RESET}"
        exit 1
    fi
else
    echo "${YELLOW}⚠️  Test script not found or not executable: $TEST_SCRIPT${RESET}"
    echo ""
    echo "${BOLD}${GREEN}Bootstrap complete (tests skipped)${RESET}"
    echo ""
    echo "${DIM}Configuration loaded from: $CONFIG_FILE${RESET}"
fi

# ============================================================================
# USAGE SUMMARY
# ============================================================================
echo ""
echo "${BOLD}${BLUE}Usage:${RESET}"
echo ""
echo "  ${BOLD}claude${RESET}"
echo "    ${DIM}1. Kills any orphaned Claude processes${RESET}"
echo "    ${DIM}2. Clears the screen${RESET}"
if [ "$SKIP_PERMISSIONS" = "true" ]; then
    echo "    ${DIM}3. Launches Claude with --dangerously-skip-permissions${RESET}"
else
    echo "    ${DIM}3. Launches Claude with standard permissions${RESET}"
fi
echo ""
echo "  ${BOLD}claude --sandbox${RESET}"
echo "    ${DIM}1. Kills any orphaned Claude processes${RESET}"
echo "    ${DIM}2. Clears the screen${RESET}"
echo "    ${DIM}3. Launches Claude with --dangerously-skip-permissions in a sandboxed environment${RESET}"
echo "    ${DIM}   (uses macOS Seatbelt or Linux bubblewrap for filesystem/network isolation)${RESET}"
echo ""

# ============================================================================
# NEXT STEPS - CREDENTIALS
# ============================================================================
echo "${BOLD}${BLUE}MCP Server Credentials:${RESET}"
echo ""

CREDS_MISSING=false
for cred_example in "$CLAUDE_CONFIG_DIR"/*-credentials.json.example; do
    [ -f "$cred_example" ] || continue
    cred_name=$(basename "$cred_example" .json.example)
    actual_cred="$CLAUDE_CONFIG_DIR/${cred_name}.json"
    # Capitalize the service name (e.g. "slack-credentials" -> "Slack")
    display_name=$(echo "$cred_name" | sed 's/-credentials//' | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

    if [ -f "$actual_cred" ]; then
        echo "  ${GREEN}✓ $display_name credentials configured${RESET}"
    else
        echo "  ${YELLOW}○ $display_name credentials missing${RESET}"
        echo "    ${DIM}Copy ${cred_name}.json.example to ${cred_name}.json and fill in your credentials${RESET}"
        CREDS_MISSING=true
    fi
done

if [ "$CREDS_MISSING" = true ]; then
    echo ""
    echo "  ${DIM}MCP servers without credentials will not be activated until credentials are provided.${RESET}"
fi
echo ""

echo "${DIM}Restart your terminal or run 'source ~/.claude-shell-config.sh' to activate changes.${RESET}"
echo ""
