# frugal-harness 사용 가이드

## 구조 개요
- **Claude Code**: 플래너 및 오케스트레이터 역할을 수행합니다 (`CLAUDE.md` 참조).
- **agy**: 구현자 및 헬퍼 역할을 수행합니다 (프로젝트 루트의 `AGENTS.md` 또는 `~/.gemini/config/AGENTS.md` 참조).
- **Codex**: 선택적 헬퍼 역할을 수행합니다 (`~/.codex/AGENTS.md` 참조).
- 두 설정 파일(`CLAUDE.md`와 `AGENTS.md`)은 서로 `@` 참조를 하지 않으며, 각자 독립적인 시스템으로 동작합니다.

## 설정 파일 인클루드 구조

CLAUDE.md와 AGENTS.md는 같은 harness-core.md 내용을 공유하지만 방식이 다르다.

| 파일 | 인클루드 방식 | 시점 |
|------|--------------|------|
| CLAUDE.md | `@./shared/harness-core.md` (@ 참조) | 런타임 — Claude Code가 읽을 때 자동 반영 |
| AGENTS.md | 내용 직접 임베드 | 빌드타임 — sync-agents.sh 실행 시 복붙 |

**AGENTS.md에 @ 참조를 쓰지 않는 이유:**
agy는 @ 참조를 네이티브로 지원하지 않는다. 작동은 하지만, 매 세션마다 bash 툴 콜로 파일을 읽는 방식이라 오버헤드가 발생한다. 임베드 방식이 더 안정적이고 오프라인에서도 동작한다.

**따라서:**
- `harness-core.md` 수정 → CLAUDE.md: 즉시 자동 반영
- `harness-core.md` 수정 → AGENTS.md: `sync-agents.sh` 재실행 필요

```bash
bash ~/.claude/scripts/sync-agents.sh
```

## 워크플로우
Plan (Claude) → Implement (agy 또는 Codex) → Review (agy 또는 Codex) → Docs (설정된 에이전트) → Ship (agy 또는 Codex)

## agy 모델 라우팅

| 용도 | 모델 |
|------|------|
| 빠른 작업 | Gemini 3.5 Flash (Medium) |
| 기본 구현 | Gemini 3.1 Pro (Low) |
| 복잡한 구현 | Gemini 3.1 Pro (High) |
| 아키텍처/판단 | Claude Opus 4.6 (Thinking) |
| 코드 리뷰 | Gemini 3.1 Pro (Low) |
| 문서 | 설치 시 설정한 에이전트/모델 |
| **금지** | GPT-OSS 120B (Medium) |

## 설정 변경 방법
1. `frugal-config` 명령어 실행: 인터랙티브 메뉴를 통해 설정을 변경할 수 있습니다.
2. 자연어로 Claude에게 요청: '모델 바꿔줘', 'agy 모델 업데이트해줘' 등과 같이 요청하면, Claude가 `frugal-config`를 실행하고 `sync-agents.sh`를 통해 설정을 재생성합니다.

## Claude Code 플러그인
- **caveman**: 토큰을 압축하여 사용하는 커뮤니케이션 모드입니다. `/caveman` 명령어로 활성화할 수 있습니다.
- **superpowers**: brainstorming, writing-plans, code-review, verify 스킬을 포함합니다. (위임 대상이 아닙니다)

## 설정 파일 위치

| 파일 | 용도 |
|------|------|
| `~/.frugal-harness/config.sh` | 에이전트 선택, 모델 티어, 문서 에이전트 설정 |
| `~/.claude/CLAUDE.md` | Claude Code 오케스트레이터 규칙 |
| `~/.gemini/config/AGENTS.md` | agy 글로벌 규칙 (자동 생성됨, 직접 편집 금지) |
| `~/.codex/AGENTS.md` | Codex 규칙 (자동 생성됨, 직접 편집 금지) |

## 설정 재생성
agy 모델을 변경한 후에는 다음 명령어를 실행하여 에이전트를 동기화해야 합니다.
```bash
bash ~/.claude/scripts/sync-agents.sh
```
