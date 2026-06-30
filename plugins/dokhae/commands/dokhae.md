---
description: 국어 비문학 독해 훈련을 시작합니다 (문제풀이·요약·속독·통계)
argument-hint: "[quiz|summary|speed|stats] [난이도 1-5]"
allowed-tools: [Bash, Read]
---

`dokhae-trainer` 스킬을 로드해 국어 비문학 독해 훈련 세션을 진행하세요.

요청 인자: `$ARGUMENTS`

처리 방법:

- 첫 번째 토큰이 `quiz` / `summary` / `speed` / `stats` 중 하나면 그 모드로 시작합니다.
  - `quiz`: 비문학 문제풀이 (사실·추론·구조·어휘·비판)
  - `summary`: 요약·핵심 추출
  - `speed`: 속독 + 이해도 측정
  - `stats`: 누적 기록 분석(추이·약점·추천)
- 두 번째 토큰이 숫자(1–5)면 난이도(level)로 사용합니다. 없으면 기본 3(표준).
- 인자가 비어 있거나 모드가 불분명하면 사용자에게 모드와 난이도를 짧게 물어보세요.

스킬의 공유 사양(`_spec.md`)과 해당 모드 reference의 절차·채점 루브릭을 그대로 따르고,
`stats`는 읽기 전용으로 종료하세요. `quiz`/`summary`/`speed` 세션이 끝나면 결과를
`~/.claude/dokhae/records.jsonl`에 기록하세요.
