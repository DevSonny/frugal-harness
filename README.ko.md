[Read in English →](./README.md)

# frugal-harness

**Opus로 계획하고, Codex로 만들고, Gemini로 문서 쓰고, 저렴하게 배포하세요.**

대부분의 AI 코딩 셋업은 $100짜리 요금제를 기준으로 만들어져 있습니다.

frugal-harness는 **Claude Pro ($20/월)** 와 **ChatGPT Plus ($20/월)** 를 쓰는 분들을 위해 만들었습니다.
문서 작업은 Gemini CLI가 무료로 전담합니다.

**[gstack](https://github.com/garrytan/gstack)** 과
**[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** 에서
핵심만 가져와서, 진짜 필요한 것만 남겼습니다.

---

## 3-에이전트 구성

| 에이전트 | 요금제 | 모델 | 역할 |
|---|---|---|---|
| **Claude Code** | Claude Pro $20/월 | `claude-opus-4-7` | **계획 전용** — 아키텍처, 태스크 분해 |
| **Codex CLI** | ChatGPT Plus $20/월 | `gpt-5.4` | 구현, 리뷰, 커밋 & 푸시 |
| **Gemini CLI** | 무료 (1,000 req/일) | `gemini-2.5-flash-lite` | 문서 전담 — README, 변경 로그, 주석, 커밋 메시지 |

**합계: 월 $40** — $100짜리 요금제 필요 없습니다.
Fallback: Codex나 Gemini 할당량이 소진되면 Claude가 임시 대체합니다.

세 모델 모두 설치 시 자동 고정됩니다 — `/model` 수동 설정 불필요.

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
- Claude Code 모델을 `claude-opus-4-7`로 고정 — Opus, 계획 전용
- Codex 기본 모델을 `gpt-5.4`로 고정 — 최신 코딩 모델
- Gemini 기본 모델을 `gemini-2.5-flash-lite`로 고정 — 가장 저렴, 문서 전용
- `usage` 커맨드 설치 (세 CLI 통합 사용량 리포트)
- Claude Code 상태 표시줄에 실시간 사용량 설정

`/model` 수동 설정 불필요. 세 가지 모두 자동 구성됩니다.
기존 설정 파일이 있으면 덮어쓰기 전에 자동으로 백업합니다.

> **자동 고정이 적용되지 않은 경우 (기존 설정 파일 충돌, 설치 도중 실패 등) 아래처럼 직접 지정하세요.**
>
> - **Claude Code** — 세션 안에서: `/model claude-opus-4-7`
>   또는 `~/.claude/settings.json` 에 `"model": "claude-opus-4-7"` 을 추가·교체.
> - **Codex CLI** — `~/.codex/config.toml` 최상단에 `model = "gpt-5.4"` 추가·교체.
>   한 번만 쓰려면: `codex --model gpt-5.4 ...`
> - **Gemini CLI** — `~/.gemini/settings.json` 을 `{"model": {"name": "gemini-2.5-flash-lite"}}` 로 설정.
>   한 번만 쓰려면: `gemini --model gemini-2.5-flash-lite -p "..."`

---

## 사용량 대시보드

언제든 `usage`를 실행하면 세 CLI의 잔여 사용량을 한눈에 볼 수 있습니다.
Claude Code 세션 안에서 실행할 땐 `! usage` 처럼 `!` 를 붙여 주세요. `!` 를 붙이면 명령이 셸에서 바로 실행돼서 Claude 가 출력을 요약하거나 잘라내지 않고 전체 결과가 그대로 보입니다.

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

### 큰 그림

당신이 띄우는 CLI는 **Claude Code 하나뿐**입니다.

Claude가 `CLAUDE.md`의 규칙을 읽고, 지금 어느 단계인지 판단한 뒤, 필요할 때 Codex나 Gemini를 서브프로세스로 호출합니다 (`codex exec "..."`, `gemini -p "..."`). 모든 출력이 같은 세션으로 흘러 들어옵니다. 터미널 세 개 띄울 필요 없음.

멘탈 모델: **Claude는 지휘자, Codex와 Gemini는 연주자.** 당신은 지금 어느 단계인지만 신경 쓰면 됩니다 — 나머지 라우팅은 Claude가 처리합니다.

---

### 5단계 흐름

```
 /plan  ──▶  /exec  ──▶  /review  ──▶  /docs  ──▶  /ship
   │           │            │            │           │
 Claude      Codex        Codex        Gemini       Codex
 (Opus)    (GPT-5.4)    (GPT-5.4)      (무료)    (GPT-5.4)
   │           │            │            │           │
   계획         구현       셀프 리뷰     문서화      커밋+푸시
```

모든 기능은 이 5단계를 순서대로 통과합니다. 건너뛰기 없음.

---

### 1단계 — `/plan` → Claude (Opus)

**당신:** 만들고 싶은 걸 자연어로 설명합니다.
> "설정에 다크 모드 토글 추가. 세션 간 유지되고, 기본값은 시스템 환경 따라가게."

**Claude:** 번호 매긴 태스크 목록으로 쪼개고, 리스크와 불확실성을 미리 짚어줍니다.
> *Task 1: 설정 스키마에 `theme` 필드 추가*
> *Task 2: React Context로 `ThemeContext` 생성*
> *Task 3: 설정 페이지에 토글 UI 추가*
> *Task 4: `localStorage` 지속성 + `prefers-color-scheme` 폴백*
> *리스크: 기존 CSS에 hex 색상 하드코드 — 먼저 점검 필요.*

**결과:** 승인·수정·반려할 수 있는 정렬된 태스크 목록.

**왜 Claude인가:** Opus가 가장 강한 추론 모델입니다. 좋은 계획 하나가 나쁜 커밋 열 개를 막습니다 — 비싼 토큰은 여기서 뽑는 겁니다.

---

### 2단계 — `/exec` → Codex

**당신:** `/exec` (또는 "이제 만들자").

**Claude:** 백그라운드에서 `codex exec "Task 1 구현: <상세>"` 실행. Codex 출력이 당신의 세션으로 흘러옵니다.

**Codex:** 첫 번째 미완료 태스크를 구현, 테스트 돌리고, diff를 보여줍니다.

**규칙:** 한 번에 한 태스크만. 도중에 범위가 바뀌면 멈추고 `/plan`부터 다시.

**왜 Codex인가:** ChatGPT Plus는 Claude와 별개의 쿼터를 제공합니다. 무거운 코딩이 Claude 세션을 빨아먹지 않습니다.

---

### 3단계 — `/review` → Codex

**당신:** **모든** 커밋 전에 `/review`. 예외 없음.

**Codex 체크 항목:**
- 코드가 계획대로 됐는가?
- 명백한 버그나 놓친 엣지 케이스는?
- 설정으로 빼야 할 하드코딩 값은?
- diff가 최소한으로 깔끔한가?
- 테스트 통과하는가?

**결과:** `LGTM` 또는 구체적인 이슈 목록.

**주의:** Codex가 방금 자기가 쓴 코드를 리뷰하는 상황입니다. 중요도 높은 변경(인증, 마이그레이션, 보안)에는 Claude에게 독립적인 2차 리뷰를 요청하세요.

---

### 4단계 — `/docs` → Gemini

**당신:** `/docs update CHANGELOG`, `/docs 이 파일에 주석 추가` 등.

**Claude:** 백그라운드에서 `gemini -p "<요청>"` 실행.

**Gemini:** 관련 코드나 diff를 읽고 텍스트를 작성합니다 — README 업데이트, 변경 로그, 인라인 주석, 커밋 메시지.

**왜 Gemini인가:** 하루 1,000 요청 무료. 문서는 반복적이고 분량 많은 작업 — 여기서 Claude나 Codex 토큰 태우는 건 낭비입니다. Gemini의 1M 토큰 컨텍스트는 코드베이스를 통째로 먹어도 문제없습니다.

---

### 5단계 — `/ship` → Codex

**당신:** 푸시 준비 완료되면 `/ship`.

**일어나는 일:**
1. Codex가 ship 체크리스트 실행 (테스트 통과, 디버그 로그 없음, 브랜치 정리).
2. Gemini가 스테이징된 diff로 커밋 메시지 생성.
3. Codex가 `git add -A && git commit -m "<메시지>" && git push` 실행.

**결과:** `origin`에 깔끔한 커밋 푸시.

**왜 이렇게 나눴나:** Gemini는 글을 저렴하게 잘 쓰고, Codex는 이미 셸 접근과 테스트 실행 능력을 갖추고 있습니다. Claude는 이 단계에 끼지 않습니다.

---

### 실제 기능 하나 만드는 흐름

다크 모드 토글 추가한다고 치면:

1. **당신 → Claude:** *"설정에 다크 모드 토글 추가, 세션 간 유지."*
2. **Claude**가 4-태스크 계획 반환. 당신이 승인.
3. **당신:** `/exec`. Codex가 Task 1 구현, diff 보여줌. 다시 `/exec`. Task 2. 반복.
4. **당신:** `/review`. Codex가 이슈 하나 발견: `#fff` 하드코드. 당신이 수정.
5. **당신:** `/docs update CHANGELOG`. Gemini가 항목 작성.
6. **당신:** `/ship`. Codex 테스트 → Gemini 커밋 메시지 → Codex 푸시.
7. **Claude 쿼터 소비:** 약 2% (초기 계획 + 짧은 `/review` 응답 한 번).

터미널 전환 없음, 3개 CLI 저글링 없음. 한 대화 안에서 세 에이전트가 뒤에서 돌아갑니다.

---

### 슬래시 커맨드로 써도 되고, 자연어로 써도 됩니다

슬래시 커맨드는 그냥 단축키입니다. `skills/` 폴더의 매칭되는 파일을 불러와서 해당 에이전트에게 넘겨줍니다. `/plan` 치는 것과 이렇게 말하는 것은 완전히 동일:

> "X를 만들 건데, 태스크로 쪼개주고 리스크 짚어서 번호 목록으로 줘."

| 선호 방식 | 사용법 |
|---|---|
| 슬래시 커맨드 | `/plan`, `/exec`, `/review`, `/docs`, `/ship` |
| 자연어 | 원하는 걸 말하면 Claude가 단계 파악 |
| 혼합 | 반복 단계는 커맨드, 새 기능 설명할 땐 자연어 |

`skills/` 파일들은 저장된 프롬프트 모음입니다. 수정하든 삭제하든 본인 말투로 다시 쓰든 자유.

---

### Fallback — 에이전트 쿼터 소진 시

실제 한도:

- **Claude Pro:** 5시간 롤링 + 7일 주간
- **ChatGPT Plus (Codex):** 5시간 롤링 + 7일 주간
- **Gemini 무료:** 하루 1,000 요청

워크플로우 중간에 한도 도달하면:

1. `usage` 실행 → 누가 비었는지 확인.
2. 그 단계를 **임시로** Claude에 넘김 (Codex나 Gemini가 소진된 경우).
3. 쿼터가 리셋되자마자 원래 에이전트로 복구.

전환은 반드시 **수동으로만** 하세요. 자동 폴백을 만들어 두는 순간 frugal-harness 가 지향하는 비용 절감 원칙이 무너집니다.

---

## 왜 frugal인가요?

$100짜리 요금제가 나쁜 건 아닙니다. 근데 모두에게 필요한 건 아닙니다.

Claude Pro와 ChatGPT Plus는 각각 $20/월입니다.
Gemini CLI 는 하루 1,000회까지 무료로 쓸 수 있습니다.
워크플로우만 잘 짜면 월 $40으로 충분히 멀리 갈 수 있습니다.
frugal-harness가 그 워크플로우입니다.
