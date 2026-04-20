[한국어로 읽기 →](./README.ko.md)

# frugal-harness

**Plan with Opus. Build with Codex. Document with Gemini. Ship cheap.**

Most AI coding setups assume you're on a $100/mo plan.
This one doesn't.

frugal-harness is built for **Claude Pro ($20/mo)** and **ChatGPT Plus ($20/mo)** users
who want a real multi-agent workflow — without the $100+ price tag.
Gemini CLI handles all the documentation for free.

It takes the best ideas from two great projects —
**[gstack](https://github.com/garrytan/gstack)** by Garry Tan (YC CEO)
and **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** —
and strips them down to what actually matters.

---

## The three-agent lineup

| Agent | Plan | Role |
|---|---|---|
| **Claude Code** (Opus) | Claude Pro $20/mo | Planning, architecture, review |
| **Codex CLI** | ChatGPT Plus $20/mo | Implementation, coding |
| **Gemini CLI** | Free (1,000 req/day) | Docs, README, changelogs, comments |

**Total: $40/mo.** No $100 plan needed.

---

## What's inside

| File | What it does |
|---|---|
| `CLAUDE.md` | Global rules + skill loader |
| `skills/plan.md` | Think before you build |
| `skills/exec.md` | Build from the plan |
| `skills/review.md` | Catch issues before committing |
| `skills/docs.md` | Hand off docs to Gemini |
| `skills/ship.md` | Checklist before you push |
| `scripts/usage.sh` | Detailed usage report for all three CLIs |
| `scripts/usage-statusline.sh` | Claude Code statusline — live usage at a glance |
| `scripts/lib-claude-window.sh` | Rolling 5h/7d window helper for Claude stats |
| `install.sh` | One-liner setup |

---

## Prerequisites

Before installing frugal-harness, make sure these four are set up:

### 1. Claude Code
```bash
npm install -g @anthropic-ai/claude-code
claude login
```
→ Requires **Claude Pro** ($20/mo) at minimum. [claude.ai/pricing](https://claude.ai/pricing)

### 2. Codex CLI
```bash
npm install -g @openai/codex
codex login
```
→ Requires **ChatGPT Plus** ($20/mo) at minimum. [openai.com/pricing](https://openai.com/pricing)

### 3. Gemini CLI

```bash
npm install -g @google/gemini-cli
```

Gemini CLI requires an API key. Add it to `~/.zshenv` so it works in all environments including Claude Code and scripts:

```bash
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshenv
```

Then open a new terminal and verify:

```bash
gemini -p "say hi"
```

Get a free key at: [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
(Free tier: 1,000 req/day — no credit card needed)

> **Why `~/.zshenv` and not `~/.zshrc`?** `.zshrc` only loads in interactive terminals. Claude Code and other non-interactive environments skip it, so your key won't be found. `.zshenv` loads everywhere.

### 4. jq
```bash
brew install jq
```
Used by the usage scripts to parse CLI session data.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

The installer also:
- Sets up the `usage` command for a combined usage report
- Configures the Claude Code statusline with live Claude / Codex / Gemini usage
- Pins Gemini's default model to `gemini-2.5-flash-lite` (cheapest)

Backs up any existing config before overwriting.

---

## Usage dashboard

Run `usage` anytime to see remaining quota across all three CLIs:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CLI USAGE  (2026-04-20 22:30)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Claude Code  (rolling window from project JSONL)
   Session 5h: ████████████████████  81% left  (375/475 msgs used)
   Weekly 7d:  ██████████████░░░░░░  86% left  (378/2700 msgs used)

Codex CLI  (Plus · gpt-5.4 · data from 2m ago)
   5h limit:   ████████████████████  99% left  (resets 02:56)
   Weekly:     ██████░░░░░░░░░░░░░░  28% left  (resets Apr 24)

Gemini CLI  (gemini-2.5-flash-lite)
   Today:      4 API calls — in 33k / out 1.4k
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Color coding: green ≥ 50% · yellow 20–50% · red < 20% remaining.

The Claude Code statusline shows the same data inline while you work.

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

Backs up your current config before removing it.

---

## How it works

Five stages. Run them in order, every time.

### 1. `/plan` → Claude Code (Opus)
Tell Claude what you want to build in plain English.
Opus breaks it down into a numbered task list and flags risks upfront.
> "I need a login page with OAuth and Supabase integration."

### 2. `/exec` → Codex CLI
Hand the plan to Codex and let it build task by task.
One task per commit. If scope changes mid-build, stop and re-run `/plan` first.

### 3. `/review` → Claude Code
Run this before every single commit. No exceptions.
Claude reads the diff and either says LGTM or gives you a list of issues to fix.

### 4. `/docs` → Gemini CLI (free)
All text-heavy work goes here — README, changelogs, inline comments, commit messages.
> "Read this diff and write a changelog entry in Korean and English."

### 5. `/ship` → Claude Code
Final checklist before push. All tasks done, no debug logs, clean branch, ready to PR.

---

### Slash commands or plain language — both work

The slash commands (`/plan`, `/exec`, etc.) are just shortcuts.
Under the hood, they load the matching file from `skills/` and pass it to the agent.
Typing `/plan` is exactly the same as saying:

> "I want to build X. Break it into tasks, flag the risks, give me a numbered list."

**Use whichever feels natural:**

| You prefer... | Just do this |
|---|---|
| Slash commands | `/plan`, `/exec`, `/review`, `/docs`, `/ship` |
| Plain language | Describe what you want — the agents figure out the rest |
| Mix | Use commands for routine stages, plain language when explaining new features |

The skill files in `skills/` are just saved prompts.
You can edit them, ignore them, or replace them entirely with your own words.

---

## Why frugal?

$100/mo plans are great. But not everyone needs them.

Claude Pro and ChatGPT Plus are $20/mo each.
Gemini CLI is free.
With the right workflow, $40/mo gets you surprisingly far.
frugal-harness is that workflow.
