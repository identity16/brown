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
hooks/
  hooks.json          # Hook configuration
  session-start.sh    # Script invoked by the SessionStart hook
```

## Components

- `organize-commits` skill — reorganize the current branch into bisectable commits.
- `SessionStart` hook — runs `hooks/session-start.sh` when a session starts.
  Checks the local plugin checkout against its upstream branch and, when it is
  strictly behind with a clean working tree, fast-forwards it. Skips silently
  when git is unavailable, the plugin is not a git checkout, no upstream is
  configured, the remote is unreachable, the working tree is dirty, or the
  branches have diverged.

## Develop

Edit the files above, then reload in Claude Code with `/plugin` → reload, or
restart the session.
