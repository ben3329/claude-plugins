---
description: Iterative code review loop on staged changes with 5 parallel specialized agents. Fixes issues and repeats until clean.
---

Perform an iterative code review on all git staged changes using 5 specialized review agents in parallel. Fix identified issues and repeat until clean.

## Workflow

Execute the following loop (max 5 iterations):

### Step 1: Retrieve staged diff

Run `git diff --cached` to get staged changes. If empty, inform the user there are no staged changes and stop.

Display: `## Iteration N/5`

### Step 2: Launch review agents in parallel

Launch ALL 5 agents simultaneously using the Agent tool, each with `subagent_type` set to the agent name. Pass each the full staged diff output.

Agents to launch (ALL in a single message, in parallel):
1. `staged-review:sr-bugs` — bugs, logic errors, edge cases
2. `staged-review:sr-security` — security vulnerabilities
3. `staged-review:sr-quality` — code quality, readability, maintainability
4. `staged-review:sr-performance` — performance issues, inefficiencies
5. `staged-review:sr-consistency` — project convention adherence

Prompt each agent with:
```
Review the following staged git diff. Read full files for context as needed. Return findings with confidence scores.

<staged-diff>
{the git diff --cached output}
</staged-diff>
```

### Step 3: Aggregate and filter

Collect findings from all 5 agents. Keep ONLY findings with confidence >= 80.

Display a summary table:
```
### Review Results — Iteration N/5
Found X issues (from Y total findings):
| # | Agent | File | Lines | Confidence | Description |
|---|-------|------|-------|------------|-------------|
| 1 | Bugs  | ... | ... | 85 | ... |
| 2 | Security | ... | ... | 90 | ... |
```

### Step 4: Fix or stop

**If NO issues with confidence >= 80:**
Print the following and STOP:
```
Review complete. All staged changes are clean. (N iterations)
```

**If issues found:**
1. Fix each issue by reading the relevant file and applying the suggested fix using Edit
2. After fixing ALL issues, stage the changed files: `git add <each-fixed-file>`
3. Return to Step 1

### Step 5: Max iterations

If 5 iterations reached with remaining issues, list the unfixed issues and STOP.

## Rules

- All review output must be in English
- Never modify unstaged files
- Never remove or revert the user's original staged changes — only improve them
- When a fix is ambiguous or risky, skip it and report it to the user instead
- Track and display iteration count at each step
- Prefer minimal, targeted fixes over large refactors
