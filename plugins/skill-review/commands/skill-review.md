---
description: Iterative skill review loop with 4 parallel specialized agents. Reviews discoverability, structure, clarity, and best practices. Fixes issues and repeats until clean.
argument-hint: <path-to-skill-file-or-directory>
allowed-tools: [Bash, Edit, Agent, Read, Glob, Grep]
---

Perform an iterative quality review on a Claude Code skill using 4 specialized review agents in parallel. Fix identified issues and repeat until clean.

The argument is `$ARGUMENTS` — the path to a skill file (`*.md`) or a directory containing one.

## Workflow

Execute the following loop (max 5 iterations). Maintain a **seen issues list** across iterations to track previously encountered issues by (file, lines, description). If an issue was already fixed in a prior iteration but reappears, skip it to prevent oscillation.

### Step 1: Resolve the skill file

From `$ARGUMENTS`, determine the target skill `.md` file:

1. If the argument is empty, ask the user to provide a skill path and stop.
2. If the path is a `.md` file, use it directly.
3. If the path is a directory:
   - Look for `SKILL.md` (case-insensitive) first.
   - Otherwise, look for `<dirname>.md` matching the directory name.
   - Otherwise, if exactly one `.md` file exists in the directory, use it.
   - Otherwise, list candidate `.md` files and ask the user which one to review, then stop.
4. Verify the file exists and contains YAML frontmatter (lines starting with `---`). If not, inform the user and stop.

Display: `## Iteration N/5 — Reviewing <path>`

### Step 2: Launch review agents in parallel

Launch ALL 4 agents simultaneously using the Agent tool, each with `subagent_type` set to the agent name. Pass each agent the resolved skill file path and the file contents.

Agents to launch (ALL in a single message, in parallel):
1. `skill-review:sk-discoverability` — frontmatter description triggering, name quality
2. `skill-review:sk-structure` — frontmatter validity, required fields, file organization, path references
3. `skill-review:sk-clarity` — body readability, instruction precision, ambiguity
4. `skill-review:sk-best-practices` — progressive disclosure, examples, conciseness, anti-patterns

Prompt each agent with:
```
Review this Claude Code skill file. The following agents are reviewing in parallel — stay strictly within your domain and do not report issues that belong to another agent's scope:
- sk-discoverability: frontmatter description triggering, name quality
- sk-structure: frontmatter syntax, required fields, file organization, path references
- sk-clarity: body content readability, instruction precision, ambiguity
- sk-best-practices: progressive disclosure, examples, conciseness, anti-patterns

Skill path: <resolved path>

<full file contents>
```

### Step 3: Aggregate, deduplicate, and triage

Collect findings from all 4 agents. Apply the following:

1. **Deduplicate**: If multiple agents report the same issue (same file + overlapping lines + similar description), keep only the finding from the most relevant agent with the highest confidence.
2. **Skip seen**: Drop any finding that matches a previously fixed issue from the seen issues list.

Then **you (the main agent) triage each remaining finding**. For every finding, read the relevant section of the skill file and any referenced bundled files, then decide:

- **Fix**: The issue is a genuine problem and you are confident in the fix. Apply it.
- **Skip**: The finding is a false positive, intentional choice, or the suggested fix would introduce new problems. Drop it.
- **Report**: The issue may be real but the fix is ambiguous, risky, or requires the user's design decision (e.g., a major restructure or splitting the skill into bundled files). Keep it for the final report.

Do NOT blindly apply fixes based on confidence scores alone — use your own judgment after reading the actual content.

Display a summary table:
```
### Review Results — Iteration N/5
Found X findings (Y total, Z duplicates removed, W previously seen):
| # | Agent | Field/Lines | Confidence | Verdict | Description |
|---|-------|-------------|------------|---------|-------------|
| 1 | Discoverability | description | 85 | Fix | ... |
| 2 | Structure | frontmatter | 70 | Skip (intentional) | ... |
| 3 | Clarity | 42-58 | 80 | Report | ... |
```

### Step 4: Fix, report, or stop

**If NO findings triaged as Fix or Report:**
Print the following and STOP:
```
Review complete. Skill is clean. (N iterations)
```

**If findings exist:**

1. Apply fixes for all findings triaged as **Fix** by reading the relevant file and using Edit
2. Add each fixed issue to the **seen issues list**
3. If any findings were triaged as **Report**, list them at the end as items for the user to review manually
4. If fixes were applied, return to Step 1 with the same path. If only Report items remain, STOP.

### Step 5: Max iterations

If 5 iterations reached with remaining issues, list the unfixed issues and STOP.

## Rules

- All user-facing output (summary tables, reports, messages) must be in the user's language. Detect the language from the user's most recent message. Internal agent prompts remain in English.
- Never modify files outside the skill being reviewed unless a referenced bundled file is genuinely broken and the user explicitly asked for a wider review
- Preserve the user's original intent — improve clarity and fix issues, do not rewrite the skill's purpose
- When a fix is ambiguous or would significantly change scope (e.g., splitting into bundled files), skip it and report it to the user instead
- Track and display iteration count at each step
- Prefer minimal, targeted edits over large rewrites
