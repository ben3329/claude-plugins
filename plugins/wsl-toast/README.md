# wsl-toast

WSL2 환경에서 Claude Code가 **작업을 끝내거나(Stop)** **입력/권한을 기다릴 때(Notification)** Windows 토스트 알림을 띄웁니다. 토스트를 클릭하면 **그 세션의 VSCode 창**으로 포커스가 이동합니다 — 여러 워크스페이스 창을 동시에 띄워 둔 경우에 유용합니다.

## 동작 방식

```
Claude (Stop / Notification hook)
  └─ scripts/notify.sh        hook JSON에서 cwd·메시지 추출
       └─ notify-toast.ps1    "Claude Code · <폴더명>" 토스트 발사
                              (클릭 시 claudefocus:<폴더명> 프로토콜 실행)

토스트 클릭
  └─ claudefocus: 프로토콜  →  focus-launcher.vbs (창 없는 런처)
       └─ focus-window.ps1   제목에 <폴더명>이 든 VSCode 창을 복원 + 포그라운드
```

- 알림 제목에 워크스페이스 폴더명이 들어가 **어느 창 알림인지** 바로 구분됩니다.
- 클릭 시 콘솔 깜빡임이 없도록 `wscript.exe` + 숨김 VBS 런처를 경유합니다.
- `SessionStart` hook이 `claudefocus:` URL 프로토콜을 **멱등적으로** 등록합니다(경로가 바뀔 때만 `reg.exe` 실행).

## 요구 사항

- WSL2 (Windows). 비-WSL 환경에서는 모든 스크립트가 조용히 no-op 처리됩니다.
- `powershell.exe`, `reg.exe`, `wscript.exe` (Windows 기본 제공), `python3`, `wslpath`.
- VSCode 창 제목에 워크스페이스 폴더명이 포함되어 있어야 클릭 포커스가 동작합니다(기본값).

## 설치 후

플러그인 활성화 → **세션 재시작**(또는 새 창)하면 hook이 로드되고, SessionStart에서 프로토콜이 자동 등록됩니다. 이후 작업 완료/입력 대기 시 토스트가 뜹니다.

> 이미 `~/.claude/settings.json`에 동일한 Notification/Stop hook을 수동으로 넣어 두었다면, 알림이 중복되지 않도록 그 hook은 제거하세요.

## 제거

```bash
reg.exe delete "HKCU\\Software\\Classes\\claudefocus" /f
rm -rf "$HOME/.cache/claude-wsl-toast"
```
그리고 플러그인을 비활성화하면 됩니다.
