[English](#english) | [한국어](#한국어)

---

<a name="english"></a>

# frugal-harness

**Plan with Opus. Build with Codex. Ship cheap.**

Most AI coding setups assume you're on a $100/mo plan.
This one doesn't.

frugal-harness is built for **Claude Pro ($20/mo)** and **ChatGPT Plus ($20/mo)** users
who want serious workflows without paying $100+ a month for it.

It takes the best ideas from two great projects —
**[gstack](https://github.com/garrytan/gstack)** by Garry Tan (YC CEO)
and **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** —
and strips them down to what actually matters.

---

## What's inside

| File | What it does | Borrowed from |
|---|---|---|
| `CLAUDE.md` | Global rules + skill loader | oh-my-claudecode |
| `skills/plan.md` | Think before you build | gstack Think/Plan |
| `skills/review.md` | Catch issues before committing | gstack Exec |
| `skills/ship.md` | Checklist before you push | — |
| `skills/status.md` | Statusline config | Claude Code docs |
| `install.sh` | One-liner setup | oh-my-claudecode |

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

---

## How to use

```
/plan → Opus thinks and writes a plan
/exec → Codex builds from the plan
/review → quick sanity check before commit
/ship → final checklist before push
```

---

## Why frugal?

$100/mo plans are great. But not everyone needs them.

Claude Pro and ChatGPT Plus are $20/mo each —
and with the right workflow, they get you surprisingly far.
frugal-harness is that workflow.

---

## Standing on the shoulders of

- **[gstack](https://github.com/garrytan/gstack)** — Think/Plan/Exec loop, keeping context tight
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — skills/ pattern, CLAUDE.md injection, install UX

---

[한국어로 읽기 ↓](#한국어)

---

<a name="한국어"></a>

# frugal-harness

**Opus로 계획하고, Codex로 만들고, 저렴하게 배포하세요.**

대부분의 AI 코딩 셋업은 $100짜리 요금제를 기준으로 만들어져 있습니다.
이건 아닙니다.

frugal-harness는 **Claude Pro ($20/월)** 와 **ChatGPT Plus ($20/월)** 를 쓰는 분들을 위해 만들었습니다.
$100 이상 내지 않아도 제대로 된 워크플로우를 쓸 수 있어야 하니까요.

YC CEO Garry Tan이 만든 **[gstack](https://github.com/garrytan/gstack)** 과
**[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** 에서
핵심만 가져와서, 진짜 필요한 것만 남겼습니다.

---

## 구성 파일

| 파일 | 역할 | 출처 |
|---|---|---|
| `CLAUDE.md` | 전역 규칙 + 스킬 로더 | oh-my-claudecode |
| `skills/plan.md` | 짜기 전에 생각하기 | gstack Think/Plan |
| `skills/review.md` | 커밋 전에 한 번 더 | gstack Exec |
| `skills/ship.md` | 푸시 전 체크리스트 | — |
| `skills/status.md` | Statusline 설정 | Claude Code 공식 문서 |
| `install.sh` | 원라이너 설치 | oh-my-claudecode |

---

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

---

## 사용법

```
/plan → Opus가 계획 먼저 작성
/exec → 계획 기반으로 Codex가 구현
/review → 커밋 전 빠른 점검
/ship → 푸시 전 최종 체크
```

---

## 왜 frugal인가요?

$100짜리 요금제가 나쁜 건 아닙니다. 근데 모두에게 필요한 건 아닙니다.

Claude Pro와 ChatGPT Plus는 각각 $20/월입니다.
워크플로우만 잘 짜면 이걸로 충분히 멀리 갈 수 있습니다.
frugal-harness가 그 워크플로우입니다.

---

## 여기서 많이 가져왔습니다

- **[gstack](https://github.com/garrytan/gstack)** — Think/Plan/Exec 루프, 컨텍스트 집중 유지
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — skills/ 패턴, CLAUDE.md 주입, install UX

---

[Read in English ↑](#english)
