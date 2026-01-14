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
├── slab-credentials.json        # Slab MCP credentials (gitignored)
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
- Symlink Slab credentials to `~/.slab-mcp-credentials.json`
- Install Slack, Jira, and Slab MCP servers system-wide via `claude mcp add --scope user`

### Manual Installation

If you prefer to set up manually:

```bash
# Symlink commands
ln -sf ~/.claude-config/commands ~/.claude/commands

# Symlink credentials
ln -sf ~/.claude-config/slack-credentials.json ~/.slack-mcp-tokens.json
ln -sf ~/.claude-config/jira-credentials.json ~/.jira-mcp-credentials.json
ln -sf ~/.claude-config/slab-credentials.json ~/.slab-mcp-credentials.json

# Add MCP servers (system-wide)
claude mcp add --scope user slack slack-mcp-server -e SLACK_TOKEN_FILE=~/.slack-mcp-tokens.json
claude mcp add --scope user jira -e JIRA_BASE_URL="..." -e JIRA_EMAIL="..." -e JIRA_API_TOKEN="..." -- npx -y mcp-jira-stdio
claude mcp add --scope user slab -e SLAB_API_TOKEN="..." -e SLAB_TEAM="..." -- npx -y @russwyte/slabby
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

### Slab MCP
- **Package**: `@russwyte/slabby`
- **Install**: Automatically installed via `npx` when added
- **Credentials**: Stored in `slab-credentials.json` (gitignored)
  - Get your API token from: Your Slab workspace → Settings → API

## Setup Credentials

### Slack
The `slack-credentials.json` should already be configured with your tokens.

### Jira
Edit `~/.claude-config/jira-credentials.json` with your Jira details:

```json
{
  "JIRA_BASE_URL": "https://your-domain.atlassian.net",
  "JIRA_EMAIL": "your-email@example.com",
  "JIRA_API_TOKEN": "your-api-token-here"
}
```

Then re-run the bootstrap script to apply the credentials:

```bash
# First, remove the existing Jira MCP server
claude mcp remove jira -s user

# Then re-run bootstrap to add it with credentials
~/.claude-config/bootstrap.sh
```

### Slab
Edit `~/.claude-config/slab-credentials.json` with your Slab details:

```json
{
  "SLAB_API_TOKEN": "your-slab-api-token-here",
  "SLAB_TEAM": "your-team-domain"
}
```

Then re-run the bootstrap script to apply the credentials:

```bash
# First, remove the existing Slab MCP server
claude mcp remove slab -s user

# Then re-run bootstrap to add it with credentials
~/.claude-config/bootstrap.sh
```
