[한국어로 읽기 ->](./README.ko.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness is a low-cost AI coding harness that keeps the whole development loop — plan, implement, review, commit, push — running on affordable subscriptions instead of a $100/mo setup.

The core idea is **role separation**. However, you get to choose your **main handler** (the agent you talk to) and your **helper agents** (who receive delegated tasks).

## Cost Combinations

Most AI coding setups assume a $100/mo plan. But frugal-harness lets you build your own combination:

| Main Handler | Helper Agent(s) | Monthly cost |
|---|---|---|
| Claude Code | + Codex | ~$40/mo (Claude Pro + ChatGPT Plus) |
| Claude Code | + agy | ~$40/mo (Claude Pro + Antigravity) |
| Claude Code | + both | ~$60/mo |
| agy | None | ~$20/mo (Antigravity) |
| agy | + Claude | ~$40/mo |
| Codex | None | ~$20/mo (ChatGPT Plus) |
| Codex | + Claude | ~$40/mo |

## Behavior by Main Handler

The way the harness works depends on which agent you choose as your main handler.

| Main Handler | What it does | Helpers it can delegate to |
|---|---|---|
| **Claude Code** | Plans and orchestrates. It does not normally edit code directly. It delegates implementation, review, commit, and push to helpers. | agy, Codex |
| **agy** | End-to-end agent: plans, implements, reviews, commits, and pushes directly. | Claude, Codex |
| **Codex CLI** | End-to-end agent: plans, implements, reviews, commits, and pushes directly. | Claude, agy |

> [!IMPORTANT]
> When **agy** or **Codex** is your main handler, they are self-sufficient. They don't need to delegate — they ARE the executor. The helpers are strictly optional fallbacks.

## Prerequisites

### 1. Node.js and npm

frugal-harness uses Node.js to parse local JSON/JSONL usage files without requiring `jq`.

```bash
# macOS
brew install node

# Ubuntu/Debian/WSL
sudo apt install nodejs npm
```

### 2. Agent CLIs

The installer can install missing CLIs automatically using official install paths:

| CLI | Install path |
|---|---|
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Codex CLI | `npm install -g @openai/codex` |
| Antigravity CLI | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |

After installation, log in to the CLIs you chose:

```bash
claude login        # if using Claude
codex login         # if using Codex
agy login           # if using agy
```

## Install

Run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

The interactive prompt will ask:
1. **Which is your main handler?** (Claude, agy, or Codex)
2. **Install helper agents?** (for delegation/fallback)
3. **Deploy CLAUDE.md anyway?** (if Claude is not your main handler, you can still install its rules for occasional use)

### Non-interactive Installation

You can set environment variables to skip the prompts:

```bash
# Claude main + agy helper
FRUGAL_MAIN=claude FRUGAL_HELPERS=agy bash install.sh

# agy main, no helpers
FRUGAL_MAIN=agy FRUGAL_HELPERS=none bash install.sh

# Codex main + Claude helper
FRUGAL_MAIN=codex FRUGAL_HELPERS=claude bash install.sh
```

## Optional Skills

The installer prompts you to install these after the main setup:

| Skill | Agents | Recommendation | What it does |
|---|---|---|---|
| **caveman** | Claude Code, Codex, agy | ★ Strongly recommended | Cuts token output up to 75% with no loss of technical accuracy. Same substance, much shorter responses. |
| **superpowers** | Claude Code, Codex, agy | Recommended | Relentless Socratic interview to stress-test a plan before coding. Catches gaps early, saves tokens on rework. |

To install non-interactively:

```bash
FRUGAL_INSTALL_CAVEMAN=1 FRUGAL_INSTALL_GRILLME=1 bash install.sh
```

Or install caveman anytime:

```bash
claude plugin install caveman
```

## Configuration (Post-Install)

If you want to change your main handler or helpers later, use the included config utility instead of running the full installer again:

```bash
frugal-config                    # Interactive menu
frugal-config --main agy         # Change main handler
frugal-config --helpers claude   # Change helpers
```

This will save your preferences to `~/.frugal-harness/config.sh` and automatically regenerate your rules.

## Model Routing

The default rule is to use the cheapest capable path, then escalate only when planning quality matters.

- Normal planning and orchestration: Default models (`sonnet`, `gpt-5.5`, or `gemini-3.5-flash`)
- Complex planning: The main handler recommends escalating to an advanced reasoning model, then waits for user approval

A task counts as complex planning when it likely involves:
- 10 or more files
- Architecture, DB schema, or API design changes
- Cross-module dependency analysis
- A broad refactor
- Judgment-heavy structure or design decisions

### agy model selection

When agy is used (either as main or helper), it picks a model based on task complexity:

| Task | Model |
|---|---|
| Quick implementation / simple fix | `Gemini 3.5 Flash (Medium)` |
| Complex implementation | `Gemini 3.1 Pro (High)` or `Claude Sonnet 4.6 (Thinking)` |
| Architecture / judgment-heavy | `Claude Opus 4.6 (Thinking)` |
| Documentation / README | `Gemini 3.5 Flash (Low)` |
| Code review | `Gemini 3.1 Pro (Low)` |

> **Important:** The `--model` value must match `agy models` output exactly (case-sensitive, parentheses included). Abbreviated or wrong names (e.g. `"sonnet"`, `"opus"`) silently fall back to `Gemini 3.5 Flash (Medium)` with no error. Run `agy models` to verify exact names.

### Codex reasoning effort

When Codex is used, default reasoning is `medium` for both planning and implementation. For complex planning, the harness recommends rerunning with `high` or `xhigh`.

## Quality Gate

The harness is not web-only. The implementation agent first discovers the project's standard verification commands, then runs checks that match the stack and the change.

Places to inspect first:
- README
- CI config
- Makefile, Justfile, Taskfile
- `package.json`
- `pyproject.toml`, `tox.ini`, `noxfile.py`
- `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`

For code changes, run the relevant layers when available: build/compile, tests, lint, format check, type check.

For docs or config-only changes, run affected validation instead of the full test suite. If a relevant command cannot be found or cannot run, the final report must say what was skipped, why, and what manual review was done instead.

## Rules Structure

The generated `AGENTS.md` files are auto-generated output. Do not edit them directly.

| Generated file | Role |
|---|---|
| `~/.claude/CLAUDE.md` | Claude Code rules |
| `~/.codex/AGENTS.md` | Codex rules (main handler or helper depending on config) |
| `~/.gemini/config/AGENTS.md` | agy rules (main handler or helper depending on config) |

Source files:

| File | Role |
|---|---|
| `shared/harness-core.md` | Shared policy across all agents |
| `shared/codex-wrapper-main.md` | Codex standalone rules |
| `shared/codex-wrapper-helper.md` | Codex relay rules |
| `shared/agy-wrapper-*.md` | agy rules (main/helper) |

To change policy, edit the shared source files, then run `frugal-config` to regenerate.

## Usage Dashboard

```bash
usage
```

Inside Claude Code, run it through the shell: `! usage`

`usage` shows Claude and implementation agent usage in one place. The dashboard is powered by Node.js and does not require `jq`. Codex usage is selected from the newest `token_count` event across all local rollout logs.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

Existing config files are backed up before removal.
