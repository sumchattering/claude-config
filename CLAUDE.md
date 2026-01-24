# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is a dotfiles-style configuration repository for Claude Code. It centralizes settings, MCP server configurations, slash commands, and hooks that get bootstrapped to `~/.claude/` and individual project repositories.

## Commands

```bash
# Apply all configuration (run after any changes)
./bootstrap.sh

# Run tests to verify configuration
./test.sh
```

## Architecture

### Core Files

- **bootstrap-config.json** - Central configuration defining which MCP servers and commands go where. Supports `$HOME` path expansion.
- **settings.json** - Claude Code settings (permissions, hooks, env vars) that get merged into `~/.claude/settings.json`
- **bootstrap.sh** - Reads `bootstrap-config.json` and applies configuration by creating symlinks and updating JSON files

### What Bootstrap Does

1. Installs/symlinks `ccstatusline` for the status line widget
2. Merges `settings.json` into `~/.claude/settings.json`
3. Copies hooks to `~/.claude/hooks/`
4. Creates credential symlinks from `*-credentials.json` to `~/.*-credentials.json`
5. Symlinks commands to `~/.claude/commands/` (global) or `repo/.claude/commands/` (per-repo)
6. Creates/updates `.mcp.json` in target repositories
7. Runs `test.sh` to verify everything

### MCP Server Configuration

In `bootstrap-config.json`, MCP servers can be:
- **Global** (`"global": true`) - Added to `~/.claude.json`
- **Per-repository** (`"repositories": [...]`) - Added to each repo's `.mcp.json`
- **stdio type** (default) - Uses `command` and `args`
- **http type** (`"type": "http"`) - Uses `url` for remote MCP servers

### Credential Files

Files matching `*-credentials.json` are gitignored. The bootstrap creates symlinks from the repo to `$HOME` where MCP servers expect them. Use `.example` files as templates.
