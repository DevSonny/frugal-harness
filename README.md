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
| **Claude Code** (Opus) | Claude Pro $20/mo | **Planning only** — architecture & task breakdown |
| **Codex CLI** | ChatGPT Plus $20/mo | Build, review, commit & push |
| **Gemini CLI** | Free (1,000 req/day) | All docs — README, changelogs, comments, commit messages |

**Total: $40/mo.** No $100 plan needed.
Fallback: if Codex or Gemini hits its quota, Claude covers that role temporarily.

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

Gemini CLI requires an API key. Add it to your shell config:

<details><summary>zsh</summary>

```bash
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

</details>

<details><summary>bash (Linux)</summary>

```bash
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.bashrc
source ~/.bashrc
```

</details>

<details><summary>bash (macOS)</summary>

```bash
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.bash_profile
source ~/.bash_profile
```

</details>

<details><summary>fish</summary>

```fish
set -Ux GEMINI_API_KEY "your-key-here"
```

</details>

Open a new terminal, then verify:

```bash
[ -n "$GEMINI_API_KEY" ] && echo 'OK' || echo 'NOT SET'
echo "Key prefix: ${GEMINI_API_KEY:0:6}..."
gemini -p 'say hi'   # optional — 1 free-tier request
```

Get a free key at: [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
(Free tier: 1,000 req/day — no credit card needed)

### 4. jq
The installation command is automatically detected based on your OS:
```
macOS:  brew install jq
Ubuntu/Debian: sudo apt install jq
Fedora/RHEL: sudo dnf install jq
Arch: sudo pacman -S jq
```
(No need to check yourself during installation as it's auto-detected)
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

1. /plan → Claude Code (Opus) — Break it down, flag risks. Only Claude touches this step.
2. /exec → Codex CLI — Build task by task. One task per commit.
3. /review → Codex CLI — Self-review the diff. LGTM or a list of issues to fix.
4. /docs → Gemini CLI — README, changelogs, comments, commit messages. All text work, free.
5. /ship → Codex CLI — git add/commit/push. Commit message from Gemini, execution by Codex.

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
