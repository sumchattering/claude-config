# Claude Config

Personal Claude Code configuration, commands, and MCP settings.

## Structure

```
.claude-config/
├── commands/              # Slash commands for Claude Code
│   ├── commit-push-pr.md
│   └── post-sdk-pr-to-slack.md
├── mcp.json               # MCP server configurations
├── slack-credentials.json # Slack MCP credentials (gitignored)
└── jira-credentials.json  # Jira MCP credentials (gitignored)
```

## Installation

### Commands
Symlink commands to Claude's home directory:

```bash
ln -sf ~/.claude-config/commands ~/.claude/commands
```

### MCP Servers
The `mcp.json` file configures MCP servers for:
- **Slack**: Integration with Slack workspace
- **Jira**: Integration with Jira/Atlassian

Credentials are stored separately in gitignored files.

## Commands

### `/commit-push-pr`
Automates git workflow: commit, push, and create PR with smart ticket detection.

### `/post-sdk-pr-to-slack`
Posts PR links to the `eng-sdk-team` Slack channel with proper formatting and tags.

## MCP Setup

### Slack MCP
Credentials are stored in `slack-credentials.json` (gitignored).

### Jira MCP
Credentials should be stored in `jira-credentials.json` (gitignored) with:
```json
{
  "JIRA_URL": "https://your-domain.atlassian.net",
  "JIRA_USERNAME": "your-email@example.com",
  "JIRA_API_TOKEN": "your-api-token"
}
```
