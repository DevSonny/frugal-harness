[한국어로 읽기 →](./README.ko.md)

# frugal-harness

<p align="center">
  <strong>DevSonny</strong> — A developer who loves FC Seoul ⚽
</p>

**Plan with Opus. Build with Codex. Document with Gemini. Ship cheap.**

Most AI coding setups assume you're on a $100/mo plan.
This one doesn't.

frugal-harness is built for **Claude Pro ($20/mo)** and **ChatGPT Plus ($20/mo)** users
who want a real multi-agent workflow — without the $100+ price tag.
Gemini CLI handles all the documentation for free.

It takes the best ideas from two great projects —
**[gstack](https://github.com/garrytan/gstack)**
and **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** —
and strips them down to what actually matters.

---

## The three-agent lineup

| Agent | Plan | Model | Role |
|---|---|---|---|
| **Claude Code** | Claude Pro $20/mo | `claude-opus-4-7` | **Planning only** — architecture & task breakdown |
| **Codex CLI** | ChatGPT Plus $20/mo | `gpt-5.4` | Build, review, commit & push |
| **Gemini CLI** | Free (1,000 req/day) | `gemini-2.5-flash-lite` | All docs — README, changelogs, comments, commit messages |

**Total: $40/mo.** No $100 plan needed.
Fallback: if Codex or Gemini hits its quota, Claude covers that role temporarily.

All three models are pinned automatically at install time — no manual `/model` setup needed.

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
- Pins Claude Code model to `claude-opus-4-7` — Opus, for planning
- Pins Codex default model to `gpt-5.4` — latest coding model
- Pins Gemini default model to `gemini-2.5-flash-lite` — cheapest, for docs
- Sets up the `usage` command for a combined usage report
- Configures the Claude Code statusline with live Claude / Codex / Gemini usage

No `/model` commands needed. All three are configured automatically.
Backs up any existing config before overwriting.

> **If auto-pinning didn't apply (e.g. a pre-existing config, or the installer failed partway), set the models manually:**
>
> - **Claude Code** — in a session: `/model claude-opus-4-7`
>   Or edit `~/.claude/settings.json` and add/replace `"model": "claude-opus-4-7"`.
> - **Codex CLI** — edit `~/.codex/config.toml` and put `model = "gpt-5.4"` at the top.
>   Per-run: `codex --model gpt-5.4 ...`
> - **Gemini CLI** — edit `~/.gemini/settings.json` to contain `{"model": {"name": "gemini-2.5-flash-lite"}}`.
>   Per-run: `gemini --model gemini-2.5-flash-lite -p "..."`

---

## Usage dashboard

Run `usage` anytime to see remaining quota across all three CLIs.
Inside a Claude Code session, prefix it with `!` (e.g. `! usage`) — the `!` runs the command directly in your shell so the full output lands in the conversation without Claude truncating it.

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

### The big picture

You only ever talk to **one CLI: Claude Code.**

Claude reads the rules in `CLAUDE.md`, figures out which stage you're in, and silently calls Codex or Gemini as sub-processes (`codex exec "..."` and `gemini -p "..."`) when it's their turn. Output streams back to the same session. No juggling three terminals.

Mental model: **Claude is the conductor. Codex and Gemini are the players.** You only care which stage you're in — Claude handles the hand-offs.

---

### The 5-stage flow

```
 /plan  ──▶  /exec  ──▶  /review  ──▶  /docs  ──▶  /ship
   │           │            │            │           │
 Claude      Codex        Codex        Gemini       Codex
 (Opus)    (GPT-5.4)    (GPT-5.4)      (free)     (GPT-5.4)
   │           │            │            │           │
  think       build    sanity-check     docs     commit+push
```

Every feature walks all 5 stages in order. No skipping.

---

### Stage 1 — `/plan` → Claude (Opus)

**You:** describe the feature in plain English.
> "Add a dark mode toggle to settings. Persist across sessions. Default to system preference."

**Claude:** breaks it into a numbered task list, flags risks, and calls out unknowns upfront.
> *Task 1: Add `theme` field to settings schema*
> *Task 2: Create `ThemeContext` with React Context*
> *Task 3: Toggle UI on settings page*
> *Task 4: `localStorage` persistence + `prefers-color-scheme` fallback*
> *Risk: existing CSS uses hard-coded hex values — audit first.*

**Output:** an ordered task list you can approve, edit, or reject.

**Why Claude here:** Opus is the strongest reasoner available. One good plan prevents ten bad commits — this is where the expensive token pays off.

---

### Stage 2 — `/exec` → Codex

**You:** `/exec` (or "let's start building").

**Claude:** runs `codex exec "Implement task 1: <details>"` in the background. Codex's output streams back to your session.

**Codex:** picks the first unchecked task, implements it, runs tests, shows you the diff.

**Rule:** one task at a time. If scope creeps mid-build, stop and re-run `/plan`.

**Why Codex here:** ChatGPT Plus has its own quota, separate from Claude. Heavy coding doesn't drain your Claude session.

---

### Stage 3 — `/review` → Codex

**You:** `/review` before **every** commit. No exceptions.

**Codex checks:**
- Does the code match the plan?
- Any obvious bugs or missed edge cases?
- Hardcoded values that should be config?
- Is the diff minimal and clean?
- Are tests passing?

**Output:** either `LGTM` or a concrete list of issues.

**Caveat:** Codex is reviewing code it just wrote. For high-stakes changes (auth, migrations, security), ask Claude for a second independent pass.

---

### Stage 4 — `/docs` → Gemini

**You:** `/docs update CHANGELOG` / `/docs add comments to this file` / etc.

**Claude:** runs `gemini -p "<your request>"` in the background.

**Gemini:** reads the relevant code or diff and writes prose — README updates, changelog entries, inline comments, commit messages.

**Why Gemini here:** 1,000 free requests/day. Docs are repetitive and high-volume — burning Claude or Codex tokens here is wasteful. Gemini's 1M-token context also eats whole codebases without flinching.

---

### Stage 5 — `/ship` → Codex

**You:** `/ship` when you're ready.

**What happens:**
1. Codex runs the ship checklist (tests pass, no debug logs, clean branch).
2. Gemini writes the commit message from the staged diff.
3. Codex runs `git add -A && git commit -m "<message>" && git push`.

**Output:** a clean commit pushed to `origin`.

**Why the split:** Gemini writes prose well and cheaply; Codex already has shell access and test-running muscle. Claude doesn't touch this stage.

---

### End-to-end: what a real feature looks like

Say you're building a dark-mode toggle:

1. **You → Claude:** *"Add a dark mode toggle to settings, persist across sessions."*
2. **Claude** returns a 4-task plan. You approve.
3. **You:** `/exec`. Codex builds Task 1, shows the diff. `/exec` again. Task 2. And so on.
4. **You:** `/review`. Codex flags one issue: hard-coded `#fff` color. You fix it.
5. **You:** `/docs update CHANGELOG`. Gemini writes the entry.
6. **You:** `/ship`. Codex runs tests, Gemini writes the commit message, Codex pushes.
7. **Claude quota spent:** ~2% (just the initial plan and a brief `/review` reply).

No terminal-switching. No manual CLI juggling. One conversation, three agents behind it.

---

### Slash commands or plain language — both work

Slash commands are just shortcuts. They load the matching file from `skills/` and hand it to the right agent. Typing `/plan` is literally the same as saying:

> "I want to build X. Break it into tasks, flag the risks, give me a numbered list."

| You prefer... | Just do this |
|---|---|
| Slash commands | `/plan`, `/exec`, `/review`, `/docs`, `/ship` |
| Plain language | Describe what you want — Claude figures out the stage |
| Mix | Commands for routine steps, plain language for new features |

The files in `skills/` are saved prompts. Edit them, delete them, or rewrite them in your own voice.

---

### Fallback — when an agent runs out of quota

The real limits:

- **Claude Pro:** 5h rolling session + 7-day weekly
- **ChatGPT Plus (Codex):** 5h rolling + 7-day weekly
- **Gemini free tier:** 1,000 requests/day

If an agent hits its cap mid-workflow:

1. Run `usage` — see who's empty.
2. **Temporarily** route that stage to Claude (if Codex or Gemini is out).
3. Revert as soon as the quota resets.

Manual override only. Don't automate it — that defeats the whole cost-discipline point of frugal-harness.

---

## Why frugal?

$100/mo plans are great. But not everyone needs them.

Claude Pro and ChatGPT Plus are $20/mo each.
Gemini CLI is free up to 1,000 requests/day.
With the right workflow, $40/mo gets you surprisingly far.
frugal-harness is that workflow.
