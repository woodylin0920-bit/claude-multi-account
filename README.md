[繁體中文](README.zh-TW.md)

# claude-multi-account

Manage multiple Claude Code accounts on the same Mac — bypass the single-token Keychain limitation via `CLAUDE_CONFIG_DIR`.

> **macOS only.** Built on top of [claude-monitor](https://github.com/doobidoo/claude-monitor) and [ccusage](https://github.com/ryoppippi/ccusage).

## The Problem

macOS Keychain stores **only one** Claude OAuth token. If you have a work account (Max) and a personal account (Pro), you have to `/login` again every time you switch — losing your active session in the process.

**The fix:** Claude Code respects the `CLAUDE_CONFIG_DIR` environment variable. Point each alias at its own directory (`~/.claude-work`, `~/.claude-personal`, …) and the tokens never collide.

---

## Quick Start

```bash
# 1. Clone and install
git clone https://github.com/woodylin0920-bit/claude-multi-account.git
cd claude-multi-account
bash install.sh

# 2. Edit the config file — uncomment the alias lines for your accounts
#    (replace "work" / "personal" with whatever names you prefer)
open ~/.config/claude-multi-account/claude-multi-account.zsh

# 3. Reload your shell
source ~/.zshrc

# 4. Add an account slot and log in
claude-add-account work max5   # creates ~/.claude-work + adds alias + monitor wrapper
claude-work                    # opens Claude Code under the "work" config
# Inside Claude: /login
# Press Ctrl+D when done

# 5. Verify
claude-whoami
```

---

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| [Claude Code CLI](https://claude.ai/code) | ✅ Yes | See link |
| [ccusage](https://github.com/ryoppippi/ccusage) | Optional | `npm install -g ccusage` |
| [claude-monitor](https://github.com/doobidoo/claude-monitor) | Optional | `uv tool install claude-monitor` |

> **Note:** `monitor-*` commands require claude-monitor **and** its CLAUDE_CONFIG_DIR patch (see below). Without the patch, all monitor instances read from the same account.

---

## Installation

```bash
git clone https://github.com/woodylin0920-bit/claude-multi-account.git
cd claude-multi-account
bash install.sh
```

`install.sh` copies `claude-multi-account.zsh` to `~/.config/claude-multi-account/` and appends a `source` line to your `~/.zshrc`.

---

## Configuration

After installing, edit the config file:

```bash
open ~/.config/claude-multi-account/claude-multi-account.zsh
# or: $EDITOR ~/.config/claude-multi-account/claude-multi-account.zsh
```

**Uncomment and fill in the alias block** near the top of the file:

```zsh
# Before (commented out — examples only):
# alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
# alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'

# After (your actual accounts):
alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
alias claude-personal='CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude'
```

**Also update the monitor wrappers** a few lines below, to match your account names and plans:

```zsh
monitor-work()     { CLAUDE_CONFIG_DIR=$HOME/.claude-work     claude-monitor --plan max5 "$@"; }
monitor-personal() { CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude-monitor --plan pro  "$@"; }
usage-work()       { CLAUDE_CONFIG_DIR=$HOME/.claude-work     ccusage "$@"; }
usage-personal()   { CLAUDE_CONFIG_DIR=$HOME/.claude-personal ccusage "$@"; }
```

Then reload: `source ~/.zshrc`

---

## Commands

### Account status

```bash
claude-whoami
```

Scans all `~/.claude-*` directories registered in `~/.zshrc` and shows login status, email, and plan for each.

### Add an account slot

```bash
claude-add-account <name> [plan]
# plan defaults to "pro" — options: pro / max5 / max20

claude-add-account client1 max5
```

Creates `~/.claude-client1/` and appends the alias + monitor/usage wrappers to `~/.zshrc`.

### Remove an account slot

```bash
claude-remove-account client1
```

Removes the alias and monitor/usage wrappers from `~/.zshrc`. Prompts interactively whether to also delete the config directory (it may contain an active login session, so deletion is opt-in).

### Edit monitor plan

```bash
claude-edit-plan <name> <plan>

claude-edit-plan client1 max5   # upgrade client1 from pro to max5
```

### Usage monitoring

```bash
monitor-work              # live usage dashboard for "work" account (claude-monitor TUI)
monitor-personal          # live usage dashboard for "personal" account

usage-work                # usage history for "work" account
usage-work daily          # daily breakdown
usage-work blocks --live  # 5-hour rolling window, live-updating
```

### Quick reference

```bash
claude-help   # print all commands with your current account list
```

---

## API Key Account

For API key accounts (pay-as-you-go), see the commented instructions near the top of `claude-multi-account.zsh`:

1. Create `~/.secrets/claude-api-key`:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-..."
   ```
2. Lock it down: `chmod 600 ~/.secrets/claude-api-key`
3. Uncomment the `claude-api` alias line in the config file.

---

## IDE Launcher

To ensure VS Code / Cursor extensions use the correct Claude account, launch them from the terminal. See the **IDE launchers** comment block in `claude-multi-account.zsh` for ready-to-use alias templates.

---

## claude-monitor Patch

By default, `claude-monitor` ignores `CLAUDE_CONFIG_DIR` and always reads from `~/.claude`.

> ⚠️ **Without this patch, `monitor-work` and `monitor-personal` will show data from the same account.** The patch is required for the `monitor-*` wrappers to work correctly.

### Verify / apply the patch

Find `main.py`:

```bash
find "$(uv tool dir)/claude-monitor" -name "main.py" -path "*/cli/main.py"
```

Open the file and check that `get_standard_claude_paths` (around line 45) looks like this:

```python
def get_standard_claude_paths():
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
    if config_dir:
        return [f"{config_dir.rstrip('/')}/projects"]
    return ["~/.claude/projects", "~/.config/claude/projects"]
```

If the `if config_dir` block is missing, add it manually.

> ⚠️ Running `uv tool upgrade claude-monitor` **overwrites the patch**. Re-apply after every upgrade.

### Optional: full isolation patch

`settings.py`, `bootstrap.py`, and `display_controller.py` still contain hardcoded `~/.claude-monitor` and `~/.claude` paths that affect where claude-monitor stores its own config/cache. If you need complete per-account isolation, update those files to read `CLAUDE_CONFIG_DIR` in the same way.

---

## Directory Layout

```
~/.claude-work/        ← work account config (token, session)
~/.claude-personal/    ← personal account config
~/.claude-client1/     ← added via claude-add-account
~/.config/claude-multi-account/
  claude-multi-account.zsh   ← the tool itself (edit aliases here)
```

---

## Acknowledgements

This tool is built on top of:

- **[claude-monitor](https://github.com/doobidoo/claude-monitor)** by doobidoo — real-time Claude usage TUI
- **[ccusage](https://github.com/ryoppippi/ccusage)** by ryoppippi — historical usage reports

---

## License

MIT
