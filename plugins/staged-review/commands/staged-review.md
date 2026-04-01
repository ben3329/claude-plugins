---
description: Iterative code review loop on staged changes with 5 parallel specialized agents. Fixes issues and repeats until clean.
---

Perform an iterative code review on all git staged changes using 5 specialized review agents in parallel. Fix identified issues and repeat until clean.

## Workflow

Execute the following loop (max 5 iterations). Maintain a **seen issues list** across iterations to track previously encountered issues by (file, lines, description). If an issue was already fixed in a prior iteration but reappears, skip it to prevent oscillation.

### Step 1: Retrieve staged diff

Run `git diff --cached --stat` to get the list of changed files, and `git diff --cached` for the full diff. If empty, inform the user there are no staged changes and stop.

Display: `## Iteration N/5`

### Step 2: Launch review agents in parallel

Launch ALL 5 agents simultaneously using the Agent tool, each with `subagent_type` set to the agent name.

If the staged diff is **under 200 lines**, pass the full diff to each agent. If **200 lines or more**, pass only the changed file list and instruct agents to read the files themselves using the Read tool and `git diff --cached -- <file>`.

Agents to launch (ALL in a single message, in parallel):
1. `staged-review:sr-bugs` — bugs, logic errors, edge cases
2. `staged-review:sr-security` — security vulnerabilities
3. `staged-review:sr-quality` — code quality, readability, maintainability
4. `staged-review:sr-performance` — performance issues, inefficiencies
5. `staged-review:sr-consistency` — project convention adherence

Prompt each agent with:
```
Review the staged git changes. The following agents are reviewing in parallel — stay strictly within your domain and do not report issues that belong to another agent's scope:
- sr-bugs: bugs, logic errors, null safety, edge cases, error handling
- sr-security: injection, auth, data exposure, input validation, crypto
- sr-quality: readability, maintainability, DRY, dead code
- sr-performance: algorithmic complexity, database, memory, I/O, caching
- sr-consistency: naming conventions, code patterns, project structure, CLAUDE.md

{Either the full diff or the file list with instructions to read}
```

### Step 3: Aggregate, deduplicate, and triage

Collect findings from all 5 agents. Apply the following:

1. **Deduplicate**: If multiple agents report the same issue (same file + overlapping lines + similar description), keep only the finding from the most relevant agent with the highest confidence.
2. **Skip seen**: Drop any finding that matches a previously fixed issue from the seen issues list.

Then **you (the main agent) triage each remaining finding**. For every finding, read the relevant file and surrounding context, then decide:

- **Fix**: The issue is a genuine problem and you are confident in the fix. Apply it.
- **Skip**: The finding is a false positive, intentional code, or the suggested fix would introduce new problems. Drop it.
- **Report**: The issue may be real but the fix is ambiguous, risky, or requires the user's design decision. Keep it for the final report.

Do NOT blindly apply fixes based on confidence scores alone — use your own judgment after reading the actual code.

Display a summary table:
```
### Review Results — Iteration N/5
Found X findings (Y total, Z duplicates removed, W previously seen):
| # | Agent | File | Lines | Confidence | Verdict | Description |
|---|-------|------|-------|------------|---------|-------------|
| 1 | Bugs  | ... | ... | 85 | Fix | ... |
| 2 | Security | ... | ... | 90 | Skip (false positive) | ... |
| 3 | Quality | ... | ... | 80 | Report | ... |
```

### Step 4: Fix, report, or stop

**If NO findings triaged as Fix or Report:**
Print the following and STOP:
```
Review complete. All staged changes are clean. (N iterations)
```

**If findings exist:**

1. Apply fixes for all findings triaged as **Fix** by reading the relevant file and using Edit
2. Add each fixed issue to the **seen issues list**
3. After fixing, re-stage only the fixed hunks: for each fixed file, run `git diff <file> | git apply --cached` to stage only the new changes without pulling in pre-existing unstaged hunks. If the file had no prior unstaged changes, `git add <file>` is acceptable.
4. If any findings were triaged as **Report**, list them at the end as items for the user to review manually
5. If fixes were applied, return to Step 1. If only Report items remain, STOP.

### Step 5: Max iterations

If 5 iterations reached with remaining issues, list the unfixed issues and STOP.

## Rules

- All review output must be in English
- Never modify unstaged files
- Never remove or revert the user's original staged changes — only improve them
- When a fix is ambiguous or risky, skip it and report it to the user instead
- Track and display iteration count at each step
- Prefer minimal, targeted fixes over large refactors
