#!/usr/bin/env bash
# SessionStart hook for the brown plugin.
# Checks whether the local plugin checkout is up to date with its upstream
# branch and fast-forwards it when it is strictly behind.

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BROWN_STATE_DIR="${BROWN_STATE_DIR:-$HOME/.brown}"

sanitize_for_json() {
  printf '%s' "$1" | tr '\n\r\t' '   ' | tr -d '"\\'
}

telemetry_prompt() {
  # Emit a one-time opt-in directive if the user hasn't decided yet.
  [ -f "$BROWN_STATE_DIR/config" ] && return
  cat <<'PROMPT'
[brown:telemetry] The user has not yet chosen a telemetry preference. Before any other work in this session, use AskUserQuestion exactly once with this question: "brown 플러그인이 익명 사용 통계를 수집해도 될까요? (어떤 skill/command/agent가 실행됐는지, 플러그인 버전, OS만 — 코드나 경로는 포함되지 않습니다.)" with options "네, 수집해도 좋아요" and "아니요". After the user answers, run the matching shell command and nothing else: for yes -> `mkdir -p ~/.brown && echo on > ~/.brown/config`; for no -> `mkdir -p ~/.brown && echo off > ~/.brown/config`. Do not ask again in future sessions.
PROMPT
}

emit_context() {
  local msg
  msg=$(sanitize_for_json "$1")
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${msg}"
  }
}
EOF
}

check_and_update() {
  if ! command -v git >/dev/null 2>&1; then
    echo "brown plugin loaded (git unavailable; skipping update check)."
    return
  fi

  if ! git -C "$PLUGIN_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "brown plugin loaded (not a git checkout; skipping update check)."
    return
  fi

  local upstream
  upstream=$(git -C "$PLUGIN_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [ -z "$upstream" ]; then
    echo "brown plugin loaded (no upstream tracking branch; skipping update check)."
    return
  fi

  if ! timeout 10 git -C "$PLUGIN_ROOT" fetch --quiet 2>/dev/null; then
    echo "brown plugin loaded (could not reach remote; update check skipped)."
    return
  fi

  local local_sha remote_sha base
  local_sha=$(git -C "$PLUGIN_ROOT" rev-parse HEAD)
  remote_sha=$(git -C "$PLUGIN_ROOT" rev-parse "$upstream")

  if [ "$local_sha" = "$remote_sha" ]; then
    echo "brown plugin is up to date (${local_sha:0:7} == ${upstream})."
    return
  fi

  base=$(git -C "$PLUGIN_ROOT" merge-base HEAD "$upstream" 2>/dev/null || true)

  if [ "$base" = "$local_sha" ]; then
    if [ -n "$(git -C "$PLUGIN_ROOT" status --porcelain)" ]; then
      echo "brown plugin update available on ${upstream} but local changes detected; skipping auto-update."
      return
    fi
    if git -C "$PLUGIN_ROOT" merge --ff-only --quiet "$upstream" >/dev/null 2>&1; then
      echo "brown plugin updated ${local_sha:0:7} -> ${remote_sha:0:7} from ${upstream}. Restart Claude Code to load the new version."
    else
      echo "brown plugin update available on ${upstream} but fast-forward failed."
    fi
  elif [ "$base" = "$remote_sha" ]; then
    echo "brown plugin loaded (local is ahead of ${upstream})."
  else
    echo "brown plugin loaded (local and ${upstream} have diverged; manual review needed)."
  fi
}

msg=$(check_and_update)
tel_msg=$(telemetry_prompt)
if [ -n "$tel_msg" ]; then
  msg="$msg
$tel_msg"
fi
emit_context "$msg"
