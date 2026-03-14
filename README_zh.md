# cc-link

> 用自然语言或简单命令，在猫咪（[nanobot](https://github.com/nanobot-ai/nanobot)）🐱 和龙虾（[openclaw](https://github.com/open-claw/openclaw)）🦞 里轻松调用 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 进行编码和对话。

不用切终端，不用复制粘贴。在聊天里输入 `cc myproject -m 帮我写个登录页面`，Claude Code 就在对应项目里开始干活了，还能记住上下文。

## 为什么用 cc-link？

- **够简单** — 短命令 `cc todo -m 修个bug` 或者直接说人话都行
- **有记忆** — 同一项目的对话共享上下文，Claude Code 记得你们聊过什么
- **多项目** — 每个项目独立会话，互不干扰

## 环境要求

| 依赖 | 安装方式 |
|------|---------|
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) | 参考官方文档，首次使用运行 `claude login` |
| jq | `apt install jq` 或 `brew install jq` |
| nanobot 或 openclaw | 需支持 skill 功能 |

## 安装

把 skill 文件放到智能体的 skill 目录：

```
~/.nanobot/workspace/skills/claude-code-link/
├── SKILL.md
└── cc.sh
```

## 快速上手

```bash
# 创建项目
cc create myapp

# 或者从 GitHub 克隆
cc create myapp -u https://github.com/user/repo.git

# 发消息
cc myapp -m 添加用户登录功能

# 开新对话
cc myapp -new

# 开新对话同时发第一条消息
cc myapp -new 重构认证模块

# 上下文快满了？压缩一下
cc myapp -compact

# 不要这个项目了
cc delete myapp
```

## 命令一览

| 命令 | 说明 |
|------|------|
| `cc {项目} -m {消息}` | 向项目会话发送消息 |
| `cc {项目} -new` | 开启全新会话 |
| `cc {项目} -new {消息}` | 新会话 + 发第一条消息 |
| `cc {项目} -compact` | 压缩会话上下文 |
| `cc create {项目}` | 创建空项目 |
| `cc create {项目} -u {地址}` | 从 Git 仓库克隆创建项目 |
| `cc delete {项目}` | 删除项目及会话记录 |

## 自然语言

也可以直接用文字描述：

```
用cc在todolist项目提交一个新功能：添加深色模式
用cc在myapp项目问一下：认证流程是怎么工作的？
```

加上 `（plan模式）` 可以让 Claude Code 以只读模式运行，先看方案再动手。

## 自定义 System Prompt

在项目目录下放一个 `system_prompt.txt`，就能给 Claude Code 设定专属角色：

```
{workspace}/cc-projects/{项目名}/system_prompt.txt
```

每次调用自动生效。

## 工作原理

```
用户聊天 ──→ nanobot/openclaw ──→ cc.sh ──→ Claude Code CLI ──→ 返回结果
              (SKILL.md 解析指令)   (会话管理)    (实际干活)
```

- 会话存储在 `{workspace}/cc-projects/.sessions.json`
- 项目目录在 `{workspace}/cc-projects/{项目名}/`
- 会话恢复失败时自动回退为新会话

## 计划中的功能

- [ ] **上下文窗口用量显示** — 每次回复显示 token 使用百分比（如 `📊 claude-opus-4-6: 20% (40000/200000 tokens)`）

## License

MIT
