# Skill Review

Iterative quality review loop for Claude Code skills using 4 specialized parallel review agents.

## Installation

```
/plugin install skill-review@ben3329-plugins
```

## Usage

Run the command with a path to a skill file or directory:

```
/skill-review:skill-review path/to/skill.md
/skill-review:skill-review path/to/skill-dir/
```

If you pass a directory, the command resolves to `SKILL.md`, `<dirname>.md`, or the only `.md` file inside it.

## How it works

1. Resolves the target skill `.md` file from the given path
2. Launches 4 review agents in parallel:
   - **sk-discoverability** — frontmatter description triggering, name quality
   - **sk-structure** — frontmatter validity, required fields, file organization, path references
   - **sk-clarity** — body readability, instruction precision, ambiguity
   - **sk-best-practices** — progressive disclosure, examples, conciseness, anti-patterns
3. Main agent triages each finding (Fix / Skip / Report)
4. Fixes confirmed issues and repeats (max 5 iterations) until clean
