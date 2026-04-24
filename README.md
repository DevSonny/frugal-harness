[한국어로 읽기 ->](./README.ko.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness is a low-cost coding harness that combines Claude Pro, ChatGPT Plus, and Gemini CLI so the whole development loop can run without a $100/mo setup.

The core idea is role separation.

- Claude Code plans and orchestrates.
- Codex CLI implements, reviews code, commits, and pushes.
- Gemini CLI writes long-form docs such as READMEs, changelogs, and API documentation.

In normal use, you open Claude Code and speak naturally. The harness rules decide which CLI should handle each stage behind the scenes.

## Why Split The Roles?

Most AI coding setups assume a $100/mo plan. frugal-harness is designed around **Claude Pro ($20/mo)** and **ChatGPT Plus ($20/mo)**, with documentation work delegated to free Gemini CLI.

**Total: $40/mo** as the baseline.

Claude is most efficient when it focuses on planning and orchestration. Codex is better suited for implementation, code review, commits, and pushes. Gemini is useful for long, repetitive documentation tasks.

This keeps Claude session quota out of routine code editing and uses each tool where it is strongest.

## Agent Roles

| Tool | Model/settings | Role |
|---|---|---|
| Claude Code | `sonnet` by default, Opus only when recommended for complex plans | Planning and orchestration |
| Codex CLI | `gpt-5.5`, plan `high`, implementation `medium` | Implementation, code review, commit, push |
| Gemini CLI | `gemini-2.5-flash-lite`, free 1,000 req/day | README, changelog, API docs, long-form writing |

Claude does not normally edit code directly. Code implementation and code review belong to Codex.

## Prerequisites

### 1. Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

The baseline assumes **Claude Pro ($20/mo)**.

### 2. Codex CLI

```bash
npm install -g @openai/codex
codex login
```

The baseline assumes **ChatGPT Plus ($20/mo)**.

### 3. Gemini CLI

```bash
npm install -g @google/gemini-cli
```

Gemini CLI needs an API key.

```bash
export GEMINI_API_KEY="your-key-here"
gemini -p 'say hi'
```

Get a free key at <https://aistudio.google.com/apikey>.

### 4. jq

The `usage` dashboard and installer use `jq` for JSON handling.

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

The installer configures:

- Claude Code default model: `sonnet`
- Codex default model: `gpt-5.5`
- Codex reasoning: planning `high`, implementation `medium`
- Gemini default model: `gemini-2.5-flash-lite`
- the `usage` command
- Claude Code slash commands under `~/.claude/commands`
- Claude Code statusline
- a PreToolUse guard that blocks Claude from editing source files directly
- `~/.codex/AGENTS.md` for Codex standalone fallback

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

| Command | Meaning | Owner |
|---|---|---|
| `/plan` | Break down work and call out risks | Claude |
| `/exec` | Implement | Codex |
| `/review` | Review code | Codex |
| `/docs` | Write or update docs | Gemini (→ Codex if exhausted → Claude last resort) |
| `/ship` | Verify, commit, and push | Codex |

Plain language follows the same routing.

## What Claude Does Not Do

Claude does not normally edit code directly.

- Code implementation: Codex
- Code review: Codex
- Commit messages: Codex
- Commit/push: Codex

If Codex quota is exhausted and Claude needs to act as an implementation fallback, the user must explicitly approve that specific fallback. The source-edit guard stays enabled by default, and fallback edits should stay narrow and easy to audit.

Documentation goes to Gemini first. If Gemini fails or is out of quota, Codex is the fallback. Claude may edit documentation directly only as the final fallback.

## Model Routing

The default rule is to use the cheapest capable path, then escalate only when planning quality matters.

- Normal planning and orchestration: Claude Sonnet
- Complex planning: Claude recommends Opus, then waits for user approval
- Codex standalone planning: `plan_mode_reasoning_effort = "high"`
- Codex implementation: `model_reasoning_effort = "medium"`
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
| `skills/*.md` | Short optional slash-command prompts |
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

`usage` shows Claude, Codex, and Gemini usage in one place.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

Existing config files are backed up before removal.
