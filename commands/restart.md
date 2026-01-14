---
description: Quit Claude and optionally restart with the current conversation
argument-hint: [--keep-conversation]
allowed-tools: [Bash]
---

# Restart Claude

This command safely quits Claude Code and can optionally attempt to restart it with the current conversation.

## Arguments

Optional: `--keep-conversation`

- Without arguments: Simply quits Claude Code
- `--keep-conversation`: Attempts to quit and restart Claude while preserving the conversation (experimental)

## Instructions

When this command is invoked:

### Basic Restart (no arguments)

1. **Check for unsaved changes**: Run `git status` to see if there are any uncommitted changes
2. **Warn user if needed**: If there are uncommitted changes, inform the user they may be lost
3. **Quit gracefully**: Exit Claude Code with exit code 0

### Keep Conversation Restart (--keep-conversation)

1. **Experimental feature**: This is an experimental attempt to restart Claude while preserving conversation context
2. **Check current state**: Note the current working directory and any active processes
3. **Save conversation marker**: Create a temporary file to indicate restart was requested
4. **Quit Claude**: Exit with a special exit code (42) to signal restart intent
5. **Note**: The actual conversation restoration would need to be handled by the Claude interface or a wrapper script

## Implementation

```bash
#!/bin/bash

# Handle the restart command
if [ "$ARGUMENTS" = "--keep-conversation" ]; then
  echo "Attempting to restart Claude while preserving conversation..."

  # Check for unsaved work
  if git status --porcelain | grep -q .; then
    echo "Warning: You have uncommitted changes. They may be lost on restart."
    echo "Consider committing your changes first with /commit-push-pr"
  fi

  # Create a restart marker (this could be used by a wrapper script)
  echo "RESTART_REQUESTED" > /tmp/claude_restart_marker
  echo "Working directory: $(pwd)" >> /tmp/claude_restart_marker
  echo "Timestamp: $(date)" >> /tmp/claude_restart_marker

  echo "Quitting Claude with restart marker set..."
  exit 42  # Special exit code to indicate restart was requested
else
  echo "Quitting Claude Code..."

  # Check for unsaved work
  if git status --porcelain | grep -q .; then
    echo "Warning: You have uncommitted changes."
    echo "Use '/commit-push-pr' to save your work before quitting."
  fi

  echo "Goodbye!"
  exit 0
fi
```

## Notes

- **Conversation preservation**: Currently, conversation state is managed by Claude's interface. The `--keep-conversation` flag creates markers that could potentially be used by wrapper scripts or future Claude features.
- **Safety**: Always checks for unsaved git changes before quitting
- **Exit codes**: Uses exit code 42 for restart requests, 0 for normal quits
- **Future enhancement**: This could be extended with actual conversation serialization if Claude provides APIs for it

## Usage Examples

```
/restart
/restart --keep-conversation
```