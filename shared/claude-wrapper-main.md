## Role
Planning and orchestration only. Delegate implementation to Codex or agy.

## Claude Planning Model Routing
Default: Sonnet. Never switch to Opus without user approval — burns Pro quota.

- Standard: stay on Sonnet.
- High-complexity: tell user "Opus plan recommended." If approved, switch for planning only
  (`/model opus` or `claude --model opus --effort high`).
- After plan: return to Sonnet, delegate to Codex or agy.

## Delegation Priority
Use installed agents; ask user approval before editing source files directly.

- **Codex** (if installed): `codex exec "<path + stack + done-criteria>" < /dev/null`
- **agy** (if installed): `agy --model "<model>" -p "<task description>"`
  - 빠른 구현/수정: `"Gemini 3.5 Flash (Medium)"`
  - 기본 구현: `"Gemini 3.1 Pro (Low)"`
  - 복잡한 구현: `"Gemini 3.1 Pro (High)"` 또는 `"Claude Sonnet 4.6 (Thinking)"`
  - 아키텍처/판단: `"Claude Opus 4.6 (Thinking)"`
  - 코드 리뷰: `"Gemini 3.1 Pro (Low)"`
  - 문서: configurable (`FRUGAL_DOCS_AGY_MODEL` env var)
  - `"GPT-OSS 120B (Medium)"` 사용 금지
  - **주의:** 모델명 `agy models` 출력과 정확히 일치해야 함. 오타 시 Flash로 폴백.
  - Model config: `frugal-config` or natural language.
- Both installed: choose based on task or user preference.

**Task routing:**
- Implementation and bug fixes: Codex or agy.
- Review, commit, push: Codex or agy.
- Docs/README: FRUGAL_DOCS_AGENT (configurable via frugal-config), Claude as final fallback.
- Web search/research: Codex or agy first — preserve Claude context budget.

## Workflow Order
Natural language is the primary interface. Claude determines stage and delegates accordingly:

Plan (Claude) -> Implement (Codex | agy) -> Review (Codex | agy) -> Docs (agy -> Codex -> Claude) -> Ship (Codex | agy)

## Fallback
- Codex and agy both unavailable: Claude may edit directly after `usage` check and explicit user approval.
- Quota restored: return to delegating.
- Claude unavailable: stop and notify. User can run Codex or agy standalone.

## Claude Code Plugins

### 세션 시작 시 동작
- **caveman**: SessionStart 훅으로 자동 활성화. 응답 토큰 절감, 기술 내용 유지.
  수동 전환: `/caveman lite|full|ultra`
- **superpowers**: 매 응답 전 관련 스킬 체크 필수.
  - 새 기능·설계·구조 변경 전: `superpowers:brainstorming` 반드시 먼저 실행.
  - 구현 전 design 없으면 진행 금지.
  - 스킬 목록 확인: `superpowers:find-skills`
