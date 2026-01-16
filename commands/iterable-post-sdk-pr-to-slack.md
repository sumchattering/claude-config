---
description: Post a PR link to the eng-sdk-team Slack channel
argument-hint: <pr-url>
allowed-tools: mcp__slack__send_message, Bash
---

# Post SDK PR to Slack

Post a pull request link to the `eng-sdk-team` Slack channel with standard formatting.

## Channel Details

- **Channel**: `eng-sdk-team`
- **Channel ID**: `C0956CRHEE6`

## Instructions

1. **Get the PR URL**: Use the argument provided: `$ARGUMENTS`. If no argument is provided:
   - Check the recent conversation context for a PR URL
   - Or run `gh pr list --state open --limit 1 --json url,title` to get the most recent open PR

2. **Detect SDK Type**: Determine if this is a Swift or Android PR:
   - **Swift**: URL contains `iterable-swift-sdk` or `iterable-ios-sdk`
   - **Android**: URL contains `iterable-android-sdk`

3. **Extract PR Info**: From the PR URL, get the PR title/description using `gh pr view <url> --json title`

4. **Extract Ticket Number**: Look for a Jira ticket number (e.g., `MOB-1234`) in the PR title or branch name. Format it in square brackets like `[MOB-1234]`.

5. **Post to Slack**: Use the Slack MCP `slack_send_message` tool with channel_id `C0956CRHEE6`:

   **For Swift PRs:**
   ```
   <PR_URL> [TICKET-NUMBER] <brief description> :apple: :twisted_rightwards_arrows: :pr-fresh: @joao.dordio @Jena @Akshay
   ```

   **For Android PRs:**
   ```
   <PR_URL> [TICKET-NUMBER] <brief description> :android: :twisted_rightwards_arrows: :pr-fresh: @joao.dordio @Jena @Akshay
   ```

## Examples

**Swift PR:**
```
https://github.com/Iterable/iterable-swift-sdk/pull/994 [MOB-1234] PR for fixing the carthage build issues :apple: :twisted_rightwards_arrows: :pr-fresh: @joao.dordio @Jena @Akshay
```

**Android PR:**
```
https://github.com/Iterable/iterable-android-sdk/pull/500 [MOB-5678] Add new inbox feature :android: :twisted_rightwards_arrows: :pr-fresh: @joao.dordio @Jena @Akshay
```

6. **Confirm**: Report success or any errors to the user.
