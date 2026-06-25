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
- Codex CLI implements, reviews code, commits, and pushes.
- Antigravity CLI writes long-form docs such as READMEs, changelogs, and API documentation.

In normal use, you open Claude Code and speak naturally. The harness rules decide which CLI should handle each stage behind the scenes.

## Why Split The Roles?

Most AI coding setups assume a $100/mo plan. frugal-harness is designed around **Claude Pro ($20/mo)** and **ChatGPT Plus ($20/mo)**, with documentation work delegated to Antigravity CLI.

**Total: $40/mo** as the baseline.

Claude is most efficient when it focuses on planning and orchestration. Codex is better suited for implementation, code review, commits, and pushes. Antigravity is useful for long, repetitive documentation tasks.

This keeps Claude session quota out of routine code editing and uses each tool where it is strongest.

## Agent Roles

| Tool | Model/settings | Role |
|---|---|---|
| Claude Code | `sonnet` by default, Opus only when recommended for complex plans | Planning and orchestration |
| Codex CLI | `gpt-5.5`, plan `medium`, implementation `medium` | Implementation, code review, commit, push |
| Antigravity CLI | default configured | README, changelog, API docs, long-form writing |

Claude does not normally edit code directly. Code implementation and code review belong to Codex.

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

- missing Claude/Codex/agy CLIs using official install paths
- Claude Code default model: `sonnet`
- Codex default model: `gpt-5.5`
- Codex reasoning: planning `medium`, implementation `medium`
- agy default model configured
- the `usage` command
- Claude Code statusline with remaining quota and current session cost
- a PreToolUse guard that blocks Claude from editing source files directly
- `~/.codex/AGENTS.md` for Codex standalone fallback

Set `FRUGAL_SKIP_CLI_INSTALL=1` before running the installer if you want it to only check for missing CLIs and never install them.

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

Claude decides whether the current request is planning, implementation, review, docs, or shipping.

Slash commands are optional shortcuts.

| Stage | Meaning | Owner |
|---|---|---|
| `/plan` | Break down work and call out risks | Claude |
| `/exec` | Implement | Codex \| agy |
| `/review` | Review code | Codex \| agy |
| `/docs` | Write or update docs | agy (→ Codex if exhausted → Claude last resort) |
| `/ship` | Verify, commit, and push | Codex \| agy |

Plain language follows the same routing.

## What Claude Does Not Do

Claude does not normally edit code directly.

- Code implementation: Codex | agy
- Code review: Codex | agy
- Commit messages: Codex | agy
- Commit/push: Codex | agy

If both Codex and agy are exhausted and Claude needs to act as an implementation fallback, the user must explicitly approve that specific fallback. The source-edit guard stays enabled by default, and fallback edits should stay narrow and easy to audit.

Documentation goes to agy first. If agy fails or is out of quota, Codex is the fallback. Claude may edit documentation directly only as the final fallback.

## Model Routing

The default rule is to use the cheapest capable path, then escalate only when planning quality matters.

- Normal planning and orchestration: Claude Sonnet
- Complex planning: Claude recommends Opus, then waits for user approval
- Codex standalone planning: `plan_mode_reasoning_effort = "medium"`
- Codex implementation: `model_reasoning_effort = "medium"`
- Complex Codex standalone planning: recommend rerunning with `high`
- Very complex Codex standalone planning: recommend rerunning with `xhigh`

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
| `shared/agy-wrapper.md` | agy standalone/relay rules |
| `scripts/sync-agents.sh` | Regenerates `~/.codex/AGENTS.md` from shared sources |

To change Codex policy, edit `shared/harness-core.md` or `shared/codex-wrapper.md`, then run:

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

`usage` shows Claude, Codex, and Antigravity usage in one place.

The dashboard is powered by Node.js and does not require `jq`. Codex usage is selected from the newest `token_count` event across all local rollout logs, not from the newest file timestamp.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

Existing config files are backed up before removal.
