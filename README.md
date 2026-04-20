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
gemini login
```
→ Free tier is enough. No paid plan needed. [aistudio.google.com](https://aistudio.google.com)

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

---

## How to use

```
/plan    → Opus thinks and writes a plan
/exec    → Codex builds from the plan
/review  → sanity check before commit
/docs    → Gemini writes README, docs, changelogs
/ship    → final checklist before push
```

---

## Why frugal?

$100/mo plans are great. But not everyone needs them.

Claude Pro and ChatGPT Plus are $20/mo each.
Gemini CLI is free.
With the right workflow, $40/mo gets you surprisingly far.
frugal-harness is that workflow.
