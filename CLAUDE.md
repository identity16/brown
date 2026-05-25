# brown

This repo is a **Claude Code plugin**, distributed through its own marketplace
manifest. Treat it as plugin source code, not an application.

## Layout

```
.claude-plugin/
  plugin.json         # Plugin manifest (name, version, component paths)
  marketplace.json    # Marketplace manifest (this repo distributes itself)
commands/             # Slash commands (one .md per command)
agents/               # Subagents (one .md per agent)
skills/<name>/SKILL.md  # Skills (one folder per skill)
hooks/
  hooks.json          # Hook event -> command mapping
  *.sh                # Scripts referenced from hooks.json
```

Both manifests are loaded by Claude Code at session start; the directories
above are referenced from `plugin.json`.

## Conventions

- **Plugin paths**: hook scripts and any other plugin-internal references must
  use `${CLAUDE_PLUGIN_ROOT}`, never relative paths or the user's CWD. The
  plugin runs from wherever Claude Code installed it, which is not the user's
  project directory.
- **Hook scripts** live in `hooks/` alongside `hooks.json`. They must be
  executable (`chmod +x`) and, when they need to inject context, emit a single
  JSON object on stdout with the shape:
  ```json
  {"hookSpecificOutput": {"hookEventName": "<Event>", "additionalContext": "..."}}
  ```
  Sanitize any dynamic text before embedding it in JSON (strip quotes,
  backslashes, control chars) or use `jq` / `python3 -c 'import json'`.
- **Hooks must fail safe**: never `exit 1` on an expected-but-unhandled
  condition (missing git, no network, dirty tree, etc.). Emit a status message
  and return success so sessions can still start. Use `set -uo pipefail` (not
  `-e`) and guard external commands with `command -v` / `|| true`.
- **Version bumps** must be applied in both `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` — they are read independently.
- **Adding a component**: create the file under the corresponding directory
  (`commands/foo.md`, `agents/foo.md`, `skills/foo/SKILL.md`). No registration
  step is needed — Claude Code discovers them from the directory listed in
  `plugin.json`. If you add a brand new component type, also add its path key
  to `plugin.json`.
- **No app code**: do not add build tooling, package managers, or runtime
  dependencies. Plugins are interpreted from source.

## Local testing

After editing, reload inside Claude Code instead of restarting the whole CLI:

```
/plugin marketplace add /path/to/brown    # once
/plugin install brown@brown               # once
/plugin                                    # -> reload
```

Hook scripts can be smoke-tested standalone with
`CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/<name>.sh | python3 -m json.tool` to confirm
they emit valid JSON.

## Don't

- Don't add a `scripts/` directory for hook helpers — keep them in `hooks/`.
- Don't hardcode the install path or assume git is present at runtime.
- Don't make a hook block the session on network calls; always bound them with
  `timeout` and degrade gracefully.
