# claude-multi-account.zsh
# 管理多個 Claude Code 帳號（繞過 macOS Keychain 單帳號限制）
# https://github.com/YOUR_USERNAME/claude-multi-account
#
# 安裝：bash install.sh
# 設定：編輯下方「帳號 alias」區塊，照自己的帳號數量增減

# ─────────────────────────────────────────────
# 1. 帳號 alias（範例，請依需求增減）
#    每個帳號對應一個獨立的 CLAUDE_CONFIG_DIR
# ─────────────────────────────────────────────
# alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
# alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'

# ── API key 帳號（按量計費） ──
# 步驟：
#   1. 建立 ~/.secrets/claude-api-key，內容為：
#      export ANTHROPIC_API_KEY="sk-ant-api03-..."
#   2. 確認該檔案權限：chmod 600 ~/.secrets/claude-api-key
#   3. 取消注解下面這行（替換為你的 secrets 路徑）：
# alias claude-api='source ~/.secrets/claude-api-key && CLAUDE_CONFIG_DIR=$HOME/.claude-api claude'

# ─────────────────────────────────────────────
# 2. IDE launchers（可選）
#    從 terminal 啟動 IDE，才能把正確的 token 帶給 Claude 擴充功能
# ─────────────────────────────────────────────
# VS Code 範例（個人帳號）：
# alias code='source ~/.secrets/claude-personal-token && CLAUDE_CONFIG_DIR=$HOME/.claude-personal "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"'
#
# Cursor 範例（工作帳號）：
# alias cursor='source ~/.secrets/claude-work-token && CLAUDE_CONFIG_DIR=$HOME/.claude-work /Applications/Cursor.app/Contents/Resources/app/bin/cursor'
#
# secrets 檔案格式範例（~/.secrets/claude-personal-token）：
#   export CLAUDE_CODE_OAUTH_TOKEN="eyJh..."

# ─────────────────────────────────────────────
# 3. 監控 wrapper 範例（照帳號 alias 新增對應的）
#    plan 選項：pro / max5 / max20
# ─────────────────────────────────────────────
monitor-work()     { CLAUDE_CONFIG_DIR=$HOME/.claude-work     claude-monitor --plan max5 "$@"; }
monitor-personal() { CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude-monitor --plan pro  "$@"; }
usage-work()       { CLAUDE_CONFIG_DIR=$HOME/.claude-work     ccusage "$@"; }
usage-personal()   { CLAUDE_CONFIG_DIR=$HOME/.claude-personal ccusage "$@"; }

# ─────────────────────────────────────────────
# 4. 核心工具函式（不需修改）
# ─────────────────────────────────────────────

# 自動掃描 ~/.claude-* 顯示各自登入的帳號（有上色）
claude-whoami() {
  python3 <<'PY'
import json, os, glob, sys, re
home = os.path.expanduser("~")

# 只列出 zshrc 有對應 alias 的目錄，避免把其他工具的 dir 誤判成帳號
zshrc = os.path.join(home, ".zshrc")
registered = set()
if os.path.exists(zshrc):
    with open(zshrc) as f:
        for line in f:
            m = re.match(r"\s*alias\s+claude-([a-zA-Z0-9_-]+)\s*=", line)
            if m:
                registered.add(m.group(1))

dirs = []
default_dir = home + "/.claude"
# 若 ~/.claude 是真實目錄就列出；若是 symlink 則跳過，避免重複
if os.path.isdir(default_dir) and not os.path.islink(default_dir):
    dirs.append(default_dir)
for name in sorted(registered):
    d = f"{home}/.claude-{name}"
    if os.path.isdir(d):
        dirs.append(d)

C = {
  "B": "\033[1m", "D": "\033[2m", "R": "\033[0m",
  "green": "\033[32m", "yellow": "\033[33m",
  "cyan": "\033[36m", "red": "\033[31m",
} if sys.stdout.isatty() or os.environ.get('FORCE_COLOR') else {k: "" for k in ["B","D","R","green","yellow","cyan","red"]}

def alias_of(d):
    suffix = os.path.basename(d).lstrip(".")
    return "claude-work" if suffix == "claude" else suffix

width = max((len(alias_of(d)) for d in dirs), default=0)
for d in dirs:
    alias = alias_of(d)
    label = f"{C['green']}{alias.ljust(width)}{C['R']}"
    arrow = f"{C['D']}→{C['R']}"
    path  = os.path.join(d, ".claude.json")
    if alias == "claude-api":
        print(f"{label} {arrow} {C['yellow']}API key 模式（按量計費）{C['R']}")
        continue
    if not os.path.exists(path):
        print(f"{label} {arrow} {C['red']}(尚未登入){C['R']}")
        continue
    try:
        a = json.load(open(path)).get("oauthAccount") or {}
        if a:
            name  = f"{C['B']}{C['yellow']}{a.get('displayName','?')}{C['R']}"
            email = f"{C['D']}<{a.get('emailAddress','?')}>{C['R']}"
            role  = f"{C['cyan']}[{a.get('organizationRole','?')}]{C['R']}"
            print(f"{label} {arrow} {name}  {email}  {role}")
        else:
            print(f"{label} {arrow} {C['red']}(尚未登入){C['R']}")
    except Exception as e:
        print(f"{label} {arrow} {C['red']}(error: {e}){C['R']}")
PY

  if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo ""
    echo "current shell token: ${CLAUDE_CODE_OAUTH_TOKEN:0:18}... (IDE env)"
    echo "CLAUDE_CONFIG_DIR:   ${CLAUDE_CONFIG_DIR:-(unset)}"
  fi
}

# 指令速查（動態掃描 ~/.zshrc 顯示當前帳號清單）
claude-help() {
  local t d g c y r
  if [ -t 1 ]; then
    t=$'\e[1;35m'; c=$'\e[1;36m'; g=$'\e[32m'; d=$'\e[2m'; y=$'\e[33m'; r=$'\e[0m'
  else
    t=""; c=""; g=""; d=""; y=""; r=""
  fi

  print "${t}═══ Claude 指令速查 ═══${r}"
  print
  print "${c}【帳號】${r}"
  FORCE_COLOR=1 claude-whoami | sed 's/^/  /'
  print
  print "${c}【工具】${r}"
  print "  ${g}claude-whoami${r}           ${d}→${r} ${y}列出所有 config 目錄登入狀態${r}"
  print "  ${g}claude-add-account N${r}    ${d}→${r} ${y}新增帳號槽${r}${d}（例：claude-add-account client1）${r}"
  print "  ${g}claude-remove-account N${r} ${d}→${r} ${y}移除帳號槽 alias${r}${d}（會詢問是否一併刪 config 目錄）${r}"
  print "  ${g}claude-edit-plan N plan${r} ${d}→${r} ${y}修改帳號的 monitor plan${r}${d}（pro/max5/max20）${r}"
  print "  ${g}claude-help${r}             ${d}→${r} ${y}顯示這份說明${r}"
  print
  print "${c}【用量監控】${r}"

  local zshrc_path="${ZDOTDIR:-$HOME}/.zshrc"
  # 動態列出 monitor-* 函式（用 grep/sed，bash/zsh 相容）
  while IFS= read -r fname; do
    print "  ${g}monitor-${fname}${r}  ${d}→${r} ${y}即時監測 ${fname}${r}${d}（claude-monitor UI）${r}"
  done < <(grep -oE '^monitor-[a-zA-Z0-9_-]+\(\)' "$zshrc_path" 2>/dev/null | sed 's/()//' | sed 's/^monitor-//')

  # 動態列出 usage-* 函式
  while IFS= read -r fname; do
    print "  ${g}usage-${fname}${r}  ${d}→${r} ${y}${fname} 歷史用量${r}${d}（ccusage，可接 daily/blocks/session）${r}"
  done < <(grep -oE '^usage-[a-zA-Z0-9_-]+\(\)' "$zshrc_path" 2>/dev/null | sed 's/()//' | sed 's/^usage-//')

  print "  ${d}# 範例：usage-work blocks --live  看 5 小時窗口${r}"
  print "  ${d}# 注意：claude-monitor 需 patch 才支援 CLAUDE_CONFIG_DIR（升級會被覆蓋）${r}"
  print
  print "${c}【IDE 啟動器】${r} ${d}（從 terminal 開才能帶對 token 給擴充功能）${r}"
  print "  ${d}# 設定方式見 claude-multi-account.zsh 頂部注解${r}"
}

# claude-monitor 預設 classic 主題（對比較清楚）
claude-monitor() { command claude-monitor --theme classic "$@"; }

# 新增 Claude 帳號槽：建目錄 + 加 alias + monitor/usage wrapper + 提示登入
# 用法: claude-add-account <name> [plan]   plan 預設 pro，可填 pro/max5/max20
claude-add-account() {
  local name="$1"
  local plan="${2:-pro}"
  if [ -z "$name" ]; then
    echo "用法: claude-add-account <name> [plan]   (例: claude-add-account client1 max5)"
    return 1
  fi
  if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "錯誤: name 只能是英數字、底線、連字號"
    return 1
  fi
  local dir="$HOME/.claude-$name"
  local alias_name="claude-$name"
  local alias_line="alias $alias_name='CLAUDE_CONFIG_DIR=\$HOME/.claude-$name claude'"
  local monitor_line="monitor-$name() { CLAUDE_CONFIG_DIR=\$HOME/.claude-$name claude-monitor --plan $plan \"\$@\"; }"
  local usage_line="usage-$name()   { CLAUDE_CONFIG_DIR=\$HOME/.claude-$name ccusage \"\$@\"; }"

  if [ -d "$dir" ]; then
    echo "⚠️  目錄 $dir 已存在（可能之前已新增過）"
  else
    mkdir -p "$dir"
    echo "✅ 建立目錄：$dir"
  fi

  # 插入 alias（在最後一個 alias claude-* 行之後）
  if grep -qF "alias $alias_name=" ~/.zshrc; then
    echo "⚠️  ~/.zshrc 已有 $alias_name alias，略過"
  else
    awk -v line="$alias_line" '
      /^alias claude-[a-zA-Z0-9_-]+=/ { last=NR }
      { lines[NR]=$0 }
      END {
        for (i=1; i<=NR; i++) {
          print lines[i]
          if (i==last) print line
        }
      }
    ' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
    echo "✅ 已加 alias 到 ~/.zshrc"
  fi

  # 插入 monitor/usage functions（在最後一個 usage-* 行之後）
  if grep -qF "monitor-$name()" ~/.zshrc; then
    echo "⚠️  ~/.zshrc 已有 monitor-$name，略過"
  else
    awk -v ml="$monitor_line" -v ul="$usage_line" '
      /^usage-[a-zA-Z0-9_-]+\(\)/ { last=NR }
      { lines[NR]=$0 }
      END {
        for (i=1; i<=NR; i++) {
          print lines[i]
          if (i==last) { print ml; print ul }
        }
      }
    ' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
    echo "✅ 已加 monitor-$name / usage-$name 到 ~/.zshrc"
  fi

  eval "$alias_line"
  eval "$monitor_line"
  eval "$usage_line"

  echo ""
  echo "下一步："
  echo "  1. 跑  $alias_name"
  echo "  2. 在 claude 裡面下 /login"
  echo "  3. claude-whoami 驗證"
  echo "  4. monitor-$name  /  usage-$name daily  查用量"
}

# 移除帳號槽：刪除 ~/.zshrc 裡的 alias 行，並互動詢問是否刪 config 目錄
claude-remove-account() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "用法: claude-remove-account <name>   (例: claude-remove-account client1)"
    return 1
  fi
  if [[ "$name" == "work" || "$name" == "personal" || "$name" == "api" ]]; then
    echo "錯誤: $name 是保留槽位，不允許用這個指令移除（需要就手動改 ~/.zshrc）"
    return 1
  fi
  local alias_name="claude-$name"
  local dir="$HOME/.claude-$name"

  if ! grep -qF "alias $alias_name=" ~/.zshrc; then
    echo "⚠️  ~/.zshrc 找不到 $alias_name alias"
  else
    awk -v a="alias $alias_name=" '$0 !~ a' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
    echo "✅ 已從 ~/.zshrc 移除 $alias_name alias"
  fi

  # 移除 monitor/usage functions
  awk -v m="monitor-$name()" -v u="usage-$name()" '$0 !~ m && $0 !~ u' \
    ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
  echo "✅ 已從 ~/.zshrc 移除 monitor-$name / usage-$name"

  # 從當前 shell unalias/unfunction
  unalias "$alias_name" 2>/dev/null
  unfunction "monitor-$name" "usage-$name" 2>/dev/null

  # 互動詢問是否一併刪 config 目錄
  if [ -d "$dir" ]; then
    echo ""
    echo -n "⚠️  要一併刪除 config 目錄 $dir 嗎？[y/N] "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      rm -rf "$dir"
      echo "🗑️  已刪除 $dir"
    else
      echo "    略過，需要時手動執行：rm -rf $dir"
    fi
  fi
}

# 修改帳號的 monitor plan
# 用法: claude-edit-plan <name> <plan>   plan: pro/max5/max20
claude-edit-plan() {
  local name="$1"
  local plan="$2"
  if [[ -z "$name" || -z "$plan" ]]; then
    echo "用法: claude-edit-plan <name> <plan>   (例: claude-edit-plan client1 max5)"
    echo "plan 選項: pro / max5 / max20"
    return 1
  fi
  if ! grep -q "monitor-$name()" ~/.zshrc; then
    echo "❌ 找不到 monitor-$name，請先用 claude-add-account $name 建立"
    return 1
  fi
  # 取代 monitor-<name> 那行裡的 --plan xxx
  sed -i '' "s/monitor-$name() {.*claude-monitor --plan [a-z0-9]*/monitor-$name() { CLAUDE_CONFIG_DIR=\$HOME\/.claude-$name claude-monitor --plan $plan/" ~/.zshrc
  echo "✅ monitor-$name plan 已更新為 $plan"
  # 重新 eval 讓當前 shell 生效
  eval "monitor-$name() { CLAUDE_CONFIG_DIR=\$HOME/.claude-$name claude-monitor --plan $plan \"\$@\"; }"
}
