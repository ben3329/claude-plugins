# Staged Review

Iterative code review loop for git staged changes using 5 specialized parallel review agents.

## Installation

```
/plugin install staged-review@ben3329-plugins
```

## Usage

Once installed, stage your changes and run:

```
/staged-review:staged-review
```

## How it works

1. Reads `git diff --cached` to get staged changes
2. Launches 5 review agents in parallel:
   - **sr-bugs** — bugs, logic errors, edge cases
   - **sr-security** — security vulnerabilities
   - **sr-quality** — code quality, readability, maintainability
   - **sr-performance** — performance issues, inefficiencies
   - **sr-consistency** — project convention adherence
3. Main agent triages each finding (Fix / Skip / Report)
4. Fixes confirmed issues and repeats (max 5 iterations) until clean
