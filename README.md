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
├── jira-credentials.json        # Jira MCP credentials (gitignored)
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
- Symlink Jira credentials to `~/.jira-mcp-credentials.json`
- Install Slack and Jira MCP servers via `claude mcp add`

### Manual Installation

If you prefer to set up manually:

```bash
# Symlink commands
ln -sf ~/.claude-config/commands ~/.claude/commands

# Symlink credentials
ln -sf ~/.claude-config/slack-credentials.json ~/.slack-mcp-tokens.json
ln -sf ~/.claude-config/jira-credentials.json ~/.jira-mcp-credentials.json

# Add MCP servers
claude mcp add slack slack-mcp-server -e SLACK_TOKEN_FILE=~/.slack-mcp-tokens.json
claude mcp add jira -e JIRA_URL="..." -e JIRA_USERNAME="..." -e JIRA_API_TOKEN="..." -- npx -y mcp-jira-stdio
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
- **Credentials**: Stored in `jira-credentials.json` (gitignored)
  - Get your API token from: https://id.atlassian.com/manage-profile/security/api-tokens

## Setup Credentials

### Slack
The `slack-credentials.json` should already be configured with your tokens.

### Jira
Edit `~/.claude-config/jira-credentials.json` with your Jira details:

```json
{
  "JIRA_URL": "https://your-domain.atlassian.net",
  "JIRA_USERNAME": "your-email@example.com",
  "JIRA_API_TOKEN": "your-api-token-here"
}
```

Then re-run the bootstrap script to apply the credentials.
