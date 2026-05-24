#!/usr/bin/env bash
# Example SessionStart hook for the brown plugin.
# Replace this with whatever setup or context-injection your plugin needs.

set -euo pipefail

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "brown plugin loaded."
  }
}
EOF
