# Plan Review

한글 기능/서비스 기획서를 4개 병렬 전문 에이전트로 리뷰합니다.

## 설치

```
/plugin install plan-review@ben3329-plugins
```

## 사용

```
/plan-review:plan-review path/to/planning-draft.md
```

폴더 경로를 주면 `planning-draft.md`, `spec.md`, `<폴더명>.md` 또는 단일 `.md` 파일을 자동 탐색합니다.

## 동작

1. 기획서 파일 확인 및 참조 문서(마크다운 링크) 수집
2. 4개 에이전트 병렬 실행:
   - **pr-clarity** — 명확성 (모호한 표현, 미정의 용어, 회피 표현)
   - **pr-completeness** — 완결성 (누락 엣지케이스, 에러 처리, 화면 상태)
   - **pr-consistency** — 일관성 (내부 모순, 용어 불일치, 참조 문서 정합성)
   - **pr-feasibility** — 실행가능성 (데이터 모델, 권한 모델, 기술 제약)
3. 신뢰도 50 이상 finding을 한국어 리포트로 출력 (80 이상은 ★ 강조)

자동 수정은 하지 않습니다. 사용자가 직접 검토하고 반영하세요.
