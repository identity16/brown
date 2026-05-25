#!/usr/bin/env bash
# Sync ~/.brown/events.jsonl to a remote ingest endpoint.
#
# Fire-and-forget, rate-limited to once per 5 minutes, cursor-based dedup.
# Env:
#   BROWN_TELEMETRY_URL — full POST URL of the ingest endpoint
#   BROWN_TELEMETRY_KEY — optional auth key (sent as `x-brown-key` header)
# If BROWN_TELEMETRY_URL is unset, the script is a no-op (local-only mode).

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${BROWN_STATE_DIR:-$HOME/.brown}"
CONFIG_FILE="$STATE_DIR/config"
EVENTS_FILE="$STATE_DIR/events.jsonl"
CURSOR_FILE="$STATE_DIR/.cursor"
RATE_FILE="$STATE_DIR/.last-sync"

# Source the shipped endpoint config when env vars aren't already set.
if [ -z "${BROWN_TELEMETRY_URL:-}" ] && [ -f "$PLUGIN_ROOT/hooks/telemetry-config.sh" ]; then
  # shellcheck source=telemetry-config.sh
  . "$PLUGIN_ROOT/hooks/telemetry-config.sh" 2>/dev/null || true
fi

URL="${BROWN_TELEMETRY_URL:-}"
KEY="${BROWN_TELEMETRY_KEY:-}"

# Local-only mode — nothing to do
[ -z "$URL" ] && exit 0
[ -f "$EVENTS_FILE" ] || exit 0
command -v curl >/dev/null 2>&1 || exit 0

TIER="off"
[ -f "$CONFIG_FILE" ] && TIER="$(tr -d ' \n\r\t' < "$CONFIG_FILE" 2>/dev/null || echo off)"
[ "$TIER" = "on" ] || exit 0

# Rate limit: 5 minutes
if [ -f "$RATE_FILE" ]; then
  STALE="$(find "$RATE_FILE" -mmin +5 2>/dev/null || true)"
  [ -z "$STALE" ] && exit 0
fi

# Cursor — number of lines already sent
CURSOR=0
if [ -f "$CURSOR_FILE" ]; then
  CURSOR="$(tr -d ' \n\r\t' < "$CURSOR_FILE" 2>/dev/null || echo 0)"
  case "$CURSOR" in *[!0-9]*) CURSOR=0 ;; esac
fi

TOTAL="$(wc -l < "$EVENTS_FILE" 2>/dev/null | tr -d ' \n\r\t' || echo 0)"
case "$TOTAL" in *[!0-9]*) TOTAL=0 ;; esac

# If cursor is past the end (e.g. file truncated), reset
if [ "$CURSOR" -gt "$TOTAL" ] 2>/dev/null; then
  CURSOR=0
fi
[ "$CURSOR" -ge "$TOTAL" ] 2>/dev/null && exit 0

SKIP=$(( CURSOR + 1 ))
UNSENT="$(tail -n "+$SKIP" "$EVENTS_FILE" 2>/dev/null || true)"
[ -z "$UNSENT" ] && exit 0

# Build a JSON array body, capped at 100 events per batch
BATCH="["
FIRST=true
COUNT=0
while IFS= read -r LINE; do
  [ -z "$LINE" ] && continue
  case "$LINE" in '{'*) ;; *) continue ;; esac
  if [ "$FIRST" = "true" ]; then
    FIRST=false
  else
    BATCH="$BATCH,"
  fi
  BATCH="$BATCH$LINE"
  COUNT=$(( COUNT + 1 ))
  [ "$COUNT" -ge 100 ] && break
done <<EOF
$UNSENT
EOF
BATCH="$BATCH]"
[ "$COUNT" -eq 0 ] && exit 0

HEADERS=( -H "Content-Type: application/json" )
[ -n "$KEY" ] && HEADERS+=( -H "x-brown-key: $KEY" )

HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
  -X POST "$URL" \
  "${HEADERS[@]}" \
  -d "$BATCH" 2>/dev/null || echo 000)"

case "$HTTP_CODE" in
  2*)
    NEW_CURSOR=$(( CURSOR + COUNT ))
    echo "$NEW_CURSOR" > "$CURSOR_FILE" 2>/dev/null || true
    ;;
esac

touch "$RATE_FILE" 2>/dev/null || true
exit 0
