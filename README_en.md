# cc-link

[中文文档](./README_zh.md)

> Call [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with plain language or simple commands — right inside [nanobot](https://github.com/nanobot-ai/nanobot) 🐱 and [openclaw](https://github.com/open-claw/openclaw) 🦞.

No terminal switching. No copy-pasting prompts. Type `cc myproject -m build a login page` in your chat, and Claude Code starts coding in a persistent, project-scoped session.

## Why cc-link?

- **Dead simple** — short commands like `cc todo -m fix the bug` or just describe what you want in plain language
- **Persistent sessions** — Claude Code remembers context across messages within the same project
- **Multi-project** — each project gets its own isolated Claude Code session

## Requirements

| Dependency | Install |
|------------|---------|
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) | See official docs, then run `claude login` |
| jq | `apt install jq` or `brew install jq` |
| nanobot or openclaw | With skill support enabled |

## Installation

Place the skill files in your agent's skill directory:

```
~/.nanobot/workspace/skills/claude-code-link/
├── SKILL.md
└── scripts/
    └── cc.sh
```

## Quick Start

```bash
# Create a project
cc create myapp

# Or clone from GitHub
cc create myapp -u https://github.com/user/repo.git

# Send a message
cc myapp -m add user authentication with JWT

# Start a fresh conversation
cc myapp -new

# Start fresh + send first message in one shot
cc myapp -new refactor the auth module

# Compress context when running low
cc myapp --compact

# Check context window usage
cc myapp --usage

# Done with a project
cc delete myapp
```

## Commands

| Command | Description |
|---------|-------------|
| `cc {project} -m {message}` | Send a message to the project session |
| `cc {project} -new` | Start a fresh session |
| `cc {project} -new {message}` | Fresh session + send first message |
| `cc {project} --compact` | Compact the session context |
| `cc {project} --usage` | Show context window usage (token count & %) |
| `cc create {project}` | Create an empty project |
| `cc create {project} -u {url}` | Clone a Git repo as a new project |
| `cc delete {project}` | Delete project and session data |

## Natural Language

You can also just describe what you want:

```
用cc在todolist项目提交一个新功能：add dark mode
用cc在myapp项目问一下：how does the auth flow work?
```

Add `(plan模式)` to run Claude Code in read-only plan mode.

## Custom System Prompt

Create a `system_prompt.txt` in the project directory to give Claude Code a custom persona:

```
{workspace}/cc-projects/{project}/system_prompt.txt
```

Automatically applied on every call.

## How It Works

```
User chat ──→ nanobot/openclaw ──→ cc.sh ──→ Claude Code CLI ──→ response
                (SKILL.md parses)    (session mgmt)   (does the work)
```

- Sessions are stored in `{workspace}/cc-projects/.sessions.json`
- Projects live under `{workspace}/cc-projects/{project}/`
- Failed session resume automatically falls back to a new session

## Roadmap

- [x] **Context window usage display** — `cc {project} --usage` shows token usage percentage (e.g. `📊 claude-opus-4-6: 20% (40000/200000 tokens)`)

## License

MIT
