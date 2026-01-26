---
description: Show my Jira tickets with triage preferences applied
argument-hint: "[project-filter]"
allowed-tools: [mcp__jira__jira_search_issues, mcp__jira__jira_get_my_issues]
---

# Jira Triage

This command displays my assigned Jira tickets with my preferred formatting and sorting.

## Arguments

Optional: $ARGUMENTS

Can include:
- A project filter (e.g., "SDK" to show only SDK project tickets)

## Display Preferences

### Filtering
- Exclude tickets with status "Done"
- Exclude tickets with status "Won't Fix"
- Only show active/open tickets

### Sorting (in order of priority)
1. **First sort by Sprint**: Tickets in the current active sprint should appear at the top
2. **Second sort by Priority**: Within each group (in-sprint vs not-in-sprint), sort by priority (Highest > High > Medium > Low > Lowest)

### Columns to Display
Show a table with these columns:
| Key | Summary | Status | Priority | In Sprint |

### Sprint Indicator
- Use a bullet point `•` to indicate tickets that are in the current active sprint
- Do NOT use emojis or checkmarks

### Additional Info
- Show a count of total active tickets at the bottom
- Show a count of tickets in the current sprint
- If the user is on a git branch that matches a ticket (e.g., `feature/SDK-294-*`), highlight that ticket in bold

## Instructions

When this command is invoked:

### 1. Fetch Active Sprint Tickets

```
JQL: assignee = currentUser() AND status NOT IN (Done) AND sprint in openSprints() ORDER BY priority DESC
Fields: key, summary, status, priority, sprint
```

### 2. Fetch All Active Tickets

```
JQL: assignee = currentUser() AND status != Done ORDER BY priority DESC
Fields: key, summary, status, priority
```

### 3. Combine and Sort Results

1. Create a set of ticket keys that are in the active sprint
2. Sort all tickets:
   - Sprint tickets first (sorted by priority)
   - Non-sprint tickets second (sorted by priority)
3. Filter out "Won't Fix" status tickets from the display

### 4. Format Output

**IMPORTANT: You MUST display results as a markdown table.** Do NOT use a list format.

Use this exact table structure:
```
| Key | Summary | Status | Priority | Sprint |
|-----|---------|--------|----------|--------|
| SDK-XXX | Description here | Status | Priority | • |
```

- Truncate long summaries to ~50 chars with "..." if needed
- Bold the Key column if it matches the current git branch
- Use `•` in the Sprint column for tickets in the active sprint, leave empty otherwise

### 5. Show Summary

- Total active tickets count
- Tickets in sprint count
- Note about current branch if it matches a ticket

## Example Output

```
| Key | Summary | Status | Priority | In Sprint |
|-----|---------|--------|----------|-----------|
| **SDK-294** | Review iOS SDK Keychain handling | In Review | High | • |
| SDK-323 | iOS JWT 401 concurrent refresh | Selected for Development | Medium | • |
| SDK-314 | RN Embedded Bug Bash | In Progress | Medium | • |
| SDK-1 | BCIT Test setup | Long term | High | |
| SDK-297 | Support disablePush in OfflineManager | Open | Medium | |

**6 tickets** in the current active sprint.
**18 total active tickets.**
```
