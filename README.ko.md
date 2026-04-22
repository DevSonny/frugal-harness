[Read in English →](./README.md)

# frugal-harness

**Opus로 계획하고, Codex로 만들고, Gemini로 문서 쓰고, 저렴하게 배포하세요.**

대부분의 AI 코딩 셋업은 $100짜리 요금제를 기준으로 만들어져 있습니다.

frugal-harness는 **Claude Pro ($20/월)** 와 **ChatGPT Plus ($20/월)** 를 쓰는 분들을 위해 만들었습니다.
문서 작업은 Gemini CLI가 무료로 전담합니다.

YC CEO Garry Tan이 만든 **[gstack](https://github.com/garrytan/gstack)** 과
**[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** 에서
핵심만 가져와서, 진짜 필요한 것만 남겼습니다.

---

## 3-에이전트 구성

| 에이전트 | 요금제 | 역할 |
|---|---|---|
| **Claude Code** (Opus) | Claude Pro $20/월 | **계획 전용** — 아키텍처, 태스크 분해 |
| **Codex CLI** | ChatGPT Plus $20/월 | 구현, 리뷰, 커밋 & 푸시 |
| **Gemini CLI** | 무료 (1,000 req/일) | 문서 전담 — README, 변경 로그, 주석, 커밋 메시지 |

**합계: 월 $40** — $100짜리 요금제 필요 없습니다.
Fallback: Codex나 Gemini 할당량이 소진되면 Claude가 임시 대체합니다.

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
| `scripts/usage.sh` | 세 CLI 사용량 통합 리포트 |
| `scripts/usage-statusline.sh` | Claude Code 상태 표시줄 — 실시간 사용량 |
| `scripts/lib-claude-window.sh` | Claude 5h/7d 롤링 윈도우 계산 헬퍼 |
| `install.sh` | 원라이너 설치 |

---

## 사전 준비

frugal-harness를 설치하기 전에 아래 네 가지를 먼저 세팅해야 합니다.

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
```

Gemini CLI는 API 키가 필요합니다. 셸 설정 파일에 추가하세요:

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

새 터미널을 열고 확인:

```bash
[ -n "$GEMINI_API_KEY" ] && echo 'OK' || echo 'NOT SET'
echo "Key prefix: ${GEMINI_API_KEY:0:6}..."
gemini -p 'say hi'   # optional — 1 free-tier request
```

무료 키 발급: [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
(무료 티어: 1,000 req/일 — 신용카드 불필요)

### 4. jq
OS에 따라 자동으로 감지되어 설치됩니다.
macOS:  `brew install jq`
Ubuntu/Debian: `sudo apt install jq`
Fedora/RHEL: `sudo dnf install jq`
Arch: `sudo pacman -S jq`
사용량 스크립트에서 CLI 세션 데이터 파싱에 사용됩니다.

---

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

설치 시 자동으로:
- `usage` 커맨드 설치 (세 CLI 통합 사용량 리포트)
- Claude Code 상태 표시줄에 실시간 사용량 설정
- Gemini 기본 모델을 `gemini-2.5-flash-lite` (가장 저렴)으로 고정

기존 설정 파일이 있으면 덮어쓰기 전에 자동으로 백업합니다.

---

## 사용량 대시보드

언제든 `usage`를 실행하면 세 CLI의 잔여 사용량을 한눈에 볼 수 있습니다:

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

색상 기준: 초록 ≥ 50% · 노랑 20–50% · 빨강 < 20% 잔여.

Claude Code 상태 표시줄에도 동일한 데이터가 작업 중에 실시간으로 표시됩니다.

---

## 언인스톨

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

기존 설정 파일을 백업한 뒤 삭제합니다.

---

## 사용 흐름

5단계입니다. 매번 순서대로 실행하면 됩니다.

### 1. /plan → Claude Code (Opus) — 태스크 분해, 리스크 플래그. Claude만 이 단계를 담당합니다.
무엇을 만들지 자연어로 설명합니다. Opus가 번호가 매겨진 태스크 목록으로 정리하고 리스크를 미리 짚어줍니다.
> "OAuth랑 Supabase 연동된 로그인 페이지 만들어야 해."

### 2. /exec → Codex CLI — 태스크 단위로 구현합니다. 태스크 하나당 커밋 하나.
계획서를 Codex에 넘겨서 태스크 하나씩 구현합니다. 빌드 중 범위가 바뀌면 멈추고 `/plan`부터 다시 시작합니다.

### 3. /review → Codex CLI — diff 셀프 리뷰. LGTM이거나 수정 목록을 돌려줍니다.
커밋 전에 반드시 실행합니다. 예외 없습니다. Codex가 diff를 읽고 LGTM이거나, 고쳐야 할 문제 목록을 알려줍니다.

### 4. /docs → Gemini CLI — README, 변경 로그, 주석, 커밋 메시지. 텍스트 작업 전부, 무료.
텍스트가 많은 작업은 전부 여기서 합니다 — README, 변경 로그, 인라인 주석, 커밋 메시지.
> "이 diff 읽고 한국어랑 영어로 변경 로그 작성해줘."

### 5. /ship → Codex CLI — git add/commit/push. 커밋 메시지는 Gemini가 생성, 실행은 Codex가 담당.
푸시 전 최종 체크리스트입니다. 모든 태스크 완료, 디버그 로그 없음, 브랜치 정리, PR 준비 확인합니다.

---

### 슬래시 커맨드로 써도 되고, 자연어로 써도 됩니다

`/plan`, `/exec` 같은 슬래시 커맨드는 그냥 단축키입니다.
내부적으로는 `skills/` 폴더의 파일을 불러와서 에이전트에게 전달하는 것뿐입니다.
`/plan`을 치는 것과 이렇게 말하는 것은 완전히 동일합니다:

> "X를 만들 건데, 태스크로 쪼개주고 리스크 짚어서 번호 목록으로 줘."

**편한 방식으로 쓰면 됩니다:**

| 선호 방식 | 사용법 |
|---|---|
| 슬래시 커맨드 | `/plan`, `/exec`, `/review`, `/docs`, `/ship` |
| 자연어 | 원하는 걸 말하면 에이전트가 알아서 처리 |
| 혼합 | 반복 단계는 커맨드, 새 기능 설명할 때는 자연어 |

`skills/` 파일들은 결국 저장된 프롬프트 모음입니다.
수정해도 되고, 무시해도 되고, 본인 말로 완전히 대체해도 됩니다.

---

## 왜 frugal인가요?

$100짜리 요금제가 나쁜 건 아닙니다. 근데 모두에게 필요한 건 아닙니다.

Claude Pro와 ChatGPT Plus는 각각 $20/월입니다.
Gemini CLI는 무료입니다.
워크플로우만 잘 짜면 월 $40으로 충분히 멀리 갈 수 있습니다.
frugal-harness가 그 워크플로우입니다.
