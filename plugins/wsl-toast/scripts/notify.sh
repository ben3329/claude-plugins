#!/usr/bin/env bash
# Claude Code hook -> Windows toast notification (WSL2)
# Reads hook JSON from stdin, extracts message/event/cwd, fires a Windows toast.
# Clicking the toast focuses the VSCode window for this session's workspace.

# Only meaningful under WSL with powershell.exe reachable.
grep -qi microsoft /proc/version 2>/dev/null || exit 0
command -v powershell.exe >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input="$(cat)"
get() { printf '%s' "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('$1',''))" 2>/dev/null; }

event="$(get hook_event_name)"
msg="$(get message)"
cwd="$(get cwd)"

[ -z "$cwd" ] && cwd="$PWD"
target="$(basename "$cwd")"      # VSCode window title contains the workspace folder name

case "$event" in
  Stop)         [ -z "$msg" ] && msg="작업이 끝났습니다" ;;
  Notification) [ -z "$msg" ] && msg="입력 대기 중" ;;
  *)            [ -z "$msg" ] && msg="알림" ;;
esac

title="Claude Code · $target"

ps1_win="$(wslpath -w "$SCRIPT_DIR/notify-toast.ps1")"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps1_win" \
  -Title "$title" -Message "$msg" -Target "$target" >/dev/null 2>&1 &

exit 0
