# Claude Plugins

A collection of Claude Code plugins by ben3329.

## Plugins

| Plugin | Description |
|--------|-------------|
| [staged-review](plugins/staged-review/) | Iterative code review loop for git staged changes using 5 specialized parallel review agents |
| [skill-review](plugins/skill-review/) | Iterative quality review loop for Claude Code skills using 4 specialized parallel review agents |

## Installation

```
/plugin install <plugin-name>@ben3329-plugins
```

## Plugin Structure

```
plugins/
└── plugin-name/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── agents/
    ├── commands/
    ├── skills/
    └── README.md
```
