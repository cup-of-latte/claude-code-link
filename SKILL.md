---
name: cc-link
description: 通过 cc.sh 脚本调用 Claude Code CLI 执行命令并获取结构化回复（claude-code-link）。触发条件：（1）用户输入以 "cc " 开头的指令，如 `cc todolist -m 你好`、`cc todolist -new`、`cc todolist --compact`、`cc create myproject`、`cc delete myproject`；（2）用户提到 "用cc"、"claude code"、"claude代码" 等关键词。
---

# CC-Link（claude-code-link）技能

## 前置条件

执行前确认以下依赖可用：

```bash
claude -v    # Claude Code CLI
jq --version # JSON 处理工具
```

如未安装：
- Claude Code：参考官方文档安装，首次使用需 `claude login` 或配置 API Key
- jq：`apt install jq` 或 `brew install jq`

## 指令格式（优先级最高）

用户可直接使用以下简短指令触发，**无需自然语言描述**：

### 消息指令

| 指令 | 说明 | 对应 cc.sh 调用 |
|------|------|----------------|
| `cc {project} -m {content}` | 向项目发送消息 | `bash {skill_dir}/scripts/cc.sh --project {project} --content "{content}"` |
| `cc {project} -new [content]` | 新建会话（可选附带首条消息） | 无 content：`bash {skill_dir}/scripts/cc.sh --project {project} --content "/new"`；有 content：先 `/new` 再 `bash {skill_dir}/scripts/cc.sh --project {project} --new --content "{content}"` |
| `cc {project} --compact` | 压缩当前会话上下文 | `bash {skill_dir}/scripts/cc.sh --project {project} --compact` |
| `cc {project} --usage` | 查看上下文窗口使用率 | `bash {skill_dir}/scripts/cc.sh --project {project} --usage` |

### 项目管理指令

| 指令 | 说明 | 对应 cc.sh 调用 |
|------|------|----------------|
| `cc create {project}` | 创建空项目 | `bash {skill_dir}/scripts/cc.sh --action create --project {project}` |
| `cc create {project} -u {git-url}` | 从 Git 仓库克隆创建项目 | `bash {skill_dir}/scripts/cc.sh --action create --project {project} --git-url {git-url}` |
| `cc delete {project}` | 删除项目（含会话记录） | `bash {skill_dir}/scripts/cc.sh --action delete --project {project}` |

### 指令解析规则

1. 输入以 `cc ` 开头，第二个词判断指令类型：
   - `create` / `delete` → 项目管理指令
   - 其他 → 项目名，继续解析第三个词（`-m`、`-new`、`--compact`、`--usage`）
2. `-m` 后面跟随的所有文字为 `CONTENT`，**完整保留，不截断**
3. `-new` 后面如果有文字，则为新会话的首条消息 `CONTENT`；没有则仅清除会话
4. `-u` 后面为 Git 仓库 URL
5. `--compact`、`--usage` 和 `delete` 无需额外内容

### 指令示例

```
cc todolist -m 添加用户登录功能
cc todolist -new
cc todolist -new 帮我写一个自我介绍
cc todolist --compact
cc create myproject
cc create myproject -u https://github.com/user/repo.git
cc delete myproject
cc todolist --usage
```

## 自然语言触发（次优先级）

### 触发关键词

- "用cc"、"claude code"、"claude代码"、"cc在xxx项目"

### 提示词格式

```
用cc在{项目名}项目提交{类型}：{内容}
```

**类型**：新功能、任务、提问、bug修复

**示例**：
- `用cc在todolist项目提交一个新功能：添加登录功能`
- `用cc在todolist项目提交一个提问：帮我做一个周末出行计划`

### Plan 模式

用户提到"计划模式"、"plan模式"、"用plan"时启用 plan 只读模式。

## 解析用户输入

### 指令格式解析（优先匹配）

| 用户输入 | 操作 | cc.sh 调用 |
|----------|------|-----------|
| `cc todolist -m 添加登录功能` | 发送消息 | `--project todolist --content "添加登录功能"` |
| `cc todolist -new` | 仅新建会话 | `--project todolist --content "/new"` |
| `cc todolist -new 帮我写自我介绍` | 新建 + 发送 | 先 `--content "/new"`，再 `--project todolist --new --content "帮我写自我介绍"` |
| `cc todolist --compact` | 压缩上下文 | `--project todolist --compact` |
| `cc todolist --usage` | 查看上下文使用率 | `--project todolist --usage` |
| `cc create demo` | 创建项目 | `--action create --project demo` |
| `cc create demo -u https://...` | 克隆创建 | `--action create --project demo --git-url "https://..."` |
| `cc delete demo` | 删除项目 | `--action delete --project demo` |

### 自然语言解析

从自然语言输入中提取字段：

| 字段 | 说明 | 示例值 |
|------|------|--------|
| `PROJECT` | 项目名称 | `todolist`、`nanobot` |
| `CONTENT` | 发送给 Claude Code 的完整内容 | `添加登录功能`（必须完整保留用户原话） |
| `MODE` | 执行模式（可选） | `plan`（出现"plan模式"/"计划模式"时） |

**解析规则**：
1. 分隔符（`发送：`、`提交xxx：`、`：`）之后的所有文字 = `CONTENT`（完整保留）
2. 从"在xxx项目"、"进入xxx"、"去xxx项目"中提取 `PROJECT`
3. 出现"plan模式"、"计划模式"、"用plan"时 `MODE=plan`

> **重要**：`CONTENT` 必须完整保留用户原话，不得添加、删除或改写任何内容。

## 执行规则（必须遵守）

> **严格执行，不得违反以下任何一条规则。**

### 规则一：直接执行，不确认、不分析、不追问

收到 `cc` 指令后，**立即解析并执行**，不得：
- 向用户确认"要不要发送"、"是不是还有内容"
- 自行分析用户的 CONTENT 内容并给出建议
- 先读取项目文件再决定是否执行
- 拆成多步并在中间询问用户

### 规则二：`-new {content}` 必须一步到位

当 `-new` 后面带有 content 时，**必须在一次执行中完成两步**，不得拆开确认：

```bash
# 第一步：清除旧会话
bash {skill_dir}/scripts/cc.sh --project "PROJECT" --content "/new"
# 第二步：立即发送首条消息（不等待、不确认）
bash {skill_dir}/scripts/cc.sh --project "PROJECT" --new --content "CONTENT"
```

### 规则三：原样透传结果，禁止加工

脚本输出 JSON 格式，直接将 `result` 字段的完整内容返回给用户即可。

**禁止对 result 内容做任何总结、缩写、改写或省略。**

## 执行流程

### 1. 解析用户输入

按上文规则提取字段。

### 2. 调用脚本

```bash
# 发送消息
bash {skill_dir}/scripts/cc.sh --project "PROJECT" --content "CONTENT"

# Plan 模式
bash {skill_dir}/scripts/cc.sh --project "PROJECT" --content "CONTENT" --mode plan

# 强制新建会话
bash {skill_dir}/scripts/cc.sh --project "PROJECT" --content "CONTENT" --new

# 创建项目
bash {skill_dir}/scripts/cc.sh --action create --project "PROJECT"
bash {skill_dir}/scripts/cc.sh --action create --project "PROJECT" --git-url "URL"

# 删除项目
bash {skill_dir}/scripts/cc.sh --action delete --project "PROJECT"
```

### 3. 返回结果

脚本输出 JSON 格式，将 `result` 字段的完整内容原样返回给用户。

## 会话管理

- **自动持久化**：每次调用后 session_id 自动保存到 `{workspace}/cc-projects/.sessions.json`
- **自动恢复**：同一项目再次调用时自动恢复上次会话
- **新建会话**：`-new` 或自然语言"新对话"时清除 session
- **resume 失败回退**：session_id 过期时自动回退为新会话

## System Prompt（可选）

在项目目录下创建 `system_prompt.txt` 即可自动生效：

```
{workspace}/cc-projects/{项目名}/system_prompt.txt
```

## 工作目录

所有项目在 `cc-projects` 下管理，workspace 路径自动检测（`~/.nanobot/config.json` → `~/.openclaw/openclaw.json` → 默认路径）。
