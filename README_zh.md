# cc-link

> 用自然语言或简单命令，在猫咪（[nanobot](https://github.com/nanobot)）🐱 和龙虾（[openclaw](https://github.com/openclaw)）🦞 中轻松调用 Claude Code 编码与对话。

不用切换终端，不用复制粘贴。输入 `cc myproject -m 帮我写一个登录页面`，Claude Code 就在对应项目的持久会话里开始工作了。

---

## 为什么用 cc-link？

大多数 AI 助手只能给建议，cc-link 更进一步 —— 它把你的聊天智能体（nanobot / openclaw）直接桥接到 **Claude Code**（Anthropic 的智能编程 CLI）。你获得的是：

- **持久会话** — 同一项目的多条消息共享上下文，Claude Code 记住你们的对话
- **零门槛** — 短命令或自然语言都能触发，不需要懂命令行
- **多项目隔离** — 每个项目独立管理自己的 Claude Code 会话
- **上下文可视** — 每次回复都显示 token 用量，随时掌握窗口余量

---

## 环境要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（`claude` CLI）— 首次使用需运行 `claude login`
- `jq` — `apt install jq` 或 `brew install jq`
- 支持 skill 的 nanobot 或 openclaw

---

## 安装

将 skill 文件放入智能体的 skill 目录：

```
~/.nanobot/workspace/skills/claude-code-link/
├── SKILL.md
└── cc.sh
```

所有项目统一存放在：

```
{workspace}/cc-projects/{项目名}/
```

---

## 使用方式

### 短命令

```
cc {项目} -m {消息}             向项目会话发送消息
cc {项目} -new                  开启全新会话
cc {项目} -new {消息}           开启全新会话并发送第一条消息
cc {项目} -compact              压缩（摘要）当前会话上下文
cc create {项目}                创建新项目
cc create {项目} -u {git地址}   从 Git 仓库克隆创建项目
cc delete {项目}                删除项目及其会话记录
```

### 自然语言

直接用文字描述你想做什么：

```
用cc在todolist项目提交一个新功能：添加深色模式切换
用cc在nanobot项目提交一个问题：会话恢复是怎么工作的？
用cc在myapp项目提交任务（plan模式）：重构认证模块
```

---

## 命令速查

| 命令 | 说明 |
|------|------|
| `cc {项目} -m {内容}` | 向项目的 Claude Code 会话发送消息 |
| `cc {项目} -new` | 清除当前会话 |
| `cc {项目} -new {内容}` | 清除会话并发送第一条消息 |
| `cc {项目} -compact` | 压缩会话上下文窗口 |
| `cc create {项目}` | 创建空项目目录 |
| `cc create {项目} -u {地址}` | 从 Git 仓库克隆到项目目录 |
| `cc delete {项目}` | 删除项目目录和会话记录 |

### Plan 模式

在自然语言请求中加入 `（plan模式）` / `（计划模式）`，Claude Code 将以只读 plan 模式运行 —— 适合在实际修改代码前先预览方案。

---

## 自定义 System Prompt（可选）

为某个项目创建专属角色或上下文，在项目目录下放一个文本文件即可：

```
{workspace}/cc-projects/{项目名}/system_prompt.txt
```

每次调用该项目时自动生效。

---

## 上下文用量显示

每次回复开头都会显示 token 用量：

```
📊 claude-opus-4-6: 20% (40000/200000 tokens)
```

---

## License

MIT
