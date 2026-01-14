# Claude Config

Personal Claude Code configuration, commands, and MCP settings.

## Structure

```
.claude-config/
├── commands/                    # Slash commands for Claude Code
│   ├── commit-push-pr.md
│   └── post-sdk-pr-to-slack.md
├── bootstrap.sh                 # Setup script for symlinks and MCP servers
├── slack-credentials.json       # Slack MCP credentials (gitignored)
└── README.md
```

## Installation

Run the bootstrap script to set up everything:

```bash
~/.claude-config/bootstrap.sh
```

This will:
- Symlink commands to `~/.claude/commands`
- Symlink Slack credentials to `~/.slack-mcp-tokens.json`
- Install Slack and Jira MCP servers via `claude mcp add`

### Manual Installation

If you prefer to set up manually:

```bash
# Symlink commands
ln -sf ~/.claude-config/commands ~/.claude/commands

# Symlink Slack credentials
ln -sf ~/.claude-config/slack-credentials.json ~/.slack-mcp-tokens.json

# Add MCP servers
claude mcp add slack slack-mcp-server -e SLACK_TOKEN_FILE=~/.slack-mcp-tokens.json
claude mcp add jira -- npx -y mcp-jira-stdio
```

## Commands

### `/commit-push-pr`
Automates git workflow: commit, push, and create PR with smart ticket detection.

### `/post-sdk-pr-to-slack`
Posts PR links to the `eng-sdk-team` Slack channel with proper formatting and tags.

## MCP Servers

### Slack MCP
- **Package**: `@teamsparta/mcp-server-slack`
- **Install**: `npm install -g @teamsparta/mcp-server-slack`
- **Credentials**: Stored in `slack-credentials.json` (gitignored)

### Jira MCP
- **Package**: `mcp-jira-stdio`
- **Install**: Automatically installed via `npx` when added
- **Credentials**: Configure via environment variables when needed
