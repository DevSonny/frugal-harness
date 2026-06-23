[한국어로 읽기 ->](./README.ko.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness is a low-cost coding harness that combines Claude Pro, ChatGPT Plus, and Antigravity CLI so the whole development loop can run without a $100/mo setup.

The core idea is role separation.

- Claude Code plans and orchestrates.
- Worker agents (Codex CLI, Antigravity CLI) implement, review, write docs, commit, and push.
- You pick which worker handles each role — and in what priority order — with `frugal config`.

In normal use, you open Claude Code and speak naturally. The harness rules decide which agent should handle each stage behind the scenes, following your delegation profile.

## Why Split The Roles?

Most AI coding setups assume a $100/mo plan. frugal-harness is designed around **Claude Pro ($20/mo)** and **ChatGPT Plus ($20/mo)**, with documentation work delegated to Antigravity CLI.

**Total: $40/mo** as the baseline.

Claude is most efficient when it focuses on planning and orchestration. Codex is better suited for implementation, code review, commits, and pushes. Antigravity is useful for long, repetitive documentation tasks.

This keeps Claude session quota out of routine code editing and uses each tool where it is strongest.

## Agent Roles

| Tool | Model/settings | Role |
|---|---|---|
| Claude Code | `sonnet` by default, Opus only when recommended for complex plans | Planning and orchestration (always plans) |
| Codex CLI | `gpt-5.5`, plan `medium`, implementation `medium` | Worker: implementation, review, docs, commit, push |
| Antigravity CLI | `Claude Sonnet 4.6 (Thinking)` default; `Claude Opus 4.6 (Thinking)` for complex; `Gemini 3.1 Pro (High)` → `Gemini 3.5 Flash (Medium)` when Claude quota exhausted | Worker: implementation, review, docs, long-form writing |

Claude always plans and never edits code directly during normal operation. Every other role (implementation, review, docs, ship) is delegated to a worker agent. Which worker runs first for each role is set by your delegation profile (`frugal config`); the harness tries the first agent in a role's priority list and falls back to the next.

## Prerequisites

### 1. Node.js and npm

frugal-harness uses Node.js to parse local JSON/JSONL usage files without requiring `jq`. The Codex and Antigravity official install paths also use npm or native curl scripts.

Install Node.js first if you do not already have it:

```bash
# macOS
brew install node

# Ubuntu/Debian/WSL
sudo apt install nodejs npm
```

### 2. Agent CLIs

The installer can install missing CLIs automatically using official install paths:

| CLI | Install path used by frugal-harness |
|---|---|
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Codex CLI | `npm install -g @openai/codex` |
| Antigravity CLI | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |

After installation, log in:

```bash
claude login
codex login
```

Antigravity CLI requires you to login with your subscription.

```bash
agy login
agy -p 'say hi'
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

The installer configures:

- Claude Code (auto-installed if missing); Codex CLI and Antigravity CLI prompt `[y/N]` before installing
- Claude Code default model: `sonnet`
- Codex default model: `gpt-5.5`
- Codex reasoning: planning `medium`, implementation `medium`
- Antigravity default model: `Claude Sonnet 4.6 (Thinking)`; model fallback chain configured (Sonnet → Opus → Gemini Pro → Gemini Flash)
- the `usage` command
- the `frugal` command for configuring agent subscription and per-role priority
- a default delegation profile at `~/.config/frugal/profile.json` (subscribed = installed CLIs; priority: Antigravity → Codex, ship Codex → Antigravity)
- `~/.claude/shared/delegation-profile.md`, the rendered profile imported by `CLAUDE.md`
- Claude Code statusline with remaining quota and current session cost
- a PreToolUse guard that guides Claude away from editing source files directly
- `~/.codex/AGENTS.md` for Codex standalone fallback (carries the same priority)
- [caveman](https://github.com/JuliusBrussee/caveman) Claude Code plugin — compressed communication mode that cuts token usage ~75%
- [mattpocock/skills](https://github.com/mattpocock/skills) — installs `grill-me`, `grill-with-docs`, and `grilling` skills (and 30+ more) globally via `npx skills@latest`

To change which agents you subscribe to or their per-role priority, run `frugal config` after install.

No manual `/model` command is needed for normal work. For complex planning, Claude recommends Opus and only switches after user approval.

## How To Use It

Natural language is the default interface.

```text
"Plan this feature."
"Now implement it."
"Review the code."
"Update the docs."
"Run checks, commit, and push."
```

Claude decides whether the current request is planning, implementation, review, docs, or shipping, then delegates each non-planning step to the highest-priority available worker from your delegation profile.

There are no slash commands — natural language is the only interface.

## Configure Agent Priority

Run `frugal config` to choose which worker agents you subscribe to and set the per-role delegation priority:

```bash
frugal config
```

It detects the installed CLIs (`agy`, `codex`), confirms which you subscribe to, and asks the priority order for `exec`, `review`, `docs`, and `ship`. Planning always stays with Claude. Your answers are saved to `~/.config/frugal/profile.json` and rendered into `~/.claude/shared/delegation-profile.md` (imported by `CLAUDE.md`) and `~/.codex/AGENTS.md`.

Example profile (Antigravity preferred, Codex as fallback):

```json
{
  "agents": ["antigravity", "codex"],
  "roles": {
    "plan":   ["claude"],
    "exec":   ["antigravity", "codex"],
    "review": ["antigravity", "codex"],
    "docs":   ["antigravity", "codex"],
    "ship":   ["codex", "antigravity"]
  },
  "routing": "complexity-auto"
}
```

## What Claude Does Not Do

Claude does not normally edit code directly. Each role is delegated to a worker agent following the priority order in your delegation profile:

- Code implementation: highest-priority worker for `exec`
- Code review: highest-priority worker for `review`
- Docs: highest-priority worker for `docs`
- Commit messages / commit / push: highest-priority worker for `ship` (Codex writes its own commit message)

If a worker is out of quota, the harness falls back to the next agent in that role's list. If no worker can act and Claude needs to be the implementation fallback, the user must explicitly approve that specific fallback. The source-edit guard stays enabled by default, and fallback edits should stay narrow and easy to audit.

## Model Routing

The default rule is to use the cheapest capable path, then escalate only when planning quality matters.

- Normal planning and orchestration: Claude Sonnet
- Complex planning: Claude recommends Opus, then waits for user approval
- Codex standalone planning: `plan_mode_reasoning_effort = "medium"`
- Codex implementation: `model_reasoning_effort = "medium"`
- Complex Codex standalone planning: recommend rerunning with `high`
- Very complex Codex standalone planning: recommend rerunning with `xhigh`
- Antigravity standard task: `agy --model "Claude Sonnet 4.6 (Thinking)" -p "<task>"`
- Antigravity complex task: `agy --model "Claude Opus 4.6 (Thinking)" -p "<task>"`
- Antigravity Claude quota exhausted: switch to `Gemini 3.1 Pro (High)`, then `Gemini 3.5 Flash (Medium)`

A task counts as complex planning when it likely involves:

- 10 or more files
- architecture, DB schema, or API design changes
- cross-module dependency analysis
- a broad refactor
- judgment-heavy structure or design decisions

## Quality Gate

The harness is not web-only. Codex first discovers the project's standard verification commands, then runs checks that match the stack and the change.

Places to inspect first:

- README
- CI config
- Makefile, Justfile, Taskfile
- `package.json`
- `pyproject.toml`, `tox.ini`, `noxfile.py`
- `Cargo.toml`
- `go.mod`
- `pom.xml`, `build.gradle`

For code changes, run the relevant layers when available:

- build/compile
- tests
- static analysis/lint
- format check
- type/static correctness

Examples:

| Ecosystem | Typical checks |
|---|---|
| Node/TypeScript | `npm test`, `npm run lint`, `npm run build`, `tsc --noEmit` |
| Python | `pytest`, `ruff check`, `ruff format --check`, `mypy` or `pyright` |
| Go | `go test ./...`, `go vet ./...`, `gofmt` |
| Rust | `cargo test`, `cargo check`, `cargo clippy` |

For docs or config-only changes, run affected validation instead of the full test suite: Markdown checks, JSON/YAML/TOML parsing, shell syntax checks, or generation scripts.

If a relevant command cannot be found or cannot run, the final report must say what was skipped, why, and what manual review was done instead.

## AGENTS.md Structure

`~/.codex/AGENTS.md` is generated output. Do not edit it directly.

Source files:

| File | Role |
|---|---|
| `CLAUDE.md` | Claude role and delegation rules |
| `shared/harness-core.md` | Shared policy for Claude and Codex |
| `shared/codex-wrapper.md` | Codex standalone/relay rules |
| `~/.claude/shared/delegation-profile.md` | Rendered per-role priority (generated by `frugal config`) |
| `scripts/render-profile.sh` | Renders the profile and pins subscribed-agent defaults |
| `scripts/sync-agents.sh` | Regenerates `~/.codex/AGENTS.md` from shared sources + profile |

To change Codex policy, edit `shared/harness-core.md` or `shared/codex-wrapper.md`, then run:

```bash
scripts/sync-agents.sh
```

To change which agents handle which role, run `frugal config` (it regenerates the profile and `AGENTS.md` for you).

## Usage Dashboard

```bash
usage
```

Inside Claude Code, run it through the shell:

```bash
! usage
```

`usage` shows Claude, Codex, and Antigravity usage in one place.

The dashboard is powered by Node.js and does not require `jq`. Codex usage is selected from the newest `token_count` event across all local rollout logs, not from the newest file timestamp.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

Existing config files are backed up before removal.
