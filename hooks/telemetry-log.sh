#!/usr/bin/env bash
# Append a brown-plugin telemetry event to ~/.brown/events.jsonl.
#
# Invoked from hooks.json with one of:
#   telemetry-log.sh --kind skill
#   telemetry-log.sh --kind agent
#   telemetry-log.sh --kind command
#
# Reads the hook JSON payload from stdin to extract the event name.
# Filters to brown-namespaced invocations only.
# Fails safe: always exits 0 so the session is never blocked.

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${BROWN_STATE_DIR:-$HOME/.brown}"
CONFIG_FILE="$STATE_DIR/config"
EVENTS_FILE="$STATE_DIR/events.jsonl"

KIND=""
while [ $# -gt 0 ]; do
  case "$1" in
    --kind) KIND="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

[ -z "$KIND" ] && exit 0

TIER="off"
[ -f "$CONFIG_FILE" ] && TIER="$(tr -d ' \n\r\t' < "$CONFIG_FILE" 2>/dev/null || echo off)"
[ "$TIER" = "on" ] || exit 0

PAYLOAD="$(cat 2>/dev/null || true)"
[ -z "$PAYLOAD" ] && exit 0

extract_json_string() {
  local key="$1" json="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r "$key // empty" 2>/dev/null
  else
    # Fallback: simple grep -o (handles flat string fields only)
    local pat="\"${key##*.}\":\"[^\"]*\""
    printf '%s' "$json" | grep -o "$pat" | head -1 | awk -F'"' '{print $4}'
  fi
}

NAME=""
case "$KIND" in
  skill)
    NAME="$(extract_json_string '.tool_input.skill' "$PAYLOAD")"
    ;;
  agent)
    NAME="$(extract_json_string '.tool_input.subagent_type' "$PAYLOAD")"
    ;;
  command)
    PROMPT="$(extract_json_string '.prompt' "$PAYLOAD")"
    # Match /brown:<name> at the start of the prompt
    NAME="$(printf '%s' "$PROMPT" | grep -oE '^/brown:[a-zA-Z0-9_-]+' | head -1 | sed 's|^/brown:||')"
    [ -n "$NAME" ] && NAME="brown:$NAME"
    ;;
esac

# Only record brown-namespaced events
case "$NAME" in
  brown:*) ;;
  *) exit 0 ;;
esac

# Strip the brown: prefix for the stored name
SHORT_NAME="${NAME#brown:}"

# Sanitize for JSON (strip quotes/backslashes/control chars, cap length)
sanitize() {
  printf '%s' "$1" | tr -d '"\\\n\r\t' | head -c 80
}
SHORT_NAME="$(sanitize "$SHORT_NAME")"
[ -z "$SHORT_NAME" ] && exit 0

PLUGIN_VERSION="unknown"
if [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
  PLUGIN_VERSION="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null | head -1 | sed -E 's/.*"([^"]*)"$/\1/')"
  PLUGIN_VERSION="${PLUGIN_VERSION:-unknown}"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"
OS="$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

printf '{"v":1,"ts":"%s","kind":"%s","name":"%s","plugin_version":"%s","os":"%s"}\n' \
  "$TS" "$KIND" "$SHORT_NAME" "$PLUGIN_VERSION" "$OS" \
  >> "$EVENTS_FILE" 2>/dev/null || true

# Fire-and-forget background sync (no waiting, no blocking)
SYNC="$PLUGIN_ROOT/hooks/telemetry-sync.sh"
if [ -x "$SYNC" ]; then
  ( "$SYNC" >/dev/null 2>&1 & )
fi

exit 0
