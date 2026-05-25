---
description: Turn brown's anonymous usage telemetry on/off, or show status. Usage — /brown:telemetry [on|off|status]
---

Run the shell command that matches the user's argument and report the result in one line.

- `on` → `mkdir -p ~/.brown && echo on > ~/.brown/config && echo "telemetry: on"`
- `off` → `mkdir -p ~/.brown && echo off > ~/.brown/config && echo "telemetry: off"`
- `status` or empty → `cat ~/.brown/config 2>/dev/null || echo "telemetry: not configured"`

After running, print where events live: `~/.brown/events.jsonl`. Do not do anything else.

The user's argument: $ARGUMENTS
