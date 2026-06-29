[Read in English ->](./README.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness는 계획, 구현, 리뷰, 커밋, 푸시까지 전체 개발 루프를 $100/월 없이도 돌릴 수 있도록 만든 저비용 AI 코딩 하네스입니다.

핵심은 **역할 분리**입니다. 하지만, 어떤 에이전트를 **메인 핸들러**(직접 대화하는 에이전트)로 쓸지, 어떤 에이전트를 **헬퍼 에이전트**(작업을 위임받는 에이전트)로 쓸지 사용자가 직접 선택할 수 있습니다.

## 비용 조합

대부분의 AI 코딩 셋업은 $100/월 요금제를 전제로 합니다. 하지만 frugal-harness를 사용하면 원하는 조합으로 저렴하게 구성할 수 있습니다:

| 메인 핸들러 | 헬퍼 에이전트 | 월 비용 |
|---|---|---|
| Claude Code | + Codex | ~$40/월 (Claude Pro + ChatGPT Plus) |
| Claude Code | + agy | ~$40/월 (Claude Pro + agy) |
| Claude Code | + 둘 다 | ~$60/월 |
| agy | 없음 | ~$20/월 (agy) |
| agy | + Claude | ~$40/월 |
| Codex | 없음 | ~$20/월 (ChatGPT Plus) |
| Codex | + Claude | ~$40/월 |

### 다른 LLM API 연결 (DeepSeek, Qwen, Kimi 등)

Codex CLI는 OpenAI 호환 API endpoint를 지원합니다. DeepSeek, Qwen, Kimi 등 호환 API key가 있다면 ChatGPT Plus 구독 없이 사용할 수 있습니다:

```bash
export OPENAI_API_KEY=your-api-key
export OPENAI_BASE_URL=https://api.deepseek.com  # 또는 해당 provider endpoint
export OPENAI_MODEL=deepseek-chat                 # 또는 해당 provider 모델명
```

인스톨러 실행 전에 설정하거나, shell profile에 추가하세요. Claude Code와 agy는 각자 고유한 provider를 사용하므로 이 방법은 Codex CLI에만 해당합니다.

## 메인 핸들러별 동작 방식

어떤 에이전트를 메인 핸들러로 선택하느냐에 따라 하네스의 동작 방식이 달라집니다.

| 메인 핸들러 | 역할 | 위임 가능한 헬퍼 |
|---|---|---|
| **Claude Code** | 계획 및 오케스트레이션. 평상시 코드를 직접 편집하지 않으며 구현, 리뷰, 커밋, 푸시를 헬퍼에게 위임합니다. | agy, Codex |
| **agy** | End-to-end 에이전트. 계획부터 구현, 리뷰, 커밋, 푸시까지 직접 전부 처리합니다. | Claude, Codex |
| **Codex CLI** | End-to-end 에이전트. 계획부터 구현, 리뷰, 커밋, 푸시까지 직접 전부 처리합니다. | Claude, agy |

### 워크플로우

자연어가 기본 인터페이스입니다. 메인 핸들러가 요청을 받아 단계를 판단하고 진행합니다.

- **Claude Code가 메인일 때:** 계획과 판단은 Claude가, 구현·리뷰·커밋·푸시는 agy나 Codex에 위임합니다.
- **agy 또는 Codex가 메인일 때:** 계획부터 커밋·푸시까지 메인 핸들러가 직접 처리합니다. 헬퍼는 선택적 fallback입니다.

## 설치 전 준비

### 1. Node.js와 npm

frugal-harness는 로컬 JSON/JSONL 사용량 파일을 `jq` 없이 파싱하기 위해 Node.js를 사용합니다.

```bash
# macOS
brew install node

# Ubuntu/Debian/WSL
sudo apt install nodejs npm
```

### 2. Agent CLI

installer는 누락된 CLI를 공식 설치 경로로 자동 설치할 수 있습니다.

| CLI | 설치 경로 |
|---|---|
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Codex CLI | `npm install -g @openai/codex` |
| agy | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |

설치 후 선택한 CLI에 로그인합니다:

```bash
claude login        # Claude 사용 시
codex login         # Codex 사용 시
agy login           # agy 사용 시
```

## 설치

installer를 실행합니다:

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

대화형 프롬프트가 다음을 묻습니다:
1. **어떤 에이전트를 메인 핸들러로 쓰시겠습니까?** (Claude, agy, 또는 Codex)
2. **헬퍼 에이전트를 설치하시겠습니까?** (작업 위임/fallback용)
3. **CLAUDE.md를 설치하시겠습니까?** (Claude가 메인 핸들러가 아니더라도 가끔 열어볼 때를 대비해 룰을 설치할 수 있습니다)

### 비대화형(Non-interactive) 설치

환경변수를 설정하여 프롬프트를 건너뛸 수 있습니다:

```bash
# Claude 메인 + agy 헬퍼
FRUGAL_MAIN=claude FRUGAL_HELPERS=agy bash install.sh

# agy 메인, 헬퍼 없음
FRUGAL_MAIN=agy FRUGAL_HELPERS=none bash install.sh

# Codex 메인 + Claude 헬퍼
FRUGAL_MAIN=codex FRUGAL_HELPERS=claude bash install.sh
```

## 선택 스킬

설치 완료 후 인스톨러가 아래 스킬 설치 여부를 묻습니다:

| 스킬 | 지원 에이전트 | 추천 | 설명 |
|---|---|---|---|
| **caveman** | Claude Code, Codex, agy | ★ 강력 추천 | Claude 출력 토큰을 최대 75% 절감. 기술적 내용 그대로, 응답만 훨씬 짧아짐. |
| **superpowers** | Claude Code, agy | 추천 | 에이전트에 강력한 스킬과 추가 기능을 플러그인으로 설치. |

non-interactive 설치:

```bash
FRUGAL_INSTALL_CAVEMAN=1 FRUGAL_INSTALL_SUPERPOWERS=1 bash install.sh
```

개별 단독 설치:

**Claude Code용:**
```bash
claude plugin install caveman
claude plugin install superpowers@claude-plugins-official
```

**agy용:**
```bash
npx -y skills add JuliusBrussee/caveman -a antigravity --yes
agy plugin install https://github.com/obra/superpowers
# 참고: agy 플러그인은 워크스페이스가 아닌 ~/.gemini/config/plugins 에 전역 설치됩니다.
```

**Codex CLI용:**
```bash
npx -y skills add JuliusBrussee/caveman -a codex --yes
# superpowers는 Codex CLI 내에서 /plugins 명령어를 통해 수동 설치해야 합니다.
```

## 환경 설정 (설치 후)

나중에 메인 핸들러나 헬퍼를 변경하고 싶다면, 인스톨러를 다시 실행할 필요 없이 내장된 config 유틸리티를 사용하세요:

```bash
frugal-config                    # 대화형 메뉴
frugal-config --main agy         # 메인 핸들러 변경
frugal-config --helpers claude   # 헬퍼 변경
```

설정은 `~/.frugal-harness/config.sh`에 저장되며 룰 파일들이 자동으로 재생성됩니다.

## 모델 라우팅

기본 원칙은 싼 경로를 먼저 쓰고, planning 품질이 중요할 때만 올리는 것입니다.

- 일반 planning과 오케스트레이션: 기본 모델 (`sonnet`, `gpt-5.5`, 또는 `gemini-3.5-flash`)
- 복잡한 planning: 메인 핸들러가 고급 추론 모델로 전환할 것을 추천하고, 사용자가 승인하면 전환

복잡한 planning으로 보는 기준:
- 10개 이상 파일이 바뀔 가능성
- 아키텍처, DB schema, API 설계 변경
- 여러 모듈 의존성 분석
- 큰 리팩터링
- "구조를 어떻게 바꾸는 게 좋은가" 같은 판단 중심 작업

### agy 모델 선택

agy가 실행될 때(메인이든 헬퍼든), 작업 복잡도에 따라 모델을 선택합니다:

| 작업 | 모델 |
|---|---|
| 빠른 구현 / 간단한 수정 | `Gemini 3.5 Flash (Medium)` |
| 기본 구현 | `Gemini 3.1 Pro (Low)` |
| 복잡한 구현 | `Gemini 3.1 Pro (High)` 또는 `Claude Sonnet 4.6 (Thinking)` |
| 아키텍처 / 판단이 많은 작업 | `Claude Opus 4.6 (Thinking)` |
| 리뷰 | `Gemini 3.1 Pro (Low)` |
| 문서 / README | configurable (`FRUGAL_DOCS_AGY_MODEL`) |
| **금지** | `GPT-OSS 120B (Medium)` (오픈소스 모델 사용 불가) |

> **중요:** `--model` 값은 `agy models` 출력과 **정확히 일치**해야 함 (대소문자 구분, 괄호 포함). 약어나 오타(`"sonnet"`, `"opus"` 등) 입력 시 오류 없이 `Gemini 3.5 Flash (Medium)`으로 폴백됨. 정확한 이름은 `agy models`로 확인.

### Codex reasoning effort

Codex가 실행될 때, 기본 reasoning은 planning과 구현 모두 `medium`입니다. 복잡한 planning에는 `high` 또는 `xhigh` 재실행을 추천합니다.

## 품질 게이트

하네스는 특정 웹 스택만 가정하지 않습니다. 구현 에이전트는 프로젝트의 표준 검증 명령을 먼저 찾고, 생태계에 맞게 검증합니다.

먼저 확인하는 곳:
- README
- CI 설정
- Makefile, Justfile, Taskfile
- `package.json`
- `pyproject.toml`, `tox.ini`, `noxfile.py`
- `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`

코드 변경에는 가능한 범위에서 build/compile, tests, lint, format check, type check를 확인합니다.

문서나 설정만 바뀐 경우에는 전체 테스트 대신 영향받는 검증만 실행합니다. 검증 명령을 찾지 못하거나 실행할 수 없으면, 최종 보고에 무엇을 생략했고 왜 생략했는지, 어떤 수동 검토를 했는지 남깁니다.

## 룰(AGENTS.md) 구조

생성된 시스템 파일들은 가급적 직접 수정하지 않습니다.

| 파일 | 용도 |
|---|---|
| `~/.frugal-harness/config.sh` | 에이전트 선택, 모델 티어, 문서 에이전트 설정 |
| `~/.claude/CLAUDE.md` | Claude Code 규칙 |
| `~/.codex/AGENTS.md` | Codex 규칙 (config에 따라 메인 또는 헬퍼 내용이 들어감) |
| `~/.gemini/config/AGENTS.md` | agy 규칙 (config에 따라 메인 또는 헬퍼 내용이 들어감) |

- [CLAUDE.ko.md](./CLAUDE.ko.md) — CLAUDE.md 한국어 번역 참조본 (어떤 에이전트도 읽지 않음)

원본 구조:

| 파일 | 역할 |
|---|---|
| `shared/harness-core.md` | 모든 에이전트가 공유하는 공통 정책 |
| `shared/codex-wrapper-main.md` | Codex가 메인일 때의 규칙 |
| `shared/codex-wrapper-helper.md` | Codex가 헬퍼일 때의 규칙 |
| `shared/agy-wrapper-*.md` | agy 규칙 (메인/헬퍼) |

### 설정 파일 인클루드 구조

CLAUDE.md와 AGENTS.md는 같은 `harness-core.md` 내용을 공유하지만 방식이 다릅니다.

| 파일 | 인클루드 방식 | 시점 |
|------|--------------|------|
| CLAUDE.md | `@./shared/harness-core.md` (@ 참조) | 런타임 — Claude Code가 읽을 때 자동 반영 |
| AGENTS.md | 내용 직접 임베드 | 빌드타임 — 스크립트 실행 시 복붙 |

**AGENTS.md에 @ 참조를 쓰지 않는 이유:**
agy는 @ 참조를 네이티브로 지원하지 않습니다. bash 툴 콜로 파일을 읽는 방식이라 오버헤드가 발생하기 때문에, 임베드 방식이 더 안정적이고 오프라인에서도 동작합니다.

정책(`harness-core.md` 등)을 바꿀 때는 shared 원본 파일을 수정한 뒤 `frugal-config`를 실행하여 재생성하거나, 직접 동기화 스크립트를 실행해야 합니다:

```bash
bash ~/.claude/scripts/sync-agents.sh
```

## 사용량 확인

```bash
usage
```

Claude Code 세션 안에서는 다음처럼 실행합니다: `! usage`

`usage`는 Claude와 구현 에이전트 사용량을 한 번에 보여줍니다. 대시보드는 Node.js로 동작하며 `jq`가 필요 없습니다. Codex 사용량은 최신 파일 timestamp가 아니라 모든 로컬 rollout 로그의 최신 `token_count` 이벤트를 기준으로 선택합니다.

## 언인스톨

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

기존 설정은 제거 전에 백업됩니다.
