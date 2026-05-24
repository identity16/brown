# brown

A Claude Code plugin.

## Install

From the Claude Code CLI:

```
/plugin marketplace add identity16/brown
/plugin install brown@brown
```

Or, for local development, clone the repo and add it as a local marketplace:

```
/plugin marketplace add /path/to/brown
/plugin install brown@brown
```

## Structure

```
.claude-plugin/
  plugin.json         # Plugin manifest
  marketplace.json    # Marketplace manifest (this repo distributes itself)
commands/             # Slash commands
agents/               # Subagents
skills/               # Skills (one folder per skill, with SKILL.md)
hooks/hooks.json      # Hook configuration
scripts/              # Scripts invoked by hooks
```

## Components

- `/hello [name]` — example slash command.
- `example-agent` — example subagent.
- `example-skill` — example skill.
- `SessionStart` hook — runs `scripts/session-start.sh` when a session starts.

## Develop

Edit the files above, then reload in Claude Code with `/plugin` → reload, or
restart the session.
