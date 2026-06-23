[Read in English ->](./README.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness는 Claude Pro, ChatGPT Plus, Antigravity CLI를 조합해 비용을 아끼면서도 실제 개발 흐름을 끝까지 처리하도록 만든 하네스입니다.

핵심은 역할 분리입니다.

- Claude Code는 계획하고 조율합니다.
- 작업 에이전트(Codex CLI, Antigravity CLI)가 구현·리뷰·문서·커밋·푸시를 맡습니다.
- 각 역할을 어떤 에이전트가, 어떤 우선순위로 맡을지는 `frugal config`로 직접 정합니다.

보통은 Claude Code 하나만 열고 자연어로 말하면 됩니다. 뒤에서 어떤 에이전트가 각 단계를 맡을지는 여러분의 위임 프로파일에 따라 하네스 규칙이 정합니다.

## 왜 이렇게 나누나요?

대부분의 AI 코딩 셋업은 $100/월 요금제를 전제로 합니다. frugal-harness는 **Claude Pro ($20/월)** 와 **ChatGPT Plus ($20/월)** 를 기본으로 두고, 문서 작업은 Antigravity CLI에 맡깁니다.

**합계: 월 $40** 기준으로도 충분히 멀리 가기 위한 구조입니다.

Claude는 planning과 오케스트레이션에 집중할 때 효율적입니다. Codex는 코드 구현, 코드 리뷰, 커밋 같은 실행 작업에 적합합니다. Antigravity는 문서처럼 길고 반복적인 작업에 적합합니다.

이렇게 나누면 Claude 세션을 코드 편집에 태우지 않고, 각 도구의 쿼터를 역할에 맞게 쓸 수 있습니다.

## 역할 분담

| 도구 | 모델/설정 | 역할 |
|---|---|---|
| Claude Code | 기본 `sonnet`, 복잡한 plan만 Opus 권장 | 계획, 오케스트레이션 (항상 계획 담당) |
| Codex CLI | `gpt-5.5`, plan `medium`, 구현 `medium` | 작업자: 구현, 리뷰, 문서, 커밋, 푸시 |
| Antigravity CLI | 기본 `Claude Sonnet 4.6 (Thinking)`; 복잡한 작업은 `Claude Opus 4.6 (Thinking)`; Claude 쿼터 소진 시 `Gemini 3.1 Pro (High)` → `Gemini 3.5 Flash (Medium)` | 작업자: 구현, 리뷰, 문서, 긴 글 |

Claude는 항상 계획을 맡고 평상시 코드를 직접 편집하지 않습니다. 계획 외 모든 역할(구현·리뷰·문서·배포)은 작업 에이전트에 위임됩니다. 각 역할에서 어떤 작업자가 먼저 실행될지는 위임 프로파일(`frugal config`)이 정하며, 하네스는 우선순위 목록의 첫 에이전트를 시도하고 안 되면 다음으로 넘어갑니다.

## 설치 전 준비

### 1. Node.js와 npm

frugal-harness는 로컬 JSON/JSONL 사용량 파일을 `jq` 없이 파싱하기 위해 Node.js를 사용합니다. Codex와 Antigravity의 공식 설치 경로도 npm이나 curl 스크립트를 사용합니다.

Node.js가 없다면 먼저 설치하세요.

```bash
# macOS
brew install node

# Ubuntu/Debian/WSL
sudo apt install nodejs npm
```

### 2. Agent CLI

installer는 누락된 CLI를 공식 설치 경로로 자동 설치할 수 있습니다.

| CLI | frugal-harness가 사용하는 설치 경로 |
|---|---|
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Codex CLI | `npm install -g @openai/codex` |
| Antigravity CLI | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |

설치 후 로그인합니다.

```bash
claude login
codex login
```

Antigravity CLI는 구독 로그인이 필요합니다.

```bash
agy login
agy -p 'say hi'
```

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

설치 스크립트는 다음을 설정합니다.

- 누락된 Claude/Codex/Antigravity CLI를 공식 설치 경로로 자동 설치
- Claude Code 기본 모델: `sonnet`
- Codex 기본 모델: `gpt-5.5`
- Codex reasoning: planning `medium`, implementation `medium`
- Antigravity 기본 모델: `Claude Sonnet 4.6 (Thinking)`; 모델 폴백 체인 설정 완료 (Sonnet → Opus → Gemini Pro → Gemini Flash)
- `usage` 명령
- 에이전트 구독과 역할별 우선순위를 설정하는 `frugal` 명령
- 기본 위임 프로파일 `~/.config/frugal/profile.json` (구독 = 설치된 CLI, 우선순위: Antigravity → Codex, 배포는 Codex → Antigravity)
- `CLAUDE.md`가 import하는 렌더 결과 `~/.claude/shared/delegation-profile.md`
- 남은 쿼터와 현재 세션 비용을 표시하는 Claude Code statusline
- Claude의 소스 파일 직접 편집을 막아주는(가이드) PreToolUse guard
- Codex 단독 실행용 `~/.codex/AGENTS.md` (동일한 우선순위 포함)

설치되지 않은 작업 CLI는 그냥 건너뜁니다. CLI 자동 설치를 원하지 않으면 installer 실행 전에 `FRUGAL_SKIP_CLI_INSTALL=1`을 설정하세요.

installer는 비대화형이며 기본 프로파일을 적용합니다. 구독 에이전트나 역할별 우선순위를 바꾸려면 설치 후 `frugal config`를 실행하세요.

일반 작업에는 `/model` 수동 설정이 필요 없습니다. 복잡한 planning이 필요하면 Claude가 Opus 전환을 추천하고, 사용자가 승인한 경우에만 전환합니다.

## 기본 사용 방식

자연어가 기본입니다.

```text
"이 기능 계획 세워줘"
"이제 구현해줘"
"리뷰해줘"
"문서도 정리해줘"
"검증하고 커밋/푸시해줘"
```

Claude가 요청을 보고 지금 필요한 단계가 planning인지, 구현인지, 리뷰인지, 문서 작업인지 판단한 뒤, 계획 외 단계는 위임 프로파일에서 우선순위가 가장 높은 가용 작업자에게 넘깁니다.

slash command는 없습니다. 자연어가 유일한 인터페이스입니다.

## 에이전트 우선순위 설정

`frugal config`를 실행하면 구독할 작업 에이전트와 역할별 위임 우선순위를 정할 수 있습니다.

```bash
frugal config
```

설치된 CLI(`agy`, `codex`)를 감지해 구독 여부를 확인하고, `exec`·`review`·`docs`·`ship` 역할의 우선순위 순서를 묻습니다. 계획은 항상 Claude가 맡습니다. 답변은 `~/.config/frugal/profile.json`에 저장되고, `~/.claude/shared/delegation-profile.md`(`CLAUDE.md`가 import)와 `~/.codex/AGENTS.md`로 렌더링됩니다.

예시 프로파일 (Antigravity 우선, Codex 폴백):

```json
{
  "agents": ["antigravity", "codex"],
  "roles": {
    "plan":   ["claude"],
    "exec":   ["antigravity", "codex"],
    "review": ["antigravity", "codex"],
    "docs":   ["antigravity", "codex"],
    "ship":   ["codex", "antigravity"]
  },
  "routing": "complexity-auto"
}
```

## Claude가 하지 않는 일

Claude는 평상시 코드를 직접 편집하지 않습니다. 각 역할은 위임 프로파일의 우선순위에 따라 작업 에이전트에 넘어갑니다.

- 코드 구현: `exec` 1순위 작업자
- 코드 리뷰: `review` 1순위 작업자
- 문서: `docs` 1순위 작업자
- 커밋 메시지 / 커밋 / 푸시: `ship` 1순위 작업자 (Codex는 커밋 메시지를 직접 작성)

작업자가 쿼터를 소진하면 하네스는 해당 역할 목록의 다음 에이전트로 폴백합니다. 어떤 작업자도 실행할 수 없어 Claude가 구현 fallback을 해야 하는 경우에는 사용자가 명시적으로 승인해야 합니다. 이 경우에도 소스 편집 guard는 기본적으로 유지하고, 변경 범위는 좁고 검토 가능해야 합니다.

## 모델 라우팅

기본 원칙은 싼 경로를 먼저 쓰고, planning 품질이 중요할 때만 올리는 것입니다.

- 일반 planning과 오케스트레이션: Claude Sonnet
- 복잡한 planning: Claude가 Opus 전환을 추천, 사용자가 승인하면 Opus 사용
- Codex standalone planning: `plan_mode_reasoning_effort = "medium"`
- Codex 구현: `model_reasoning_effort = "medium"`
- Codex standalone plan이 복잡하면 `high` 재실행을 추천
- Codex standalone plan이 매우 복잡하면 `xhigh` 재실행을 추천
- Antigravity 일반 작업: `agy --model "Claude Sonnet 4.6 (Thinking)" -p "<task>"`
- Antigravity 복잡한 작업: `agy --model "Claude Opus 4.6 (Thinking)" -p "<task>"`
- Antigravity Claude 쿼터 소진 시: `Gemini 3.1 Pro (High)` → `Gemini 3.5 Flash (Medium)` 순서로 전환

복잡한 planning으로 보는 기준은 대략 다음과 같습니다.

- 10개 이상 파일이 바뀔 가능성
- 아키텍처, DB schema, API 설계 변경
- 여러 모듈 의존성 분석
- 큰 리팩터링
- “구조를 어떻게 바꾸는 게 좋은가” 같은 판단 중심 작업

## 품질 게이트

하네스는 특정 웹 스택만 가정하지 않습니다. Codex는 프로젝트의 표준 검증 명령을 먼저 찾고, 생태계에 맞게 검증합니다.

먼저 확인하는 곳:

- README
- CI 설정
- Makefile, Justfile, Taskfile
- `package.json`
- `pyproject.toml`, `tox.ini`, `noxfile.py`
- `Cargo.toml`
- `go.mod`
- `pom.xml`, `build.gradle`

코드 변경에는 가능한 범위에서 다음 계층을 확인합니다.

- build/compile
- tests
- static analysis/lint
- format check
- type/static correctness

예시:

| 생태계 | 대표 검증 |
|---|---|
| Node/TypeScript | `npm test`, `npm run lint`, `npm run build`, `tsc --noEmit` |
| Python | `pytest`, `ruff check`, `ruff format --check`, `mypy` 또는 `pyright` |
| Go | `go test ./...`, `go vet ./...`, `gofmt` |
| Rust | `cargo test`, `cargo check`, `cargo clippy` |

문서나 설정만 바뀐 경우에는 전체 테스트 대신 영향받는 검증만 실행합니다. 예를 들어 Markdown, JSON/YAML/TOML 파싱, shell syntax check, 생성 스크립트 검증 등이 해당됩니다.

검증 명령을 찾지 못하거나 실행할 수 없으면, 최종 보고에 무엇을 생략했고 왜 생략했는지 남깁니다.

## AGENTS.md 구조

`~/.codex/AGENTS.md`는 직접 수정하지 않습니다. 자동 생성 파일입니다.

원본 구조는 다음과 같습니다.

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | Claude 역할과 위임 규칙 |
| `shared/harness-core.md` | Claude와 Codex가 공유하는 공통 정책 |
| `shared/codex-wrapper.md` | Codex 전용 standalone/relay 규칙 |
| `~/.claude/shared/delegation-profile.md` | 렌더된 역할별 우선순위 (`frugal config`가 생성) |
| `scripts/render-profile.sh` | 프로파일 렌더 + 구독 에이전트 기본값 설정 |
| `scripts/sync-agents.sh` | shared 원본 + 프로파일로 `~/.codex/AGENTS.md` 재생성 |

정책을 바꿀 때는 `~/.codex/AGENTS.md`를 직접 고치지 말고, `shared/harness-core.md` 또는 `shared/codex-wrapper.md`를 수정한 뒤 아래를 실행합니다.

```bash
scripts/sync-agents.sh
```

어떤 에이전트가 어떤 역할을 맡을지 바꾸려면 `frugal config`를 실행하세요 (프로파일과 `AGENTS.md`를 다시 생성합니다).

## 사용량 확인

```bash
usage
```

Claude Code 세션 안에서는 다음처럼 실행하면 shell 출력이 그대로 들어옵니다.

```bash
! usage
```

`usage`는 Claude, Codex, Antigravity 사용량을 한 번에 보여줍니다.

대시보드는 Node.js로 동작하며 `jq`가 필요 없습니다. Codex 사용량은 최신 파일 timestamp가 아니라 모든 로컬 rollout 로그의 최신 `token_count` 이벤트를 기준으로 선택합니다.

## 언인스톨

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

기존 설정은 제거 전에 백업됩니다.
