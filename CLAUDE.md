## 역할 분리 (핵심)
- 계획/설계/아키텍처: 네가 직접 처리 (opusplan이 자동으로 Opus 배정)
- 구현/코딩/버그 수정: Bash로 codex exec "[내용]" 실행해서 Codex에 위임
- 검증/테스트: Bash로 codex exec "run tests and verify [내용]" 실행
- 절대 네가 직접 코드 구현하지 마 — 구현과 검증은 항상 Codex 담당
- codex exec 실행 시 반드시 파일 경로, 기술 스택, 완료 기준을 함께 전달해
- 계획 단계에서 코드 쓰지 마 — 계획 확정 후 codex exec으로만 구현해

## 워크플로우 순서
새 기능은 반드시 이 순서로: /plan → Build → /review → /ship

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

## TDD 흐름 (새 기능 추가 시에만)
1. codex exec "write tests for [기능]"
2. codex exec "run tests, confirm they fail"
3. codex exec "implement [기능] to pass tests"
4. codex exec "run all tests, confirm all pass"

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

## 완료 체크리스트 (모든 작업)
1. codex exec "npx playwright test && npx eslint . && tsc --noEmit"
2. codex exec "remove console.log and debug code"
3. 구현 후 보안/성능/프로덕션 버그 관점에서 스스로 검토해
4. .notes/memory.md 업데이트

---

## Role Separation (Core)
- Planning/design/architecture: handle it yourself directly (`opusplan` automatically routes planning to Opus)
- Implementation/coding/bug fixes: delegate to Codex by running `codex exec "[details]"` in Bash
- Verification/testing: run `codex exec "run tests and verify [details]"` in Bash
- Never implement code directly yourself — implementation and verification always belong to Codex
- When running `codex exec`, always include file paths, tech stack, and done criteria
- Do not write code during the planning phase — only implement via `codex exec` after the plan is confirmed

## Workflow Order
New features must always follow this order: `/plan` → Build → `/review` → `/ship`

## Memory (Always)
- Before starting work, if `.notes/memory.md` exists, read it first
- After finishing work, record major decisions, errors, and solutions in `.notes/memory.md`

## Do Not Give Up
- Do not ask me in the middle of the task — the only exception is after 3 failed attempts
- If Codex fails, run `codex exec` again using a different approach
- "Done" means every item in the completion checklist has passed

## Checks Before Starting
- If the goal is unclear, ask only one question before touching code
- For a new feature request, ask me about edge cases and failure cases before implementation
- If 3 or more files will change, get plan confirmation from me first
- Do not read unnecessary files — inspect the file structure first

## TDD Flow (Only When Adding a New Feature)
1. `codex exec "write tests for [feature]"`
2. `codex exec "run tests, confirm they fail"`
3. `codex exec "implement [feature] to pass tests"`
4. `codex exec "run all tests, confirm all pass"`

## Token Saving
- Read only the files you absolutely need — no exploratory reading
- Keep responses short: explain the plan only, send implementation to Codex
- Do not read the same file twice in the same session
- When context usage reaches 60%, run `/compact` and continue

## Security
- Always use `.env` for environment variables and API keys; never hardcode them
- When creating a new API endpoint, always include input validation and auth checks
- Always use parameter binding for DB queries; never concatenate strings directly

## Code Style (Pass to Codex)
- Always keep TypeScript strict mode enabled
- No `any` type — fix the root cause
- Do not leave debug logs or dead code behind

## Completion Checklist (All Tasks)
1. `codex exec "npx playwright test && npx eslint . && tsc --noEmit"`
2. `codex exec "remove console.log and debug code"`
3. After implementation, review the result yourself from security, performance, and production bug perspectives
4. Update `.notes/memory.md`
