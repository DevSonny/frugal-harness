[English](#english) | [한국어](#한국어)

---

<a name="english"></a>

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

---

[한국어로 읽기 ↓](#한국어)

---

<a name="한국어"></a>

# frugal-harness

**Opus로 계획하고, Codex로 만들고, Gemini로 문서 쓰고, 저렴하게 배포하세요.**

대부분의 AI 코딩 셋업은 $100짜리 요금제를 기준으로 만들어져 있습니다.
이건 아닙니다.

frugal-harness는 **Claude Pro ($20/월)** 와 **ChatGPT Plus ($20/월)** 를 쓰는 분들을 위해 만들었습니다.
문서 작업은 Gemini CLI가 무료로 전담합니다.

YC CEO Garry Tan이 만든 **[gstack](https://github.com/garrytan/gstack)** 과
**[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** 에서
핵심만 가져와서, 진짜 필요한 것만 남겼습니다.

---

## 3-에이전트 구성

| 에이전트 | 요금제 | 역할 |
|---|---|---|
| **Claude Code** (Opus) | Claude Pro $20/월 | 계획, 아키텍처, 리뷰 |
| **Codex CLI** | ChatGPT Plus $20/월 | 구현, 코딩 |
| **Gemini CLI** | 무료 (1,000 req/일) | 문서, README, 변경 로그, 주석 |

**합계: 월 $40** — $100짜리 요금제 필요 없습니다.

---

## 구성 파일

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | 전역 규칙 + 스킬 로더 |
| `skills/plan.md` | 짜기 전에 생각하기 |
| `skills/exec.md` | 계획 기반으로 구현 |
| `skills/review.md` | 커밋 전에 한 번 더 |
| `skills/docs.md` | 문서는 Gemini에게 넘기기 |
| `skills/ship.md` | 푸시 전 체크리스트 |
| `install.sh` | 원라이너 설치 |

---

## 사전 준비

frugal-harness를 설치하기 전에 아래 세 가지를 먼저 세팅해야 합니다.

### 1. Claude Code
```bash
npm install -g @anthropic-ai/claude-code
claude login
```
→ 최소 **Claude Pro** ($20/월) 필요합니다. [claude.ai/pricing](https://claude.ai/pricing)

### 2. Codex CLI
```bash
npm install -g @openai/codex
codex login
```
→ 최소 **ChatGPT Plus** ($20/월) 필요합니다. [openai.com/pricing](https://openai.com/pricing)

### 3. Gemini CLI
```bash
npm install -g @google/gemini-cli
gemini login
```
→ 무료 티어로 충분합니다. 유료 요금제 불필요. [aistudio.google.com](https://aistudio.google.com)

---

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

---

## 사용법

```
/plan    → Claude Opus가 계획 작성
/exec    → 계획 기반으로 Codex가 구현
/review  → 커밋 전 빠른 점검
/docs    → Gemini가 README, 문서, 변경 로그 작성
/ship    → 푸시 전 최종 체크
```

---

## 왜 frugal인가요?

$100짜리 요금제가 나쁜 건 아닙니다. 근데 모두에게 필요한 건 아닙니다.

Claude Pro와 ChatGPT Plus는 각각 $20/월입니다.
Gemini CLI는 무료입니다.
워크플로우만 잘 짜면 월 $40으로 충분히 멀리 갈 수 있습니다.
frugal-harness가 그 워크플로우입니다.

---

[Read in English ↑](#english)
