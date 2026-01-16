# claude-config

**Dotfiles for the AI age.** A framework for managing Claude Code configurations, MCP servers, and custom slash commands across all your projects.

---

Managing Claude Code across multiple repos and machines gets messy fast—scattered `.mcp.json` files, duplicated commands, credentials everywhere. I wanted one place to version, share, and bootstrap my AI setup the same way we do dotfiles. This repo is that layer.

---

## Why?

Just like traditional dotfiles let you sync your shell configuration across machines, `claude-config` lets you:

- **Centralize** your Claude Code settings, commands, and MCP server configurations
- **Version control** your AI assistant setup
- **Bootstrap** new machines or projects with a single command
- **Share** commands across multiple repositories or keep them project-specific

## Quick Start

```bash
# Clone to ~/claude-config
git clone https://github.com/YOUR_USERNAME/claude-config.git ~/claude-config

# Copy example credentials and configure them
cp ~/claude-config/*-credentials.json.example ~/claude-config/*-credentials.json
# Edit the credential files with your actual tokens

# Run bootstrap
~/claude-config/bootstrap.sh
```

## Structure

```
~/claude-config/
├── bootstrap.sh                  # Setup script - run this to apply your config
├── bootstrap-config.json         # Define which commands/MCPs go where
├── settings.json                 # Claude Code permissions and settings
├── commands/                     # Your slash commands (markdown files)
│   ├── review-uncommitted.md     # Example: code review command
│   └── your-command.md           # Add your own!
├── *-credentials.json            # MCP credentials (gitignored)
└── *-credentials.json.example    # Template credential files (safe to commit)
```

## Configuration

### bootstrap-config.json

This is the heart of the configuration. It defines:

1. **MCP Servers** - Which MCP servers to install and where
2. **Commands** - Which slash commands to make available globally or per-repository

```json
{
  "mcpServers": {
    "slack": {
      "command": "slack-mcp-server",
      "args": [],
      "install": "npm install -g @anthropic-ai/slack-mcp-server",
      "env": {
        "SLACK_TOKEN_FILE": "$HOME/.slack-mcp-tokens.json"
      },
      "repositories": [
        "$HOME/projects/my-app",
        "$HOME/projects/another-app"
      ]
    },
    "jira": {
      "command": "npx",
      "args": ["-y", "mcp-jira-stdio"],
      "envFile": "$HOME/.jira-mcp-credentials.json",
      "repositories": ["$HOME/projects/my-app"]
    }
  },
  "commands": {
    "global": [
      "review-uncommitted.md"
    ],
    "repositories": {
      "$HOME/projects/my-app": [
        "deploy.md",
        "post-pr-to-slack.md"
      ]
    }
  }
}
```

### Adding Commands

Commands are markdown files in the `commands/` directory. They become available as `/command-name` in Claude Code.

```markdown
<!-- commands/my-command.md -->
# My Command

Instructions for Claude when this command is invoked...
```

- **Global commands**: Listed under `commands.global` - available in all projects
- **Repository commands**: Listed under `commands.repositories` - only available in specific repos

### Adding MCP Servers

MCP servers are configured in the `mcpServers` section:

- `command`: The executable to run
- `args`: Command line arguments
- `install`: Install command if package is missing (bootstrap will prompt before running)
- `env`: Environment variables (supports `$HOME` expansion)
- `envFile`: Path to a JSON file containing environment variables
- `repositories`: Which repositories should have this MCP server

**Note:** For `npx` commands, installation is handled automatically on first run. The `install` field is only needed for direct commands like `slack-mcp-server`.

### Settings

The `settings.json` file contains Claude Code permissions and settings that get merged into your global `~/.claude/settings.json`.

## How Bootstrap Works

When you run `~/claude-config/bootstrap.sh`, it:

1. **Merges settings** - Combines your `settings.json` with the global Claude settings
2. **Creates credential symlinks** - Links credential files to expected locations
3. **Symlinks commands** - Links commands to `~/.claude/commands/` (global) or `repo/.claude/commands/` (per-repo)
4. **Configures MCP servers** - Creates/updates `.mcp.json` in each repository
5. **Updates .gitignore** - Adds `.claude/` and `.mcp.json` to repositories' gitignores

## Credentials

Credential files are gitignored by default. Use the `.example` files as templates:

```bash
# Copy and edit credential files
cp slack-credentials.json.example slack-credentials.json
cp jira-credentials.json.example jira-credentials.json

# Edit with your actual credentials
# Then re-run bootstrap
~/claude-config/bootstrap.sh
```

## Syncing Across Machines

Since this is a git repository, sync your configuration across machines:

```bash
# On a new machine
git clone https://github.com/YOUR_USERNAME/claude-config.git ~/claude-config

# Set up credentials (these aren't synced)
cp ~/claude-config/*-credentials.json.example ~/claude-config/*-credentials.json
# Edit credentials...

# Bootstrap
~/claude-config/bootstrap.sh
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `jq` for JSON parsing (`brew install jq` on macOS)
- Any MCP servers you want to use (e.g., `npm install -g slack-mcp-server`)

## License

MIT License - see [LICENSE](LICENSE) for details.
