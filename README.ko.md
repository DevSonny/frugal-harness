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
```

Gemini CLI는 API 키 방식으로 인증해야 합니다. `gemini login` (OAuth)은 스크립트처럼 비대화형 환경에서 동작하지 않습니다.

**무료 API 키 발급:**
1. [aistudio.google.com/apikey](https://aistudio.google.com/apikey) 접속
2. **Create API key** 클릭 (무료, 신용카드 불필요)
3. 키 복사

**쉘에 환경변수 설정:**
```bash
# ~/.zshrc 또는 ~/.bashrc에 추가
export GEMINI_API_KEY="your-key-here"

# 즉시 적용
source ~/.zshrc
```

**동작 확인:**
```bash
gemini -p "say hi"
```

→ 무료 티어: 1,000 req/일, 1M 토큰/일. 유료 요금제 불필요.

---

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

기존 설정 파일이 있으면 덮어쓰기 전에 자동으로 백업합니다.

---

## 언인스톨

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

기존 설정 파일을 백업한 뒤 삭제합니다.

---

## 사용 흐름

5단계입니다. 매번 순서대로 실행하면 됩니다.

### 1. `/plan` → Claude Code (Opus)
무엇을 만들지 자연어로 설명합니다.
Opus가 번호가 매겨진 태스크 목록으로 정리하고 리스크를 미리 짚어줍니다.
> "OAuth랑 Supabase 연동된 로그인 페이지 만들어야 해."

### 2. `/exec` → Codex CLI
계획서를 Codex에 넘겨서 태스크 하나씩 구현합니다.
빌드 중 범위가 바뀌면 멈추고 `/plan`부터 다시 시작합니다.

### 3. `/review` → Claude Code
커밋 전에 반드시 실행합니다. 예외 없습니다.
Claude가 diff를 읽고 LGTM이거나, 고쳐야 할 문제 목록을 알려줍니다.

### 4. `/docs` → Gemini CLI (무료)
텍스트가 많은 작업은 전부 여기서 합니다 — README, 변경 로그, 인라인 주석, 커밋 메시지.
> "이 diff 읽고 한국어랑 영어로 변경 로그 작성해줘."

### 5. `/ship` → Claude Code
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
