# cc-link

> Call Claude Code with plain language or simple commands — right inside [nanobot](https://github.com/nanobot) 🐱 or [openclaw](https://github.com/openclaw) 🦞.

No switching terminals. No copy-pasting. Just type `cc myproject -m build a login page` and Claude Code gets to work in a persistent session, project by project.

---

## Why cc-link?

Most AI assistants stop at giving advice. cc-link goes further — it bridges your chat agent (nanobot / openclaw) directly to **Claude Code**, Anthropic's agentic coding CLI. You get:

- **Persistent sessions** — context is remembered across messages within the same project
- **Zero friction** — short commands or plain natural language, no CLI knowledge required
- **Multi-project** — manage independent Claude Code sessions for each of your projects
- **Context visibility** — token usage shown on every response so you always know where you stand

---

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`claude` CLI) — run `claude login` on first use
- `jq` — `apt install jq` or `brew install jq`
- nanobot or openclaw with skill support

---

## Installation

Place the skill files in your agent's skill directory:

```
~/.nanobot/workspace/skills/claude-code-link/
├── SKILL.md
└── cc.sh
```

All projects are stored under:

```
{workspace}/cc-projects/{project-name}/
```

---

## Usage

### Short Commands

```
cc {project} -m {message}          Send a message to a project session
cc {project} -new                  Start a fresh session
cc {project} -new {message}        Fresh session + send first message
cc {project} -compact              Compact (summarize) the session context
cc create {project}                Create a new project
cc create {project} -u {git-url}   Clone a Git repo as a project
cc delete {project}                Delete a project and its session
```

### Natural Language

You can also describe what you want in plain text:

```
用cc在todolist项目提交一个新功能：add a dark mode toggle
用cc在nanobot项目提交一个问题：how does the session resumption work?
用cc在myapp项目提交任务（plan模式）：refactor the auth module
```

---

## Command Reference

| Command | Description |
|---------|-------------|
| `cc {project} -m {content}` | Send a message to the project's Claude Code session |
| `cc {project} -new` | Clear the current session |
| `cc {project} -new {content}` | Clear session and send the first message |
| `cc {project} -compact` | Compact the session context window |
| `cc create {project}` | Create an empty project directory |
| `cc create {project} -u {url}` | Clone a Git repo into the project directory |
| `cc delete {project}` | Delete the project directory and session record |

### Plan Mode

Append `(plan模式)` / `(plan mode)` to any natural language request to run Claude Code in read-only plan mode — useful for reviewing before making changes.

---

## System Prompt (Optional)

To give Claude Code a custom persona or context for a project, create:

```
{workspace}/cc-projects/{project-name}/system_prompt.txt
```

It is automatically applied on every call to that project.

---

## Context Window Usage

Every response includes a token usage line at the top:

```
📊 claude-opus-4-6: 20% (40000/200000 tokens)
```

---

## License

MIT
