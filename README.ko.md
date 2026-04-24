[Read in English ->](./README.md)

# frugal-harness

<p align="center">
  <img src="https://github.com/DevSonny.png" width="120" />
  <br/>
  <strong>DevSonny</strong>
</p>

frugal-harness는 Claude Pro, ChatGPT Plus, Gemini CLI를 조합해 비용을 아끼면서도 실제 개발 흐름을 끝까지 처리하도록 만든 하네스입니다.

핵심은 역할 분리입니다.

- Claude Code는 계획하고 조율합니다.
- Codex CLI는 구현하고, 코드 리뷰하고, 커밋하고, 푸시합니다.
- Gemini CLI는 README, changelog, API 문서처럼 긴 문서를 씁니다.

보통은 Claude Code 하나만 열고 자연어로 말하면 됩니다. 뒤에서 필요한 CLI 호출은 하네스 규칙이 정합니다.

## 왜 이렇게 나누나요?

대부분의 AI 코딩 셋업은 $100/월 요금제를 전제로 합니다. frugal-harness는 **Claude Pro ($20/월)** 와 **ChatGPT Plus ($20/월)** 를 기본으로 두고, 문서 작업은 무료 Gemini CLI에 맡깁니다.

**합계: 월 $40** 기준으로도 충분히 멀리 가기 위한 구조입니다.

Claude는 planning과 오케스트레이션에 집중할 때 효율적입니다. Codex는 코드 구현, 코드 리뷰, 커밋 같은 실행 작업에 적합합니다. Gemini는 문서처럼 길고 반복적인 작업에 적합합니다.

이렇게 나누면 Claude 세션을 코드 편집에 태우지 않고, 각 도구의 쿼터를 역할에 맞게 쓸 수 있습니다.

## 역할 분담

| 도구 | 모델/설정 | 역할 |
|---|---|---|
| Claude Code | 기본 `sonnet`, 복잡한 plan만 Opus 권장 | 계획, 오케스트레이션 |
| Codex CLI | `gpt-5.5`, plan `high`, 구현 `medium` | 구현, 코드 리뷰, 커밋, 푸시 |
| Gemini CLI | `gemini-2.5-flash-lite`, 무료 1,000 req/일 | README, changelog, API 문서, 긴 글 |

Claude는 평상시 코드를 직접 편집하지 않습니다. 코드 구현과 코드 리뷰는 Codex가 맡습니다.

## 설치 전 준비

### 1. Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

최소 **Claude Pro ($20/월)** 를 기준으로 합니다.

### 2. Codex CLI

```bash
npm install -g @openai/codex
codex login
```

최소 **ChatGPT Plus ($20/월)** 를 기준으로 합니다.

### 3. Gemini CLI

```bash
npm install -g @google/gemini-cli
```

Gemini CLI는 API 키가 필요합니다.

```bash
export GEMINI_API_KEY="your-key-here"
gemini -p 'say hi'
```

무료 키는 <https://aistudio.google.com/apikey> 에서 받을 수 있습니다.

### 4. jq

`usage` 대시보드와 설치 스크립트가 JSON을 다루기 위해 `jq`를 사용합니다.

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/install.sh | bash
```

설치 스크립트는 다음을 설정합니다.

- Claude Code 기본 모델: `sonnet`
- Codex 기본 모델: `gpt-5.5`
- Codex reasoning: planning `high`, implementation `medium`
- Gemini 기본 모델: `gemini-2.5-flash-lite`
- `usage` 명령
- `~/.claude/commands` 아래 Claude Code slash command
- Claude Code statusline
- Claude의 소스 파일 직접 편집을 막는 PreToolUse guard
- Codex 단독 실행용 `~/.codex/AGENTS.md`

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

Claude가 요청을 보고 지금 필요한 단계가 planning인지, 구현인지, 리뷰인지, 문서 작업인지 판단합니다.

slash command는 선택 단축키입니다.

| 명령 | 의미 | 담당 |
|---|---|---|
| `/plan` | 작업을 나누고 리스크를 정리 | Claude |
| `/exec` | 구현 | Codex |
| `/review` | 코드 리뷰 | Codex |
| `/docs` | 문서 작성/수정 | Gemini (→ Codex 소진 시 → Claude 최후 수단) |
| `/ship` | 검증, 커밋, 푸시 | Codex |

자연어로 말해도 같은 라우팅을 따릅니다.

## Claude가 하지 않는 일

Claude는 평상시 코드를 직접 편집하지 않습니다.

- 코드 구현: Codex
- 코드 리뷰: Codex
- 커밋 메시지: Codex
- 커밋/푸시: Codex

Codex 쿼터가 떨어져 Claude가 구현 fallback을 해야 하는 경우에는 사용자가 명시적으로 승인해야 합니다. 이 경우에도 소스 편집 guard는 기본적으로 유지하고, 변경 범위는 좁고 검토 가능해야 합니다.

문서 작업은 Gemini가 1순위입니다. Gemini가 실패하거나 쿼터가 소진되면 Codex가 맡고, 마지막 fallback으로 Claude가 문서를 직접 편집할 수 있습니다.

## 모델 라우팅

기본 원칙은 싼 경로를 먼저 쓰고, planning 품질이 중요할 때만 올리는 것입니다.

- 일반 planning과 오케스트레이션: Claude Sonnet
- 복잡한 planning: Claude가 Opus 전환을 추천, 사용자가 승인하면 Opus 사용
- Codex standalone planning: `plan_mode_reasoning_effort = "high"`
- Codex 구현: `model_reasoning_effort = "medium"`
- Codex standalone plan이 너무 복잡하면 `xhigh` 재실행을 추천

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
| `skills/*.md` | 선택 slash command용 짧은 프롬프트 |
| `scripts/sync-agents.sh` | shared 원본으로 `~/.codex/AGENTS.md` 재생성 |

정책을 바꿀 때는 `~/.codex/AGENTS.md`를 직접 고치지 말고, `shared/harness-core.md` 또는 `shared/codex-wrapper.md`를 수정한 뒤 아래를 실행합니다.

```bash
scripts/sync-agents.sh
```

## 사용량 확인

```bash
usage
```

Claude Code 세션 안에서는 다음처럼 실행하면 shell 출력이 그대로 들어옵니다.

```bash
! usage
```

`usage`는 Claude, Codex, Gemini 사용량을 한 번에 보여줍니다.

## 언인스톨

```bash
curl -fsSL https://raw.githubusercontent.com/DevSonny/frugal-harness/main/uninstall.sh | bash
```

기존 설정은 제거 전에 백업됩니다.
