#!/bin/bash

# Test script for Claude Config bootstrap
# Run this after bootstrap.sh to verify everything is set up correctly
# All tests are driven by bootstrap-config.json - no hardcoded values

CLAUDE_CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CONFIG_FILE="$CLAUDE_CONFIG_DIR/bootstrap-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

expand_path() {
    echo "${1//\$HOME/$HOME}"
}

echo "🧪 Testing Claude Config Bootstrap..."

# ============================================================================
# PREREQUISITES
# ============================================================================
section "Prerequisites"

if command -v jq &> /dev/null; then
    pass "jq is installed"
else
    fail "jq is not installed"
    exit 1
fi

if [ -f "$CONFIG_FILE" ]; then
    pass "bootstrap-config.json exists"
else
    fail "bootstrap-config.json not found"
    exit 1
fi

# ============================================================================
# CCSTATUSLINE
# ============================================================================
section "ccstatusline"

if command -v ccstatusline &> /dev/null; then
    pass "ccstatusline is installed"
else
    fail "ccstatusline is not installed"
fi

if [ -L "$HOME/.config/ccstatusline/settings.json" ]; then
    pass "ccstatusline config is symlinked"
    # Verify symlink points to correct location
    LINK_TARGET=$(readlink "$HOME/.config/ccstatusline/settings.json")
    if [ "$LINK_TARGET" = "$CLAUDE_CONFIG_DIR/ccstatusline-settings.json" ]; then
        pass "ccstatusline symlink points to correct location"
    else
        fail "ccstatusline symlink points to wrong location: $LINK_TARGET"
    fi
else
    fail "ccstatusline config symlink not found"
fi

# ============================================================================
# SETTINGS
# ============================================================================
section "Settings"

SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    pass "~/.claude/settings.json exists"

    # Check for key sections from source settings.json
    if [ -f "$CLAUDE_CONFIG_DIR/settings.json" ]; then
        # Get top-level keys from source settings
        SOURCE_KEYS=$(jq -r 'keys[]' "$CLAUDE_CONFIG_DIR/settings.json")
        for key in $SOURCE_KEYS; do
            if jq -e ".$key" "$SETTINGS_FILE" > /dev/null 2>&1; then
                pass "settings.json has '$key' section"
            else
                fail "settings.json missing '$key' section"
            fi
        done

        # Check ENABLE_TOOL_SEARCH is configured
        TOOL_SEARCH=$(jq -r '.env.ENABLE_TOOL_SEARCH // ""' "$SETTINGS_FILE")
        if [ -n "$TOOL_SEARCH" ] && [ "$TOOL_SEARCH" != "null" ]; then
            pass "ENABLE_TOOL_SEARCH is set to '$TOOL_SEARCH'"
        else
            warn "ENABLE_TOOL_SEARCH not configured in env"
        fi
    fi
else
    fail "~/.claude/settings.json not found"
fi

# ============================================================================
# HOOKS
# ============================================================================
section "Hooks"

HOOKS_DIR="$CLAUDE_DIR/hooks"

if [ -d "$HOOKS_DIR" ]; then
    pass "~/.claude/hooks directory exists"

    # Check for specific hooks from source
    if [ -d "$CLAUDE_CONFIG_DIR/hooks" ]; then
        for hook_file in "$CLAUDE_CONFIG_DIR/hooks"/*; do
            if [ -f "$hook_file" ]; then
                hook_name=$(basename "$hook_file")
                if [ -f "$HOOKS_DIR/$hook_name" ]; then
                    pass "Hook copied: $hook_name"
                else
                    fail "Hook missing: $hook_name"
                fi
            fi
        done
    else
        warn "No hooks directory in source config"
    fi
else
    fail "~/.claude/hooks directory not found"
fi

# ============================================================================
# CREDENTIAL SYMLINKS (Dynamic based on envFile configs)
# ============================================================================
section "Credential Symlinks"

# Helper to check symlink status
check_credential_file() {
    local file_path="$1"
    local mcp_name="$2"
    local file_basename=$(basename "$file_path")

    if [ -L "$file_path" ]; then
        # It's a symlink - check if it resolves
        if [ -e "$file_path" ]; then
            pass "$mcp_name: $file_basename (valid symlink)"
        else
            fail "$mcp_name: $file_basename (BROKEN symlink)"
        fi
    elif [ -f "$file_path" ]; then
        pass "$mcp_name: $file_basename (regular file)"
    else
        warn "$mcp_name: $file_basename missing"
    fi
}

# Dynamically check credential files based on MCP envFile configs
MCP_NAMES=$(jq -r '.mcpServers // {} | keys[]' "$CONFIG_FILE")
for mcp_name in $MCP_NAMES; do
    ENV_FILE_RAW=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].envFile // ""' "$CONFIG_FILE")

    if [ -n "$ENV_FILE_RAW" ] && [ "$ENV_FILE_RAW" != "null" ]; then
        ENV_FILE_PATH=$(expand_path "$ENV_FILE_RAW")
        check_credential_file "$ENV_FILE_PATH" "$mcp_name"
    fi

    # Also check env vars that reference token files (dynamically find *_FILE env vars)
    TOKEN_FILES=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].env // {} | to_entries[] | select(.key | endswith("_FILE")) | .value' "$CONFIG_FILE")
    for token_file in $TOKEN_FILES; do
        if [ -n "$token_file" ] && [ "$token_file" != "null" ]; then
            TOKEN_FILE_PATH=$(expand_path "$token_file")
            check_credential_file "$TOKEN_FILE_PATH" "$mcp_name"
        fi
    done
done

# ============================================================================
# GLOBAL COMMANDS
# ============================================================================
section "Global Commands"

GLOBAL_COMMANDS_DIR="$CLAUDE_DIR/commands"

if [ -d "$GLOBAL_COMMANDS_DIR" ]; then
    pass "~/.claude/commands directory exists"

    GLOBAL_COMMANDS=$(jq -r '.commands.global // [] | .[]' "$CONFIG_FILE")
    if [ -n "$GLOBAL_COMMANDS" ]; then
        for cmd in $GLOBAL_COMMANDS; do
            if [ -L "$GLOBAL_COMMANDS_DIR/$cmd" ]; then
                pass "Global command symlinked: $cmd"
            else
                fail "Global command missing: $cmd"
            fi
        done
    else
        warn "No global commands configured"
    fi
else
    fail "~/.claude/commands directory not found"
fi

# ============================================================================
# REPOSITORY COMMANDS
# ============================================================================
section "Repository Commands"

REPO_PATHS=$(jq -r '.commands.repositories // {} | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
if [ -n "$REPO_PATHS" ]; then
    for repo_path_raw in $REPO_PATHS; do
        repo_path=$(expand_path "$repo_path_raw")
        repo_name=$(basename "$repo_path")

        if [ ! -d "$repo_path" ]; then
            warn "Repository not found: $repo_name (skipped)"
            continue
        fi

        REPO_COMMANDS_DIR="$repo_path/.claude/commands"
        if [ -d "$REPO_COMMANDS_DIR" ]; then
            REPO_COMMANDS=$(jq -r --arg path "$repo_path_raw" '.commands.repositories[$path] // [] | .[]' "$CONFIG_FILE")
            for cmd in $REPO_COMMANDS; do
                if [ -L "$REPO_COMMANDS_DIR/$cmd" ]; then
                    pass "$repo_name: command symlinked: $cmd"
                else
                    fail "$repo_name: command missing: $cmd"
                fi
            done
        else
            fail "$repo_name: .claude/commands directory not found"
        fi
    done
else
    warn "No repository-specific commands configured"
fi

# ============================================================================
# GLOBAL MCP SERVERS
# ============================================================================
section "Global MCP Servers (~/.claude.json)"

GLOBAL_CLAUDE_JSON="$HOME/.claude.json"

# Check if any global MCP servers are configured
HAS_GLOBAL_MCP=false
MCP_NAMES=$(jq -r '.mcpServers // {} | keys[]' "$CONFIG_FILE")
for mcp_name in $MCP_NAMES; do
    MCP_GLOBAL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].global // false' "$CONFIG_FILE")
    if [ "$MCP_GLOBAL" = "true" ]; then
        HAS_GLOBAL_MCP=true
        break
    fi
done

if [ "$HAS_GLOBAL_MCP" = "true" ]; then
    if [ -f "$GLOBAL_CLAUDE_JSON" ]; then
        pass "~/.claude.json exists"

        for mcp_name in $MCP_NAMES; do
            MCP_GLOBAL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].global // false' "$CONFIG_FILE")

            if [ "$MCP_GLOBAL" = "true" ]; then
                if jq -e --arg name "$mcp_name" '.mcpServers[$name]' "$GLOBAL_CLAUDE_JSON" > /dev/null 2>&1; then
                    pass "Global MCP configured: $mcp_name"

                    # Verify MCP server structure based on type
                    MCP_TYPE=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].type // "stdio"' "$GLOBAL_CLAUDE_JSON")
                    if [ "$MCP_TYPE" = "stdio" ]; then
                        if jq -e --arg name "$mcp_name" '.mcpServers[$name].command' "$GLOBAL_CLAUDE_JSON" > /dev/null 2>&1; then
                            COMMAND=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].command' "$GLOBAL_CLAUDE_JSON")
                            pass "  $mcp_name: command=$COMMAND"
                        else
                            fail "  $mcp_name: missing command field"
                        fi
                    elif [ "$MCP_TYPE" = "http" ]; then
                        if jq -e --arg name "$mcp_name" '.mcpServers[$name].url' "$GLOBAL_CLAUDE_JSON" > /dev/null 2>&1; then
                            URL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].url' "$GLOBAL_CLAUDE_JSON")
                            pass "  $mcp_name: url=$URL"
                        else
                            fail "  $mcp_name: missing url field"
                        fi
                    fi
                else
                    fail "Global MCP not configured: $mcp_name"
                fi
            fi
        done
    else
        fail "~/.claude.json not found"
    fi
else
    warn "No global MCP servers configured"
fi

# ============================================================================
# REPOSITORY MCP SERVERS
# ============================================================================
section "Repository MCP Servers (.mcp.json)"

MCP_NAMES=$(jq -r '.mcpServers // {} | keys[]' "$CONFIG_FILE")
for mcp_name in $MCP_NAMES; do
    MCP_REPOS=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].repositories // [] | .[]' "$CONFIG_FILE")

    for repo_path_raw in $MCP_REPOS; do
        repo_path=$(expand_path "$repo_path_raw")
        repo_name=$(basename "$repo_path")

        if [ ! -d "$repo_path" ]; then
            warn "$repo_name: repository not found (skipped)"
            continue
        fi

        MCP_FILE="$repo_path/.mcp.json"
        if [ -f "$MCP_FILE" ]; then
            if jq -e --arg name "$mcp_name" '.mcpServers[$name]' "$MCP_FILE" > /dev/null 2>&1; then
                pass "$repo_name: MCP configured: $mcp_name"

                # Verify MCP server structure based on type
                MCP_TYPE=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].type // "stdio"' "$MCP_FILE")
                if [ "$MCP_TYPE" = "stdio" ]; then
                    MCP_COMMAND=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].command' "$MCP_FILE")
                    if [ -n "$MCP_COMMAND" ] && [ "$MCP_COMMAND" != "null" ]; then
                        pass "  $mcp_name: command=$MCP_COMMAND"
                    else
                        fail "  $mcp_name: missing command"
                    fi
                elif [ "$MCP_TYPE" = "http" ]; then
                    MCP_URL=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].url' "$MCP_FILE")
                    if [ -n "$MCP_URL" ] && [ "$MCP_URL" != "null" ]; then
                        pass "  $mcp_name: url=$MCP_URL"
                    else
                        fail "  $mcp_name: missing url"
                    fi
                fi
            else
                fail "$repo_name: MCP not configured: $mcp_name"
            fi
        else
            fail "$repo_name: .mcp.json not found"
        fi
    done
done

# ============================================================================
# MCP BINARY CHECKS (for non-npx servers)
# ============================================================================
section "MCP Server Binaries"

MCP_NAMES=$(jq -r '.mcpServers // {} | keys[]' "$CONFIG_FILE")
for mcp_name in $MCP_NAMES; do
    MCP_COMMAND=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].command // ""' "$CONFIG_FILE")
    MCP_TYPE=$(jq -r --arg name "$mcp_name" '.mcpServers[$name].type // "stdio"' "$CONFIG_FILE")

    # Skip http type servers and npx commands
    if [ "$MCP_TYPE" = "http" ]; then
        pass "$mcp_name: HTTP server (no binary needed)"
        continue
    fi

    if [ "$MCP_COMMAND" = "npx" ]; then
        pass "$mcp_name: uses npx (auto-installs)"
        continue
    fi

    if [ -n "$MCP_COMMAND" ] && [ "$MCP_COMMAND" != "null" ]; then
        if command -v "$MCP_COMMAND" &> /dev/null; then
            pass "$mcp_name: binary installed ($MCP_COMMAND)"
        else
            fail "$mcp_name: binary not found ($MCP_COMMAND)"
        fi
    fi
done

# ============================================================================
# SUMMARY
# ============================================================================
section "Test Summary"

echo ""
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please run bootstrap.sh and try again.${NC}"
    exit 1
fi
