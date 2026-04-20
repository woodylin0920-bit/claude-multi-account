# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.0] - 2026-04-20

### Added

- `claude-whoami` — scan all registered `~/.claude-*` directories and display login status, email, and plan for each account
- `claude-add-account` / `claude-remove-account` / `claude-edit-plan` — manage account slots without manually editing `~/.zshrc`
- `monitor-*` / `usage-*` wrappers — per-account shortcuts for claude-monitor and ccusage
- `claude-help` — dynamic quick-reference that lists your current accounts
- `install.sh` — one-command install: copies the `.zsh` file and adds a `source` line to `~/.zshrc`
- claude-monitor `CLAUDE_CONFIG_DIR` patch instructions — documents the required patch so `monitor-*` commands read the correct account data
