# Claude Config

Personal Claude Code configuration, commands, and MCP settings.

## Structure

```
.claude-config/
├── commands/           # Slash commands for Claude Code
│   ├── commit-push-pr.md
│   └── post-sdk-pr-to-slack.md
├── mcp/                # MCP server configurations (future)
└── skills/             # Claude skills (future)
```

## Installation

Symlink commands to Claude's home directory:

```bash
ln -sf ~/.claude-config/commands ~/.claude/commands
```

## Commands

### `/commit-push-pr`
Automates git workflow: commit, push, and create PR with smart ticket detection.

### `/post-sdk-pr-to-slack`
Posts PR links to the `eng-sdk-team` Slack channel with proper formatting and tags.
