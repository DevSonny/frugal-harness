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
| `install.sh` | One-liner setup |

---

## Prerequisites

Before installing frugal-harness, make sure these three are set up:

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

Gemini CLI requires an API key — `gemini login` (OAuth) doesn't work in non-interactive environments like scripts.

**Get a free API key:**
1. Go to [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Click **Create API key** (free, no credit card required)
3. Copy the key

The installer will prompt for your key (input is hidden) and automatically configure `~/.gemini/settings.json` to use API key auth.

If you prefer to set it manually:

```bash
# Add to ~/.zshrc or ~/.bashrc
export GEMINI_API_KEY="your-key-here"

# Restrict file permissions
chmod 600 ~/.zshrc

# Apply immediately
source ~/.zshrc
```

> **Security note:** The API key is stored in plaintext in your shell config. For stronger security, use macOS Keychain:
> ```bash
> # Store once
> security add-generic-password -a "$USER" -s GEMINI_API_KEY -w "your-key-here"
> # Add to ~/.zshrc to load on shell start
> export GEMINI_API_KEY=$(security find-generic-password -a "$USER" -s GEMINI_API_KEY -w)
> ```

**Verify it works:**
```bash
gemini -p "say hi"
```

→ Free tier: 1,000 req/day, 1M tokens/day. No paid plan needed.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

Backs up any existing config before overwriting.

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
