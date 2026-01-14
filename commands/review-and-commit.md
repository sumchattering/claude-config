---
description: Review code changes using a Sonnet subagent, then commit with a meaningful message
argument-hint: [optional: commit-message-hint]
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task]
---

# Review and Commit

This command reviews your code changes using a Sonnet subagent, addresses any issues found, and then creates a meaningful commit.

## Arguments

Optional: $ARGUMENTS

Can be used for:
- A hint about what the changes are for (e.g., "add user authentication")
- A ticket number (e.g., "SDK-296")

## Instructions

When this command is invoked:

### 1. Gather Context

- Run `git status` to see current branch and changes
- Run `git diff` to see all uncommitted changes (both staged and unstaged)
- Focus on ALL uncommitted changes regardless of staging status
- If no changes exist, inform the user and exit

### 2. Invoke Sonnet Subagent for Code Review

**IMPORTANT**: Use the Task tool to spawn a code review subagent with these parameters:

```
Task tool parameters:
- subagent_type: "general-purpose"
- model: "sonnet"
- description: "Review code changes"
- prompt: [See below]
```

**Prompt for the review subagent:**

```
You are a code reviewer. Review the following code changes and provide feedback.

## Changes to Review:
[Include the full git diff output here - this includes ALL uncommitted changes, both staged and unstaged]

## Context:
- Current branch: [branch name]
- Arguments/context from user: $ARGUMENTS

## Your Task:
1. Review the code for:
   - Bugs or logical errors
   - Security vulnerabilities (injection, XSS, etc.)
   - Performance issues
   - Code style and readability
   - Missing error handling
   - Edge cases not handled

2. Provide your review in this format:
   - **Issues Found**: List any problems that MUST be fixed before committing
   - **Suggestions**: Optional improvements (nice-to-have, not blocking)
   - **Summary**: One sentence summary of the changes
   - **Commit Message Suggestion**: A concise commit message for these changes

3. If the code looks good with no blocking issues, say "LGTM" (Looks Good To Me) and provide the commit message suggestion.

Be concise and actionable. Focus on real issues, not nitpicks.
```

### 3. Process Review Results

After receiving the review from the subagent:

- **If issues were found**:
  - Present the issues to the user
  - Ask the user if they want to:
    1. Fix the issues now (you can help fix them)
    2. Commit anyway (acknowledge the issues)
    3. Abort the commit
  - If user chooses to fix, apply the fixes and re-run the review

- **If LGTM (no blocking issues)**:
  - Show the user the review summary and suggested commit message
  - Proceed to commit step

### 4. Stage and Commit Changes

- Stage ALL uncommitted changes with `git add .` (both staged and unstaged)
- Use the commit message suggested by the review (or user-provided message)
- Format the commit properly:

```bash
git commit -m "$(cat <<'EOF'
Your commit message here.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### 5. Confirm Success

- Run `git status` to verify the commit succeeded
- Run `git log -1` to show the user the committed changes
- Report success to the user

## Safety Rules

- NEVER commit files with secrets (.env, credentials.json, *.key, etc.)
- NEVER skip the review step
- NEVER force push
- NEVER update git config
- If the review finds security vulnerabilities, strongly recommend fixing before committing

## Example Flow

```
User: /review-and-commit add login validation

1. Claude gathers ALL uncommitted changes (staged + unstaged)
2. Claude spawns Sonnet subagent with the complete diff
3. Subagent reviews and returns:
   - Issues: None
   - Summary: Adds input validation to login form
   - Suggested commit: "Add input validation to login form fields"
4. Claude shows review to user
5. Claude stages ALL changes and commits with the suggested message
6. Claude confirms: "Committed: abc123 - Add input validation to login form fields"
```
