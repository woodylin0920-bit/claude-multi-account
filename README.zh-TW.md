[English](README.md)

# claude-multi-account

在同一台 Mac 上管理多個 Claude Code 帳號 — 透過 `CLAUDE_CONFIG_DIR` 繞過 macOS Keychain 單帳號限制。

> **僅支援 macOS。** 建立在 [claude-monitor](https://github.com/doobidoo/claude-monitor) 和 [ccusage](https://github.com/ryoppippi/ccusage) 之上。

## 問題背景

macOS Keychain **只能存一個** Claude OAuth token。當你有工作帳號（Max）和個人帳號（Pro）時，每次切換都要重新 `/login`，同時還會丟失當前的 session。

**解法：** Claude Code 支援 `CLAUDE_CONFIG_DIR` 環境變數。讓每個 alias 指向獨立的目錄（`~/.claude-work`、`~/.claude-personal`……），token 就互不干擾。

---

## 快速開始

```bash
# 1. Clone 並安裝
git clone https://github.com/woodylin0920-bit/claude-multi-account.git
cd claude-multi-account
bash install.sh

# 2. 編輯設定檔 — 取消注解帳號 alias（把 work / personal 換成你自己的名稱）
open ~/.config/claude-multi-account/claude-multi-account.zsh

# 3. 重新載入 shell
source ~/.zshrc

# 4. 新增帳號槽並登入
claude-add-account work max5   # 建立 ~/.claude-work + 加 alias + 監控 wrapper
claude-work                    # 用 work config 開啟 Claude Code
# 在 Claude 裡執行：/login
# 登入完成後按 Ctrl+D 離開

# 5. 驗證
claude-whoami
```

---

## 需求

| 工具 | 是否必要 | 安裝方式 |
|------|----------|---------|
| [Claude Code CLI](https://claude.ai/code) | ✅ 必要 | 見連結 |
| [ccusage](https://github.com/ryoppippi/ccusage) | 選用 | `npm install -g ccusage` |
| [claude-monitor](https://github.com/doobidoo/claude-monitor) | 選用 | `uv tool install claude-monitor` |

> **注意：** `monitor-*` 指令需要 claude-monitor **以及** CLAUDE_CONFIG_DIR patch（見下方說明）。未套用 patch 時，所有 monitor 實例會讀取同一個帳號的資料。

---

## 安裝

```bash
git clone https://github.com/woodylin0920-bit/claude-multi-account.git
cd claude-multi-account
bash install.sh
```

`install.sh` 會將 `claude-multi-account.zsh` 複製到 `~/.config/claude-multi-account/`，並在 `~/.zshrc` 末尾加上 `source` 那行。

---

## 設定

安裝後，編輯設定檔：

```bash
open ~/.config/claude-multi-account/claude-multi-account.zsh
# 或：$EDITOR ~/.config/claude-multi-account/claude-multi-account.zsh
```

**取消注解並填入帳號 alias**（在檔案頂部）：

```zsh
# 修改前（注解，僅供參考）：
# alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
# alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'

# 修改後（你的實際帳號）：
alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'
```

**同時更新監控 wrapper**，對應你的帳號名稱和方案：

```zsh
monitor-work()     { CLAUDE_CONFIG_DIR=$HOME/.claude-work     claude-monitor --plan max5 "$@"; }
monitor-personal() { CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude-monitor --plan pro  "$@"; }
usage-work()       { CLAUDE_CONFIG_DIR=$HOME/.claude-work     ccusage "$@"; }
usage-personal()   { CLAUDE_CONFIG_DIR=$HOME/.claude-personal ccusage "$@"; }
```

修改完重新載入：`source ~/.zshrc`

---

## 指令說明

### 帳號狀態

```bash
claude-whoami
```

掃描 `~/.zshrc` 中所有已登錄的 `~/.claude-*` 目錄，顯示各帳號的登入狀態、email 和方案。

### 新增帳號槽

```bash
claude-add-account <name> [plan]
# plan 預設 pro，可填：pro / max5 / max20

claude-add-account client1 max5
```

自動建立 `~/.claude-client1/`，並在 `~/.zshrc` 加上 alias 和 monitor/usage wrapper。

### 移除帳號槽

```bash
claude-remove-account client1
```

從 `~/.zshrc` 移除 alias 和 monitor/usage wrapper。執行後會互動詢問是否一併刪除 config 目錄（目錄內可能含登入 session，預設保留）。

### 修改監控 plan

```bash
claude-edit-plan <name> <plan>

claude-edit-plan client1 max5   # 把 client1 從 pro 升級為 max5
```

### 用量監控

```bash
monitor-work              # 即時監測 work 帳號用量（claude-monitor TUI）
monitor-personal          # 即時監測 personal 帳號用量

usage-work                # work 帳號歷史用量
usage-work daily          # 日報
usage-work blocks --live  # 5 小時窗口（即時更新）
```

### 指令速查

```bash
claude-help   # 印出所有指令（動態列出當前帳號）
```

---

## API Key 帳號

若有 API key 帳號（按量計費），參考 `claude-multi-account.zsh` 頂部的注解說明：

1. 建立 `~/.secrets/claude-api-key`，內容：
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-..."
   ```
2. 設定權限：`chmod 600 ~/.secrets/claude-api-key`
3. 取消注解設定檔裡的 `claude-api` alias 那行。

---

## IDE 啟動器

若要讓 VS Code / Cursor 的 Claude 擴充功能使用正確帳號，需從 terminal 啟動 IDE。設定方式見 `claude-multi-account.zsh` 中的 **IDE launchers** 注解區塊，裡面有可直接複製的 alias 範本。

---

## claude-monitor Patch

`claude-monitor` 預設忽略 `CLAUDE_CONFIG_DIR`，固定讀取 `~/.claude`。

> ⚠️ **未套用此 patch 時，`monitor-work` 和 `monitor-personal` 會顯示同一個帳號的資料。** `monitor-*` 系列指令必須套用此 patch 才能正確隔離帳號。

### 確認 / 套用 patch

找到 `main.py`：

```bash
find "$(uv tool dir)/claude-monitor" -name "main.py" -path "*/cli/main.py"
```

開啟檔案，確認 `get_standard_claude_paths` 函式（約第 45 行）長這樣：

```python
def get_standard_claude_paths():
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
    if config_dir:
        return [f"{config_dir.rstrip('/')}/projects"]
    return ["~/.claude/projects", "~/.config/claude/projects"]
```

若沒有 `if config_dir` 那個分支，手動加入即可。

> ⚠️ 執行 `uv tool upgrade claude-monitor` **升級後 patch 會被覆蓋**，每次升級後需重新套用。

### 可選：更完整的隔離 patch

`settings.py`、`bootstrap.py`、`display_controller.py` 還有硬編碼的 `~/.claude-monitor` 和 `~/.claude` 路徑，影響 claude-monitor 自身的 config/cache 儲存位置。若需要完整的帳號隔離，可依同樣方式將這些路徑改為讀取 `CLAUDE_CONFIG_DIR`。

---

## 目錄結構

```
~/.claude-work/        ← 工作帳號 config（token、session）
~/.claude-personal/    ← 個人帳號 config
~/.claude-client1/     ← 用 claude-add-account 新增的帳號
~/.config/claude-multi-account/
  claude-multi-account.zsh   ← 工具集主體（在這裡編輯 alias）
```

---

## 致謝

本工具建立在以下開源專案之上：

- **[claude-monitor](https://github.com/doobidoo/claude-monitor)** by doobidoo — 即時 Claude 用量 TUI
- **[ccusage](https://github.com/ryoppippi/ccusage)** by ryoppippi — 歷史用量報表

---

## 授權

MIT
