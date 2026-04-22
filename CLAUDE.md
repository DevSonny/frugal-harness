# frugal-harness

## Agent roles
| Agent | Plan | Role |
|---|---|---|
| **Claude Code** (Opus) | Claude Pro $20/mo | **Planning only** — /plan |
| **Codex CLI** | ChatGPT Plus $20/mo | /exec (build) + /review + /ship (commit & push) |
| **Gemini CLI** | Free (1,000 req/day) | /docs — README, changelogs, comments, commit messages |

## Skills
@skills/plan.md
@skills/exec.md
@skills/review.md
@skills/docs.md
@skills/ship.md

## Rules
- Always run /plan before /exec
- Never skip /review before commit
- Delegate all documentation tasks to /docs (Gemini CLI)
- Keep context tight — close tasks before opening new ones
- Prefer small, focused commits

---

## 역할 분리 (핵심)
- 계획/설계/아키텍처: 네가 직접 처리 (Opus 전용 — 토큰 비싸니까 이것만)
- 구현/코딩/버그 수정: Bash로 codex exec "[내용]" 실행해서 Codex에 위임
- 리뷰/커밋/푸시: codex exec으로 Codex에 위임 (/review, /ship 모두)
- 문서, README, 변경 로그, 주석, 커밋 메시지: Gemini CLI에 위임
- 절대 네가 직접 코드 구현하거나 리뷰하거나 커밋하지 마 — Claude는 계획 전용
- codex exec 실행 시 반드시 파일 경로, 기술 스택, 완료 기준을 함께 전달해
- 계획 단계에서 코드 쓰지 마 — 계획 확정 후 codex exec으로만 구현해

## 워크플로우 순서
새 기능은 반드시 이 순서로: /plan(Claude) → /exec(Codex) → /review(Codex) → /docs(Gemini) → /ship(Codex)

## 메모리 (항상)
- 작업 시작 전 .notes/memory.md 가 있으면 반드시 먼저 읽어
- 작업 완료 후 주요 결정, 에러, 해결 방법을 .notes/memory.md 에 기록해

## 포기 금지
- 작업 중간에 나에게 묻지 마 — 3번 시도 후 실패했을 때만 예외
- Codex가 실패하면 다른 방식으로 다시 codex exec 실행해
- "완료"는 완료 체크리스트 전부 통과한 상태를 의미

## 시작 전 확인
- 목표가 불명확하면 코드 건드리기 전에 질문 하나만 해
- 새 기능 요청 시 엣지 케이스와 실패 케이스를 구현 전에 나에게 먼저 물어봐
- 3개 이상 파일 변경 시 계획 먼저 나에게 확인받아
- 필요 없는 파일 읽지 마 — 파일 구조부터 확인

## 토큰 절약
- 꼭 필요한 파일만 읽어 — 탐색용 읽기 금지
- 응답 짧게: 계획 설명만, 구현은 Codex에게
- 같은 세션에서 동일 파일 두 번 읽지 마
- 컨텍스트 60% 소진 시 /compact 실행 후 계속해

## 보안
- 환경변수, API 키는 항상 .env 사용, 코드에 직접 쓰지 마
- 새 API 엔드포인트 작성 시 반드시 입력값 검증과 인증 체크 포함해
- DB 쿼리는 항상 파라미터 바인딩 사용, 문자열 직접 연결 금지

## 코드 스타일 (Codex에 전달)
- TypeScript strict 모드 항상 유지
- any 타입 금지 — 근본 원인 수정
- 디버그 로그, 데드 코드 남기지 마

## Fallback 규칙
- Codex 또는 Gemini 할당량 소진 시에 한해 Claude가 해당 작업을 임시 대체
- usage 대시보드로 잔여량 확인 후 수동 판단 (자동 전환 아님)
- 소진 복구 후에는 반드시 원래 에이전트 역할로 복귀

## 완료 체크리스트 (모든 작업)
1. codex exec "npx playwright test && npx eslint . && tsc --noEmit"
2. codex exec "remove console.log and debug code"
3. gemini -p로 커밋 메시지 생성 후 codex exec으로 git add/commit/push 실행
4. .notes/memory.md 업데이트
