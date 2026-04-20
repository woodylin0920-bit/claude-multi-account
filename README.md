# claude-multi-account

在同一台 Mac 上管理多個 Claude Code 帳號的 zsh 工具集。

## 問題背景

macOS Keychain **只能存一個** Claude OAuth token。當你有工作帳號（Max）和個人帳號（Pro）時，每次切換都要重新 `/login`，非常麻煩。

**解法**：Claude Code 支援 `CLAUDE_CONFIG_DIR` 環境變數，讓每個帳號使用獨立的 config 目錄（`~/.claude-work`、`~/.claude-personal`...），token 互不干擾。這個工具集把這個模式包裝成方便的指令。

## 需求

| 工具 | 用途 | 必要？ |
|------|------|--------|
| [Claude Code CLI](https://claude.ai/download) | 核心 | ✅ 必要 |
| [claude-monitor](https://github.com/doobidoo/claude-monitor) | 即時用量監控（`monitor-*`） | 選用 |
| [ccusage](https://github.com/ryoppippi/ccusage) | 歷史用量查詢（`usage-*`） | 選用 |

## 安裝

```bash
git clone https://github.com/YOUR_USERNAME/claude-multi-account.git
cd claude-multi-account
bash install.sh
```

接著編輯 `~/.config/claude-multi-account/claude-multi-account.zsh`，取消注解帳號 alias：

```zsh
# 改成這樣（照自己的帳號數量增減）：
alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'
```

最後套用設定：

```bash
source ~/.zshrc
```

## 第一次登入各帳號

```bash
claude-work     # 進入工作帳號的 claude shell
/login          # 在 claude 裡執行登入
# 登入完成後 Ctrl+D 離開

claude-personal
/login
```

用 `claude-whoami` 驗證登入狀態。

## 指令說明

### 帳號狀態

```
claude-whoami
```

掃描所有 `~/.claude-*` 目錄，顯示各帳號的登入狀態、email 和方案。

### 新增帳號槽

```bash
claude-add-account <name> [plan]
# plan 預設 pro，可填 pro / max5 / max20

# 範例
claude-add-account client1 max5
```

自動建立 `~/.claude-client1/`，並在 `~/.zshrc` 加上 alias 和監控 wrapper。

### 移除帳號槽

```bash
claude-remove-account client1
```

從 `~/.zshrc` 移除對應的 alias 和 monitor/usage wrapper。執行後會詢問是否一併刪除 config 目錄（目錄內含登入 session，預設不刪）。

### 修改監控 plan

```bash
claude-edit-plan <name> <plan>

# 範例：把 client1 從 pro 改成 max5
claude-edit-plan client1 max5
```

### 用量監控

```bash
monitor-work        # 即時監測工作帳號（claude-monitor UI）
monitor-personal    # 即時監測個人帳號

usage-work          # 工作帳號歷史用量
usage-work daily    # 日報
usage-work blocks --live   # 5 小時用量窗口（即時更新）
```

### 速查

```bash
claude-help   # 顯示所有指令（動態列出當前帳號）
```

## API Key 帳號設定

若有 API key 帳號（按量計費），參考 `claude-multi-account.zsh` 頂部的注解：

1. 建立 `~/.secrets/claude-api-key`，內容：
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-..."
   ```
2. 設定權限：`chmod 600 ~/.secrets/claude-api-key`
3. 在 `claude-multi-account.zsh` 取消注解 `claude-api` alias 那行

## IDE 啟動器設定

若要讓 VS Code / Cursor 的 Claude 擴充功能使用正確帳號，需從 terminal 啟動 IDE。設定方式見 `claude-multi-account.zsh` 中的「IDE launchers」注解區塊。

## claude-monitor patch

`claude-monitor` 預設不讀取 `CLAUDE_CONFIG_DIR`，需要手動 patch 才能讓 `monitor-*` 系列指令正確隔離帳號。

**確認 / 套用 patch：**

找到 `main.py`：
```bash
find "$(uv tool dir)/claude-monitor" -name "main.py" -path "*/cli/main.py"
```

確認 `get_standard_claude_paths` 函式有以下邏輯（約第 45 行）：

```python
def get_standard_claude_paths():
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
    if config_dir:
        return [f"{config_dir.rstrip('/')}/projects"]
    return ["~/.claude/projects", "~/.config/claude/projects"]
```

若沒有，手動加上這個 `if` 分支即可。

> ⚠️ 執行 `uv tool upgrade claude-monitor` 升級後 patch 會被覆蓋，需重新套用。

### 可選：更完整的隔離 patch

`settings.py`、`bootstrap.py`、`display_controller.py` 也有殘留的硬編碼路徑，影響 claude-monitor 自身的 config/cache 儲存位置。若你需要完整隔離，可依同樣方式將這些檔案中的 `Path.home() / ".claude-monitor"` 和 `Path.home() / ".claude"` 改為讀取 `CLAUDE_CONFIG_DIR`。

## 目錄結構

```
~/.claude-work/       ← 工作帳號 config（token、session）
~/.claude-personal/   ← 個人帳號 config
~/.claude-client1/    ← 用 claude-add-account 新增的帳號
~/.config/claude-multi-account/
  claude-multi-account.zsh   ← 工具集主體
```

## License

MIT
