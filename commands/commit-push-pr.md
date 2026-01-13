---
description: Commit changes, push to feature branch, and create a pull request
argument-hint: [ticket-number or branch-name]
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task]
---

# Commit, Push, and Create PR

This command automates the complete git workflow: commit, push, and PR creation.

## Arguments

Optional: $ARGUMENTS

Can be used for:
- Custom branch name (e.g., "fix-login-bug")
- Ticket number (e.g., "SDK-296" or "JIRA-123")
- Both: "SDK-296-fix-login-bug"

**Note:** Even if no argument is provided, the command will:
- Automatically detect ticket numbers from conversation context, branch name, or commit history
- Auto-generate a branch name based on the commit message
- Include the detected ticket number in the PR title and branch name

## Instructions

When this command is invoked:

### 1. Check Current Git Status and Extract Context

- Run `git status` to see current branch and changes
- Check if working directory has uncommitted changes

**IMPORTANT: Smart Ticket Number Detection**

Always try to detect the ticket number in this priority order:

1. **From $ARGUMENTS**: Check if arguments contain a ticket pattern (e.g., "SDK-296", "JIRA-123", "PROJ-456")
2. **From current branch name**: Extract ticket number if branch is like "feature/SDK-296-..." or "fix/JIRA-123-..."
3. **From conversation context**: Review the recent conversation history for:
   - User saying "I'm working on SDK-296"
   - User mentioning "Fix SDK-296"
   - User discussing a specific ticket number
   - Any ticket references in the last few messages
4. **From commit messages**: Check recent commits in current branch for ticket numbers

**Ticket Pattern Recognition:**
- Common formats: `[A-Z]+-\d+` (e.g., SDK-296, JIRA-1234, PROJ-42)
- Store the ticket number if found for use in branch name and PR title
- If no ticket number found after checking all sources, that's OK - proceed without it

### 2. Ensure Feature Branch

- If on `master` branch:
  - Generate branch name based on $ARGUMENTS and changes:
    - If $ARGUMENTS contains ticket number (e.g., "SDK-296"): use format `feature/SDK-296-brief-description`
    - If $ARGUMENTS is just a name: use `feature/$ARGUMENTS`
    - If no $ARGUMENTS: auto-generate like `feature/add-dark-mode` or `fix/login-bug`
  - Create and checkout new branch from master: `git checkout -b branch-name`
- If already on a feature branch:
  - Ensure we're branched from master by checking `git merge-base HEAD master`
  - If not properly branched from master, warn the user

### 3. Review Changes

- Run `git status` to see all untracked and modified files
- Run `git diff` to see staged and unstaged changes
- Run `git log -5 --oneline` to understand commit history style

### 4. Create Commit(s)

- Analyze all changes and determine if they should be **one commit or multiple commits**:
  - **Single commit**: If all changes are related to one logical unit of work
  - **Multiple commits**: If changes can be broken into distinct, independent pieces (e.g., refactor + feature, or multiple unrelated fixes)
  
- For each commit:
  - Group related files together
  - Create a meaningful commit message that:
    - Summarizes the nature of changes (feature, fix, refactor, docs, etc.)
    - Is concise (1-2 sentences) focusing on "why" not just "what"
    - Follows the repository's existing commit style
  - Stage relevant files with `git add`
  - Use heredoc format for commit message:
    ```bash
    git commit -m "$(cat <<'EOF'
    Your commit message here.
    EOF
    )"
    ```

- **Granular commit examples**:
  - Separate "cleanup/refactor" from "new feature"
  - Separate "fix bug A" from "fix bug B" if unrelated
  - Separate "update dependencies" from "code changes"
  - Keep test changes with the code they test (same commit)

### 5. Push to Remote

- Push with upstream tracking: `git push -u origin branch-name`
- Verify push succeeded

### 6. Create Pull Request

- Run `git log master..HEAD` to understand all commits in the PR
- Run `git diff master...HEAD` to see all changes since branching from master
- Analyze ALL commits (not just the latest) to understand the full scope

#### PR Title Format

- If ticket number detected (from any source): `[TICKET-NUM] Brief description` (e.g., "SDK-296 Make isIterableDeepLink public")
- If NO ticket number found: `Brief description of what this accomplishes` (e.g., "Add user authentication support")
- Keep it under 60 characters, human-readable, focus on the outcome
- The ticket number should be auto-detected from arguments, branch name, or conversation context

#### PR Description Guidelines

Write a PR description that is:
- **Concise**: Only important changes, no fluff
- **Human-readable**: Like a colleague explaining changes, not AI-generated documentation
- **Action-oriented**: Focus on what changed and why it matters

Structure:
```bash
gh pr create --title "PR Title Here" --body "$(cat <<'EOF'
## What
Brief explanation (2-3 sentences max) of what this PR does and why.

## Changes
- Key change 1 (why it matters)
- Key change 2 (why it matters)
- Keep it to 3-5 bullet points max, only the important stuff

## Impact
- **Breaking changes**: None OR describe what breaks
- **Dependencies**: Any new dependencies or version changes?
- **Performance**: Any performance implications?

## Testing
**How to test:**
1. Step-by-step instructions
2. Expected behavior
3. Edge cases to check
EOF
)"
```

#### Important Notes for PR Quality

- **Be concise**: Humans don't want to read essays. Get to the point.
- **Skip obvious details**: Don't list every single file change, focus on the "why"
- **Use clear language**: Avoid jargon, write like you're explaining to a teammate
- **Highlight risks**: If something could break, say it upfront
- **Make testing easy**: Clear, numbered steps anyone can follow
- Return the PR URL to the user

## Safety Rules

- NEVER force push to main/master
- NEVER skip git hooks (--no-verify)
- NEVER update git config
- DO NOT commit files with secrets (.env, credentials.json, etc.)
- Only use `git commit --amend` if explicitly requested by user AND:
  - HEAD commit was created in this session
  - Commit has NOT been pushed yet

## Best Practices

- Always branch from master, not from another feature branch
- Use descriptive branch names (e.g., feature/add-dark-mode, fix/login-bug)
- Ensure commit message accurately reflects changes
- Include comprehensive PR description with all commits, not just latest
- Include test plan in PR description
