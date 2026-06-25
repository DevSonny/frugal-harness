[한국어로 읽기 ->](./README.ko.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness is a low-cost AI coding harness that keeps the whole development loop — plan, implement, review, commit, push — running on affordable subscriptions instead of a $100/mo setup.

The core idea is **role separation**:

- **Claude Code** plans and orchestrates.
- An **implementation agent** (Codex CLI or Antigravity CLI) implements, reviews, commits, and pushes.

You open Claude Code and speak naturally. The harness rules decide which agent handles each stage behind the scenes.

## Why Split The Roles?

Most AI coding setups assume a $100/mo plan. frugal-harness is built around cheaper subscriptions:

| Setup | Monthly cost |
|---|---|
| Claude Pro + Codex (ChatGPT Plus) | ~$40/mo |
| Claude Pro + agy | ~$20/mo + agy subscription |
| Claude Pro + both | ~$40/mo + agy subscription |

Claude is most efficient when it focuses on planning and orchestration. Implementation, code review, commits, and pushes are delegated to an implementation agent that is better suited for those tasks.

This keeps Claude session quota out of routine code editing and uses each tool where it is strongest.

## Agent Roles

| Agent | Role |
|---|---|
| Claude Code | Planning and orchestration (default `sonnet`, Opus only for complex plans) |
| Codex CLI | Implementation, code review, commit, push (if installed) |
| Antigravity CLI (agy) | Implementation, code review, commit, push, documentation (if installed) |

Claude does not normally edit code directly. Code implementation and code review are delegated to the installed implementation agent(s).

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
claude login        # always required
codex login         # if using Codex
agy login           # if using agy
```

## Install

The installer asks which implementation agent(s) to use:

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

You can also set `FRUGAL_AGENT` to skip the prompt:

```bash
# Codex only
FRUGAL_AGENT=1 bash install.sh

# agy only
FRUGAL_AGENT=2 bash install.sh

# Both
FRUGAL_AGENT=3 bash install.sh
```

The installer configures:

- Missing CLIs using official install paths (set `FRUGAL_SKIP_CLI_INSTALL=1` to skip)
- Claude Code default model: `sonnet`
- Codex default model and reasoning effort (if Codex selected)
- The `usage` command for quota monitoring
- Claude Code statusline with remaining quota and current session cost
- `~/.codex/AGENTS.md` for Codex standalone fallback (if Codex selected)
- `~/.gemini/config/AGENTS.md` for agy standalone fallback (if agy selected)

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

Claude decides whether the current request is planning, implementation, review, docs, or shipping, and delegates to the appropriate agent.

## What Claude Does Not Do

Claude does not normally edit code directly.

- Code implementation → implementation agent
- Code review → implementation agent
- Commit messages → implementation agent
- Commit/push → implementation agent

If the implementation agent is exhausted and Claude needs to act as a fallback, the user must explicitly approve. Fallback edits should stay narrow and easy to audit.

Documentation goes to agy first (if installed). If agy is unavailable, Codex is the fallback. Claude may edit documentation directly only as the final fallback.

## Model Routing

The default rule is to use the cheapest capable path, then escalate only when planning quality matters.

- Normal planning and orchestration: Claude Sonnet
- Complex planning: Claude recommends Opus, then waits for user approval

A task counts as complex planning when it likely involves:

- 10 or more files
- Architecture, DB schema, or API design changes
- Cross-module dependency analysis
- A broad refactor
- Judgment-heavy structure or design decisions

### agy model selection

When Claude delegates to agy, it picks a model based on task complexity:

| Task | Model |
|---|---|
| Quick implementation / simple fix | `Gemini 3.5 Flash (Medium)` |
| Complex implementation | `Gemini 3.1 Pro (High)` or `Claude Sonnet 4.6 (Thinking)` |
| Architecture / judgment-heavy | `Claude Opus 4.6 (Thinking)` |
| Documentation / README | `Gemini 3.5 Flash (Low)` |
| Code review | `Gemini 3.1 Pro (Low)` |

### Codex reasoning effort

If Codex is installed, default reasoning is `medium` for both planning and implementation. For complex standalone planning, the harness recommends rerunning with `high` or `xhigh`.

## Quality Gate

The harness is not web-only. The implementation agent first discovers the project's standard verification commands, then runs checks that match the stack and the change.

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

The generated AGENTS.md files are auto-generated output. Do not edit them directly.

| Generated file | Agent |
|---|---|
| `~/.codex/AGENTS.md` | Codex standalone fallback |
| `~/.gemini/config/AGENTS.md` | agy standalone fallback |

Source files:

| File | Role |
|---|---|
| `CLAUDE.md` | Claude role and delegation rules |
| `shared/harness-core.md` | Shared policy across all agents |
| `shared/codex-wrapper.md` | Codex standalone/relay rules |
| `shared/agy-wrapper.md` | agy standalone/relay rules |
| `scripts/sync-agents.sh` | Regenerates AGENTS.md from shared sources |

To change policy, edit the shared source files, then run:

```bash
scripts/sync-agents.sh
```

## Usage Dashboard

```bash
usage
```

Inside Claude Code, run it through the shell:

```bash
! usage
```

`usage` shows Claude and implementation agent usage in one place.

The dashboard is powered by Node.js and does not require `jq`. Codex usage is selected from the newest `token_count` event across all local rollout logs, not from the newest file timestamp.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

Existing config files are backed up before removal.
