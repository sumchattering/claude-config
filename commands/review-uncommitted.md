---
description: Review all uncommitted changes (including submodules), optionally commit with --commit
argument-hint: [--commit] [context-hint]
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task]
---

# Review Uncommitted

This command reviews all uncommitted changes (staged + unstaged) in both the main repository and any submodules using a Sonnet subagent.

**Optional**: Pass `--commit` to commit the changes after review.

## Arguments

Optional: $ARGUMENTS

Can include:
- `--commit` - Commit changes after successful review
- A hint about what the changes are for (e.g., "add user authentication")
- A ticket number (e.g., "SDK-296")

## Instructions

When this command is invoked:

### 1. Parse Arguments

- Check if `--commit` flag is present in $ARGUMENTS
- Extract any remaining context/hints from $ARGUMENTS

### 2. Gather Context (Main Repo + Submodules)

**Main Repository:**
- Run `git status` to see current branch and changes
- Run `git diff` to see all uncommitted changes (both staged and unstaged)
- Run `git diff --cached` to see staged changes

**Submodules:**
- Run `git submodule status` to list all submodules
- For each submodule with changes, run:
  - `git -C <submodule-path> status`
  - `git -C <submodule-path> diff`
  - `git -C <submodule-path> diff --cached`

**Combined diff command for all changes:**
```bash
# Main repo changes
git diff
git diff --cached

# Submodule changes (recursive)
git submodule foreach --recursive 'git diff; git diff --cached'
```

- If no changes exist anywhere, inform the user and exit

### 3. Invoke Sonnet Subagent for Code Review

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

### Main Repository:
[Include git diff output from main repo]

### Submodules:
[Include git diff output from each submodule, labeled by submodule path]

## Context:
- Current branch: [branch name]
- Arguments/context from user: [user's context hints, excluding --commit flag]

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

### 4. Process Review Results

After receiving the review from the subagent:

- **If issues were found**:
  - Present the issues to the user
  - If `--commit` was specified, ask the user if they want to:
    1. Fix the issues now (you can help fix them)
    2. Commit anyway (acknowledge the issues)
    3. Abort
  - If user chooses to fix, apply the fixes and re-run the review

- **If LGTM (no blocking issues)**:
  - Show the user the review summary
  - If `--commit` was NOT specified, inform user: "Review complete. Run with `--commit` to commit these changes."
  - If `--commit` WAS specified, proceed to commit step

### 5. Stage and Commit Changes (only if --commit)

**Main Repository:**
- Stage ALL uncommitted changes with `git add -A`

**Submodules:**
- For each submodule with changes:
  ```bash
  git submodule foreach --recursive 'git add -A && git commit -m "<commit-message>" || true'
  ```
- After submodule commits, stage the submodule references in the main repo

**Main Repo Commit:**
```bash
git add -A
git commit -m "$(cat <<'EOF'
Your commit message here.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### 6. Confirm Success

- Run `git status` to verify the commit succeeded
- Run `git log -1` to show the user the committed changes
- If submodules were committed, also show their commit hashes
- Report success to the user

## Safety Rules

- NEVER commit files with secrets (.env, credentials.json, *.key, etc.)
- NEVER skip the review step
- NEVER update git config
- If the review finds security vulnerabilities, strongly recommend fixing before committing

## Example Flows

### Review Only (no --commit)
```
User: /review-uncommitted SDK-296 fix

1. Claude gathers ALL uncommitted changes from main repo + submodules
2. Claude spawns Sonnet subagent with the complete diff
3. Subagent reviews and returns LGTM
4. Claude shows review to user
5. Claude informs: "Review complete. Run `/review-uncommitted --commit` to commit."
```

### Review and Commit
```
User: /review-uncommitted --commit add login validation

1. Claude gathers ALL uncommitted changes from main repo + submodules
2. Claude spawns Sonnet subagent with the complete diff
3. Subagent reviews and returns:
   - Issues: None
   - Summary: Adds input validation to login form
   - Suggested commit: "Add input validation to login form fields"
4. Claude shows review to user
5. Claude stages and commits all changes (submodules first, then main repo)
6. Claude confirms: "Committed: abc123 - Add input validation to login form fields"
```
