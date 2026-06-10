# Staged Review

Iterative code review loop for git staged changes using 6 specialized parallel review agents with adaptive model tiering.

## Installation

```
/plugin install staged-review@ben3329-plugins
```

## Usage

Once installed, stage your changes and run:

```
/staged-review:staged-review
```

Options:

```
/staged-review:staged-review fast          # force light tier (all sonnet)
/staged-review:staged-review deep          # force deep tier (fable/opus)
/staged-review:staged-review model=opus    # force one model for all agents
```

## How it works

1. Reads `git diff --cached` to get staged changes
2. Assesses complexity (size, blast radius, risky paths) and picks a tier — **light / standard / deep** — which decides each agent's model (sonnet → opus → fable)
3. Launches 6 review agents in parallel:
   - **sr-bugs** — bugs, logic errors, edge cases (verifies assumptions by reading callee definitions)
   - **sr-security** — security vulnerabilities (traces taint flow across files)
   - **sr-quality** — code quality, readability, maintainability (repository-wide DRY check)
   - **sr-performance** — performance issues (reads called functions for hidden I/O and N+1)
   - **sr-consistency** — project convention adherence (quantifies conventions via repo-wide counts)
   - **sr-impact** — cross-module impact: traces callers, contracts, schemas, and config consumers of changed symbols to find unchanged code broken by the diff
4. Main agent triages each finding (Fix / Skip / Report). Impact findings that require touching unstaged files are always reported, never auto-fixed
5. Fixes confirmed issues and repeats (max 5 iterations) until clean

## Model tiering

| Tier | Trigger | sr-bugs / sr-impact | sr-security | others |
|------|---------|--------------------|-------------|--------|
| light | <100 lines, ≤3 files, no external references | sonnet | sonnet | sonnet |
| standard | default | opus | sonnet | sonnet |
| deep | >500 lines, >8 files, reach ≥5, or risky paths (auth/payment/schema/…) | fable | fable | opus |
