---
description: Iterative code review loop on staged changes with 6 parallel specialized agents and adaptive model tiering. Fixes issues and repeats until clean.
argument-hint: "[fast|deep] [model=sonnet|opus|fable|haiku]"
allowed-tools: [Bash, Edit, Agent, Read, Glob, Grep]
---

Perform an iterative code review on all git staged changes using 6 specialized review agents in parallel. Models are selected per agent based on the complexity and blast radius of the diff. Fix identified issues and repeat until clean.

Arguments: $ARGUMENTS

## Workflow

Execute the following loop (max 5 iterations). Maintain a **triage ledger** across iterations: every finding you triage is recorded with (file, a stable identifier such as the function or variable name, description, verdict: Fixed | Skipped | Reported). Do NOT use line numbers as the ledger key — they shift after edits. The ledger prevents re-litigating findings (a finding skipped in iteration 1 must not be "fixed" in iteration 3) and accumulates Report items so none are lost between iterations.

### Step 1: Retrieve staged diff

Run `git diff --cached --stat` to get the list of changed files, and `git diff --cached` for the full diff. If empty, inform the user there are no staged changes and stop.

On the first iteration, also run `git diff --name-only` and record which files have **pre-existing unstaged changes** — Step 5 needs this list to preserve them when re-staging fixes.

Display the iteration header on EVERY iteration: `## Iteration N/5 — tier: <tier> (lines: X, files: Y, reach: Z, risk: yes/no)`. On iteration 1, print it after Step 2 computes the tier; on later iterations reuse the stored tier and signals.

### Step 2: Assess complexity and select models (first iteration only)

On the first iteration, classify the diff into a tier. Reuse the same tier for all subsequent iterations.

Compute three signals:

1. **SIZE**: total changed lines and number of changed files (from `--stat`)
2. **REACH**: extract up to 10 changed function/class/method names from the diff hunks (lines starting with `+`/`-` that define or rename a symbol, and hunk headers). Skip symbols that are shorter than 4 characters or too generic to grep meaningfully (e.g., get, set, run, init, main, data, update, handle). For each remaining symbol, run `grep -rlw --exclude-dir={.git,node_modules,vendor,dist,build,out,.venv,venv,target} <symbol>` at the repo root and count files OUTSIDE the changed file list that reference it. REACH = number of changed symbols with at least one external reference. Keep this fast — it is a heuristic to pick a tier, not the impact analysis itself.
3. **RISK**: whether any changed file path contains one of these keywords as a whole path segment or a distinct word in the filename: `auth|login|session|token|crypto|password|payment|billing|migration|schema|middleware|core|common|shared|config`. Match on segment/word boundaries, not raw substrings — `auth/handler.py` and `user_auth.py` count; `tsconfig.json` (config), `tokenizer.py` (token), and `score.js` (core) do not

Tier rules (first match wins):

- **deep**: changed lines > 500, OR changed files > 8, OR REACH ≥ 5, OR any RISK path matched
- **light**: changed lines < 100 AND changed files ≤ 3 AND REACH = 0
- **standard**: everything else

Model assignment per tier — pass via the Agent tool's `model` parameter:

| Agent | light | standard | deep |
|---|---|---|---|
| sr-bugs | sonnet | opus | fable |
| sr-impact | sonnet | opus | fable |
| sr-security | sonnet | sonnet | fable |
| sr-quality | sonnet | sonnet | opus |
| sr-performance | sonnet | sonnet | opus |
| sr-consistency | sonnet | sonnet | opus |

**User overrides** (from arguments above): `fast` forces the light tier, `deep` forces the deep tier, `model=<sonnet|opus|fable|haiku>` forces that model for ALL agents. If no arguments, use the computed tier. When a tier or model is forced, still compute the SIZE/REACH/RISK signals — they feed the iteration header and the sr-impact leads in Step 3 — except with `fast`, where the REACH grep may be skipped (show `reach: skipped` in the header and omit the sr-impact leads line).

### Step 3: Launch review agents in parallel

Launch ALL 6 agents simultaneously using the Agent tool, each with `subagent_type` set to the agent name and `model` set per the tier table.

If the staged diff is **under 200 lines**, pass the full diff to each agent. If **200 lines or more**, pass only the changed file list and instruct agents to fetch each file's staged hunks with `git diff --cached -- <file>` (Bash), then optionally use Read for full-file context.

Agents to launch (ALL in a single message, in parallel):
1. `staged-review:sr-bugs` — bugs, logic errors, edge cases
2. `staged-review:sr-security` — security vulnerabilities
3. `staged-review:sr-quality` — code quality, readability, maintainability
4. `staged-review:sr-performance` — performance issues, inefficiencies
5. `staged-review:sr-consistency` — project convention adherence
6. `staged-review:sr-impact` — cross-module impact: unchanged code broken by the staged changes

Prompt each agent with:
```
Review the staged git changes. The following agents are reviewing in parallel — stay strictly within your domain and do not report issues that belong to another agent's scope:
- sr-bugs: bugs, logic errors, null safety, edge cases, error handling
- sr-security: injection, auth, data exposure, input validation, crypto
- sr-quality: readability, maintainability, DRY, dead code
- sr-performance: algorithmic complexity, database, memory, I/O, caching
- sr-consistency: naming conventions, code patterns, project structure, CLAUDE.md
- sr-impact: breakage of unchanged code elsewhere — call sites, contracts, schemas, config consumers

{Either the full diff or the file list with instructions to read}
```

For `sr-impact` only, additionally append the REACH heuristic results from Step 2 as starting leads:
```
Heuristic scan found these changed symbols referenced outside the diff (verify each, and look for more — this list is not exhaustive): {symbol → referencing files}
```

### Step 4: Aggregate, deduplicate, and triage

Collect findings from all 6 agents. Apply the following:

1. **Deduplicate**: If multiple agents report the same issue (same file + overlapping lines + similar description), keep only the finding from the most relevant agent with the highest confidence.
2. **Drop ledger matches**: Drop any finding that matches a ledger entry with verdict Skipped or Reported — Skipped issues stay skipped (no verdict flip-flops) and Reported issues are already accumulated for the final report. If a finding matches a ledger entry with verdict **Fixed**, the earlier fix may have been incomplete: convert it once to **Report** ("fix applied but a reviewer still flags this") and change its ledger verdict to Reported; if it resurfaces again after that, drop it.

Then **you (the main agent) triage each remaining finding**. For every finding, read the relevant file and surrounding context, then decide:

- **Fix**: The issue is a genuine problem and you are confident in the fix. Apply it.
- **Skip**: The finding is a false positive, intentional code, or the suggested fix would introduce new problems. Drop it.
- **Report**: The issue may be real but the fix is ambiguous, risky, or requires the user's design decision. Keep it for the final report.

Record EVERY triaged finding in the ledger with its verdict.

Special rule for **sr-impact** findings: if the correct resolution is to update the affected UNCHANGED files (e.g., adapting call sites to a new signature), you must NOT edit them — never modify files outside the staged diff. Triage such findings as **Report**, listing every affected file/line so the user can decide. Only triage as **Fix** when the staged side can be adapted to preserve compatibility (e.g., keeping a default parameter, restoring a removed export).

Do NOT blindly apply fixes based on confidence scores alone — use your own judgment after reading the actual code.

Display a summary table:
```
### Review Results — Iteration N/5
Found X findings (Y total, Z duplicates removed, W already in ledger):
| # | Agent | File | Lines | Confidence | Verdict | Description |
|---|-------|------|-------|------------|---------|-------------|
| 1 | Bugs  | ... | ... | 85 | Fix | ... |
| 2 | Impact | ... | ... | 90 | Report (3 call sites affected) | ... |
| 3 | Quality | ... | ... | 80 | Report | ... |
```

### Step 5: Fix, report, or stop

**If NO findings were triaged as Fix this iteration:**

- If the ledger contains NO Reported items, print the following and STOP:
  ```
  Review complete. All staged changes are clean. (N iterations, tier: <tier>)
  ```
- If the ledger contains Reported items, print ALL accumulated Report items (from every iteration, not just this one) as a list for the user to review manually, then STOP.

**If findings were triaged as Fix:**

1. **Preserve unstaged changes FIRST**: check whether any file you are about to fix is on the pre-existing-unstaged list from Step 1. If yes, run `git stash push --keep-index` BEFORE applying any Edit. (Order matters: stashing after editing would sweep your fixes into the stash — `--keep-index` resets the working tree to the index — so the fixes would never be staged.)
2. Apply fixes for all findings triaged as **Fix** using Edit. If you stashed in item 1, the stash reset the working tree — re-Read each affected file AFTER the stash before editing; content read during triage may be stale
3. Re-stage the modified files with `git add <file>`
4. If you stashed in item 1, run `git stash pop`. If the pop reports conflicts (the user's unstaged hunks overlap the fixed lines), do NOT resolve them silently: run `git checkout --ours -- <file>` followed by `git add <file>` — the fix lives in the "ours" side of the conflict; this restores the fixed content to the working tree and resolves the index. Then tell the user their unstaged changes are preserved in the stash (`git stash list`) and can be recovered with `git stash pop` after the review.
5. **Verify staging**: run `git diff --cached -- <file>` and confirm the applied fixes are actually in the index. If a fix is missing, stop the loop, print all accumulated Report items from the ledger, and report the problem to the user — never let the loop end with a false "clean" verdict.
6. Confirm each fixed issue is recorded in the ledger as Fixed
7. If this was iteration 5, go to Step 6; otherwise return to Step 1 for the next iteration.

### Step 6: Max iterations

If 5 iterations reached with remaining issues, list the unfixed issues plus ALL accumulated Report items from the ledger and STOP.

## Rules

- All user-facing output (summary tables, reports, messages) must be in the user's language. Detect the language from the user's most recent message. Internal agent prompts remain in English, and agent findings are returned in English — translate Description/Suggestion fields when presenting them to the user.
- Never modify files outside the staged diff (files with no staged changes) — impact findings that require touching such files are always Report, never Fix
- Never remove or revert the user's original staged changes — only improve them
- When a fix is ambiguous or risky, skip it and report it to the user instead
- The final message must always include every ledger entry with verdict Reported — Report items from early iterations must never be silently lost
- Track and display iteration count and tier at each step
- Prefer minimal, targeted fixes over large refactors
