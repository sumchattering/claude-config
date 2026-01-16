---
description: Review code changes using a Sonnet subagent without committing
argument-hint: [optional: context-hint]
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task]
---

# Review

This command reviews your code changes using a Sonnet subagent and provides feedback. It does NOT commit or push any changes.

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

3. If the code looks good with no blocking issues, say "LGTM" (Looks Good To Me).

Be concise and actionable. Focus on real issues, not nitpicks.
```

### 3. Present Review Results

After receiving the review from the subagent:

- Present the full review to the user
- If issues were found, offer to help fix them
- If LGTM, inform the user the code is ready to commit

**Note**: This command does NOT commit. The user can use `/review-and-commit` or `git commit` manually after reviewing.

## Example Flow

```
User: /review add login validation

1. Claude gathers ALL uncommitted changes (staged + unstaged)
2. Claude spawns Sonnet subagent with the complete diff
3. Subagent reviews and returns:
   - Issues: None
   - Summary: Adds input validation to login form
4. Claude shows review to user
5. Claude informs user: "Code looks good! Use /review-and-commit or git commit to commit your changes."
```
