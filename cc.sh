#!/usr/bin/env bash
# cc.sh - Claude Code CLI wrapper with session & project management
set -euo pipefail

# ──────────────────────────────────────────────
# Dependency check
# ──────────────────────────────────────────────
for dep in claude jq; do
    if ! command -v "$dep" &>/dev/null; then
        echo "Error: '$dep' is not installed or not in PATH." >&2
        exit 1
    fi
done

# ──────────────────────────────────────────────
# Workspace detection
# ──────────────────────────────────────────────
detect_workspace() {
    local ws=""
    if [[ -f ~/.nanobot/config.json ]]; then
        ws=$(jq -r '.agents.defaults.workspace // empty' ~/.nanobot/config.json 2>/dev/null)
        [[ -z "$ws" ]] && ws="~/.nanobot/workspace"
    elif [[ -f ~/.openclaw/openclaw.json ]]; then
        ws=$(jq -r '.workspace // empty' ~/.openclaw/openclaw.json 2>/dev/null)
        [[ -z "$ws" ]] && ws="~/.openclaw"
    elif [[ -d ~/.nanobot ]]; then
        ws="~/.nanobot/workspace"
    else
        ws="~/.openclaw"
    fi
    echo "${ws/#\~/$HOME}"
}

WORKSPACE=$(detect_workspace)
CC_PROJECTS="$WORKSPACE/cc-projects"
SESSIONS_FILE="$CC_PROJECTS/.sessions.json"

# ──────────────────────────────────────────────
# Argument parsing
# ──────────────────────────────────────────────
ACTION=""
PROJECT=""
CONTENT=""
MODE=""
GIT_URL=""
NEW_SESSION=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --action)   ACTION="$2";   shift 2 ;;
        --project)  PROJECT="$2";  shift 2 ;;
        --content)  CONTENT="$2";  shift 2 ;;
        --mode)     MODE="$2";     shift 2 ;;
        --git-url)  GIT_URL="$2";  shift 2 ;;
        --new)      NEW_SESSION=true; shift ;;
        -h|--help)
            echo "Usage: cc.sh --project PROJECT [--action create|delete] [--content CONTENT] [--mode plan] [--git-url URL] [--new]"
            exit 0 ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            exit 1 ;;
    esac
done

[[ -z "$PROJECT" ]] && { echo "Error: --project is required." >&2; exit 1; }

PROJECT_DIR="$CC_PROJECTS/$PROJECT"

# ──────────────────────────────────────────────
# JSON output helper
# ──────────────────────────────────────────────
json_result() {
    local msg="$1" err="${2:-false}"
    printf '{"type":"result","subtype":"%s","result":"%s","is_error":%s}\n' \
        "$([ "$err" = true ] && echo error || echo success)" "$msg" "$err"
}

# ──────────────────────────────────────────────
# Action: create project
# ──────────────────────────────────────────────
if [[ "$ACTION" == "create" ]]; then
    if [[ -d "$PROJECT_DIR" ]]; then
        json_result "⚠️ 项目 [$PROJECT] 已存在：$PROJECT_DIR"
        exit 0
    fi
    if [[ -n "$GIT_URL" ]]; then
        if ! command -v git &>/dev/null; then
            json_result "❌ git 未安装" true
            exit 1
        fi
        git clone "$GIT_URL" "$PROJECT_DIR" 2>&1 || {
            json_result "❌ git clone 失败：$GIT_URL" true
            exit 1
        }
        json_result "✅ 项目 [$PROJECT] 已从 $GIT_URL 克隆创建"
    else
        mkdir -p "$PROJECT_DIR"
        json_result "✅ 项目 [$PROJECT] 已创建：$PROJECT_DIR"
    fi
    exit 0
fi

# ──────────────────────────────────────────────
# Action: delete project
# ──────────────────────────────────────────────
if [[ "$ACTION" == "delete" ]]; then
    if [[ ! -d "$PROJECT_DIR" ]]; then
        json_result "⚠️ 项目 [$PROJECT] 不存在"
        exit 0
    fi
    rm -rf "$PROJECT_DIR"
    # Clean session
    if [[ -f "$SESSIONS_FILE" ]]; then
        tmp=$(jq --arg p "$PROJECT" 'del(.[$p])' "$SESSIONS_FILE")
        echo "$tmp" > "$SESSIONS_FILE"
    fi
    json_result "✅ 项目 [$PROJECT] 已删除"
    exit 0
fi

# ──────────────────────────────────────────────
# Below: send message to Claude Code (requires --content)
# ──────────────────────────────────────────────
[[ -z "$CONTENT" ]] && { echo "Error: --content is required." >&2; exit 1; }

SYSTEM_PROMPT_FILE="$PROJECT_DIR/system_prompt.txt"
mkdir -p "$PROJECT_DIR"

# ──────────────────────────────────────────────
# /new: clear session only (no API call)
# ──────────────────────────────────────────────
CONTENT_TRIMMED="${CONTENT#"${CONTENT%%[! ]*}"}"
CONTENT_TRIMMED="${CONTENT_TRIMMED%"${CONTENT_TRIMMED##*[! ]}"}"
if [[ "$CONTENT_TRIMMED" == "/new" ]]; then
    if [[ -f "$SESSIONS_FILE" ]]; then
        tmp=$(jq --arg p "$PROJECT" 'del(.[$p])' "$SESSIONS_FILE")
        echo "$tmp" > "$SESSIONS_FILE"
    fi
    json_result "✅ [$PROJECT] 新对话已创建，system prompt 将在下次发送时生效。"
    exit 0
fi

# ──────────────────────────────────────────────
# Session management
# ──────────────────────────────────────────────
get_session_id() {
    [[ -f "$SESSIONS_FILE" ]] && jq -r --arg p "$PROJECT" '.[$p] // empty' "$SESSIONS_FILE" 2>/dev/null
}

save_session_id() {
    local sid="$1"
    if [[ -f "$SESSIONS_FILE" ]]; then
        local tmp
        tmp=$(jq --arg p "$PROJECT" --arg s "$sid" '.[$p] = $s' "$SESSIONS_FILE")
        echo "$tmp" > "$SESSIONS_FILE"
    else
        jq -n --arg p "$PROJECT" --arg s "$sid" '{($p): $s}' > "$SESSIONS_FILE"
    fi
}

SESSION_ID=""
[[ "$NEW_SESSION" == false ]] && SESSION_ID=$(get_session_id)

# ──────────────────────────────────────────────
# Build & run claude command
# ──────────────────────────────────────────────
run_claude() {
    local use_resume="$1"
    local cmd=(claude -p "$CONTENT" --output-format json --max-turns 25)

    [[ "$use_resume" == true && -n "$SESSION_ID" ]] && cmd+=(--resume "$SESSION_ID")
    [[ "$MODE" == "plan" ]] && cmd+=(--permission-mode plan)
    [[ -f "$SYSTEM_PROMPT_FILE" ]] && cmd+=(--system-prompt-file "$SYSTEM_PROMPT_FILE")

    cd "$PROJECT_DIR"
    "${cmd[@]}" 2>/dev/null
}

# Try with resume first, fallback to new session on failure
OUTPUT=""
if [[ -n "$SESSION_ID" && "$NEW_SESSION" == false ]]; then
    OUTPUT=$(run_claude true) || {
        SESSION_ID=""
        OUTPUT=$(run_claude false) || { echo "Error: Claude CLI execution failed." >&2; exit 1; }
    }
else
    OUTPUT=$(run_claude false) || { echo "Error: Claude CLI execution failed." >&2; exit 1; }
fi

# ──────────────────────────────────────────────
# Save session ID
# ──────────────────────────────────────────────
NEW_SID=$(echo "$OUTPUT" | jq -r '.session_id // empty' 2>/dev/null)
[[ -n "$NEW_SID" ]] && save_session_id "$NEW_SID"

# ──────────────────────────────────────────────
# Output result as plain text
# ──────────────────────────────────────────────
echo "$OUTPUT" | jq -r '.result // ""' 2>/dev/null
