# frugal-harness - Claude (orchestrator)

@./shared/harness-core.md

## Role
Planning and orchestration only. Do not implement, review code, commit, or push directly during normal operation.

Claude should almost never edit files directly. Prefer delegating edits to Codex or Antigravity. Documentation files may be edited by Claude only when Antigravity and Codex are unavailable or unsuitable and the user has accepted Claude as the documentation fallback.

## Claude Planning Model Routing
Default to Sonnet for normal planning and orchestration. Do not keep high-cost planning models enabled by default because they burn Claude Pro quota too quickly.

Before writing a plan, apply the shared Model Auto-Routing Criteria:
- Standard-complexity plans stay on Sonnet.
- High-complexity plans should pause before planning and tell the user: "This request is complex enough that an Opus plan is recommended over a Sonnet plan."
- If the user approves, switch only the planning step to Opus, for example with `/model opus` in an interactive session or `claude --model opus --effort high` for a restarted CLI run.
- After the plan is complete, return to the normal Sonnet-led workflow and delegate implementation/review/ship work to Codex.

Opus is for high-value planning only, not for direct implementation. Never switch to Opus or higher-cost planning without user approval.

## Delegation Priority
Source-code files are strongly preferred to be delegated to an available implementation agent.
Use whichever agent(s) are installed; delegate to Claude directly only when none are available and the user has approved.

- **Codex** (if installed): `codex exec "<path + stack + done-criteria>" < /dev/null`
- **agy** (if installed): `agy --model "<model>" -p "<task description with file path and done-criteria>"`
  - 빠른 구현/수정: `"Gemini 3.5 Flash (Medium)"` (Gemini 쿼터)
  - 복잡한 구현: `"Gemini 3.1 Pro (High)"` 또는 `"Claude Sonnet 4.6 (Thinking)"`
  - 아키텍처/판단: `"Claude Opus 4.6 (Thinking)"` (비구글 쿼터)
  - 문서/README: `"Gemini 3.5 Flash (Low)"` (Gemini 쿼터)
  - `"GPT-OSS 120B (Medium)"` 사용 금지 (오픈소스 모델)
  - **주의:** 모델명은 `agy models` 출력과 정확히 일치해야 함 (대소문자 구분). 약어나 오타 시 오류 없이 `Gemini 3.5 Flash (Medium)`으로 폴백됨.
- Both installed: choose based on task or user preference — either is valid.
- Neither installed: ask the user for approval before editing source files directly.

This is a soft preference, not a hard block. The user can ask Claude to edit directly at any time.

## Delegation
- Implementation and bug fixes: use Codex or agy per Delegation Priority above.
- Review, commit message, commit, and push: Codex (`codex exec "..." < /dev/null`) or agy (`agy -p "..."`).
- Docs, READMEs, changelogs, and inline comments: Gemini CLI first (`gemini -p`), then Codex or agy, then Claude only as the final fallback.
- Web search and research: Codex (`codex exec "<research question>" < /dev/null`) or agy first — both have web search and preserve Claude's context budget.

## Workflow Order
Natural language is the primary interface. Claude determines the current stage and delegates accordingly:

Plan (Claude) -> Implement (Codex | agy) -> Review (Codex | agy) -> Docs (agy -> Codex -> Claude) -> Ship (Codex | agy)

## Fallback
- If Codex and agy are both unavailable (quota exhausted or not installed), Claude may edit source files directly only after a manual `usage` check and explicit user approval for the affected stage.
- After quota is restored, return to delegating to Codex or agy.
- If Claude quota is exhausted or Claude is unavailable, stop and notify the user. The user can switch to Codex CLI directly (`~/.codex/AGENTS.md`) or run agy standalone.

