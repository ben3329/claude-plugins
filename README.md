# Claude Plugins

A collection of Claude Code plugins by ben3329.

## Plugins

| Plugin | Description |
|--------|-------------|
| [dokhae](plugins/dokhae/) | 국어 비문학 독해 훈련: 난이도별 지문 생성, 문제풀이·요약·속독, 기록 기반 약점 분석 |
| [staged-review](plugins/staged-review/) | Iterative code review loop for git staged changes using 6 specialized parallel review agents with adaptive model tiering |
| [skill-review](plugins/skill-review/) | Iterative quality review loop for Claude Code skills using 4 specialized parallel review agents |
| [plan-review](plugins/plan-review/) | 한글 기능/서비스 기획서를 4개 병렬 에이전트로 리뷰 (명확성, 완결성, 일관성, 실행가능성) |
| [wsl-toast](plugins/wsl-toast/) | WSL2에서 작업 완료/입력 대기 시 Windows 토스트 알림 + 클릭 시 VSCode 포커스 |
| [naming](plugins/naming/) | 앱·서비스 이름을 4개 전략별 생성 에이전트로 만들고 Neumeier 7기준+SMILE/SCRATCH로 랭킹, 도메인·상표·다국어 가용성까지 점검 |

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
