[Read in English ->](./README.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness는 계획, 구현, 리뷰, 커밋, 푸시까지 전체 개발 루프를 $100/월 없이도 돌릴 수 있도록 만든 저비용 AI 코딩 하네스입니다.

핵심은 **역할 분리**입니다:

- **Claude Code**는 계획하고 조율합니다.
- **구현 에이전트** (Codex CLI 또는 Antigravity CLI)가 구현, 리뷰, 커밋, 푸시를 맡습니다.

Claude Code 하나만 열고 자연어로 말하면 됩니다. 뒤에서 필요한 에이전트 호출은 하네스 규칙이 정합니다.

## 왜 이렇게 나누나요?

대부분의 AI 코딩 셋업은 $100/월 요금제를 전제로 합니다. frugal-harness는 저렴한 구독 조합으로 설계되었습니다:

| 구성 | 월 비용 |
|---|---|
| Claude Pro + Codex (ChatGPT Plus) | ~$40/월 |
| Claude Pro + agy | ~$20/월 + agy 구독 |
| Claude Pro + 둘 다 | ~$40/월 + agy 구독 |

Claude는 계획과 오케스트레이션에 집중할 때 가장 효율적입니다. 구현, 코드 리뷰, 커밋, 푸시는 구현 에이전트에게 위임합니다.

이렇게 나누면 Claude 세션을 코드 편집에 태우지 않고, 각 도구의 쿼터를 역할에 맞게 쓸 수 있습니다.

## 역할 분담

| 에이전트 | 역할 |
|---|---|
| Claude Code | 계획, 오케스트레이션 (기본 `sonnet`, 복잡한 plan만 Opus 권장) |
| Codex CLI | 구현, 코드 리뷰, 커밋, 푸시 (설치한 경우) |
| Antigravity CLI (agy) | 구현, 코드 리뷰, 커밋, 푸시, 문서 작업 (설치한 경우) |

Claude는 평상시 코드를 직접 편집하지 않습니다. 코드 구현과 코드 리뷰는 설치된 구현 에이전트가 맡습니다.

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
| Antigravity CLI | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |

설치 후 선택한 CLI에 로그인합니다:

```bash
claude login        # 항상 필요
codex login         # Codex 사용 시
agy login           # agy 사용 시
```

## 설치

installer가 어떤 구현 에이전트를 쓸지 물어봅니다:

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

`FRUGAL_AGENT`를 설정하면 프롬프트를 건너뜁니다:

```bash
# Codex만
FRUGAL_AGENT=1 bash install.sh

# agy만
FRUGAL_AGENT=2 bash install.sh

# 둘 다
FRUGAL_AGENT=3 bash install.sh
```

설치 스크립트는 다음을 설정합니다:

- 누락된 CLI를 공식 설치 경로로 자동 설치 (`FRUGAL_SKIP_CLI_INSTALL=1`로 건너뛰기 가능)
- Claude Code 기본 모델: `sonnet`
- Codex 기본 모델 및 reasoning effort (Codex 선택 시)
- 쿼터 모니터링용 `usage` 명령
- 남은 쿼터와 현재 세션 비용을 표시하는 Claude Code statusline
- Codex 단독 실행용 `~/.codex/AGENTS.md` (Codex 선택 시)
- agy 단독 실행용 `~/.gemini/config/AGENTS.md` (agy 선택 시)

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

Claude가 요청을 보고 지금 필요한 단계가 planning인지, 구현인지, 리뷰인지, 문서 작업인지 판단하여 적절한 에이전트에게 위임합니다.

## Claude가 하지 않는 일

Claude는 평상시 코드를 직접 편집하지 않습니다.

- 코드 구현 → 구현 에이전트
- 코드 리뷰 → 구현 에이전트
- 커밋 메시지 → 구현 에이전트
- 커밋/푸시 → 구현 에이전트

구현 에이전트 쿼터가 떨어져 Claude가 fallback을 해야 하는 경우, 사용자가 명시적으로 승인해야 합니다. 변경 범위는 좁고 검토 가능해야 합니다.

문서 작업은 agy가 1순위입니다 (설치된 경우). agy가 없으면 Codex가 맡고, 마지막 fallback으로 Claude가 문서를 직접 편집할 수 있습니다.

## 모델 라우팅

기본 원칙은 싼 경로를 먼저 쓰고, planning 품질이 중요할 때만 올리는 것입니다.

- 일반 planning과 오케스트레이션: Claude Sonnet
- 복잡한 planning: Claude가 Opus 전환을 추천, 사용자가 승인하면 Opus 사용

복잡한 planning으로 보는 기준:

- 10개 이상 파일이 바뀔 가능성
- 아키텍처, DB schema, API 설계 변경
- 여러 모듈 의존성 분석
- 큰 리팩터링
- "구조를 어떻게 바꾸는 게 좋은가" 같은 판단 중심 작업

### agy 모델 선택

Claude가 agy에게 위임할 때, 작업 복잡도에 따라 모델을 선택합니다:

| 작업 | 모델 |
|---|---|
| 빠른 구현 / 간단한 수정 | `Gemini 3.5 Flash (Medium)` |
| 복잡한 구현 | `Gemini 3.1 Pro (High)` 또는 `Claude Sonnet 4.6 (Thinking)` |
| 아키텍처 / 판단이 많은 작업 | `Claude Opus 4.6 (Thinking)` |
| 문서 / README | `Gemini 3.5 Flash (Low)` |
| 리뷰 | `Gemini 3.1 Pro (Low)` |

### Codex reasoning effort

Codex를 설치한 경우, 기본 reasoning은 planning과 구현 모두 `medium`입니다. 복잡한 standalone planning에는 `high` 또는 `xhigh` 재실행을 추천합니다.

## 품질 게이트

하네스는 특정 웹 스택만 가정하지 않습니다. 구현 에이전트는 프로젝트의 표준 검증 명령을 먼저 찾고, 생태계에 맞게 검증합니다.

먼저 확인하는 곳:

- README
- CI 설정
- Makefile, Justfile, Taskfile
- `package.json`
- `pyproject.toml`, `tox.ini`, `noxfile.py`
- `Cargo.toml`
- `go.mod`
- `pom.xml`, `build.gradle`

코드 변경에는 가능한 범위에서 다음 계층을 확인합니다:

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

생성된 AGENTS.md 파일은 자동 생성 파일입니다. 직접 수정하지 않습니다.

| 생성 파일 | 에이전트 |
|---|---|
| `~/.codex/AGENTS.md` | Codex 단독 실행용 |
| `~/.gemini/config/AGENTS.md` | agy 단독 실행용 |

원본 구조:

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | Claude 역할과 위임 규칙 |
| `shared/harness-core.md` | 모든 에이전트가 공유하는 공통 정책 |
| `shared/codex-wrapper.md` | Codex 전용 standalone/relay 규칙 |
| `shared/agy-wrapper.md` | agy 전용 standalone/relay 규칙 |
| `scripts/sync-agents.sh` | shared 원본으로 AGENTS.md 재생성 |

정책을 바꿀 때는 shared 원본 파일을 수정한 뒤 아래를 실행합니다:

```bash
scripts/sync-agents.sh
```

## 사용량 확인

```bash
usage
```

Claude Code 세션 안에서는 다음처럼 실행합니다:

```bash
! usage
```

`usage`는 Claude와 구현 에이전트 사용량을 한 번에 보여줍니다.

대시보드는 Node.js로 동작하며 `jq`가 필요 없습니다. Codex 사용량은 최신 파일 timestamp가 아니라 모든 로컬 rollout 로그의 최신 `token_count` 이벤트를 기준으로 선택합니다.

## 언인스톨

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

기존 설정은 제거 전에 백업됩니다.
