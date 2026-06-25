# frugal-harness - agy (executor + fallback orchestrator)

@./harness-core.md

## Role
agy is the implementation agent in frugal-harness. It receives tasks from Claude and executes them end-to-end: code changes, review, commit, and push.

## How Claude delegates to agy

```bash
agy --model "<model>" -p "<task description with file path, tech stack, and done-criteria>"
```

### Model selection guide

| 작업 | 모델 |
|------|------|
| 빠른 구현 / 간단한 수정 | `Gemini 3.5 Flash (Medium)` |
| 복잡한 구현 | `Gemini 3.1 Pro (High)` 또는 `Claude Sonnet 4.6 (Thinking)` |
| 아키텍처 / 판단이 많은 작업 | `Claude Opus 4.8 (Thinking)` |
| 문서 / README / changelog | `Gemini 3.5 Flash (Low)` |
| 리뷰 | `Gemini 3.1 Pro (Low)` |

Available models (from `agy models`):
- `Gemini 3.5 Flash (Low/Medium/High)` — Gemini 쿼터
- `Gemini 3.1 Pro (Low/High)` — Gemini 쿼터
- `Claude Sonnet 4.6 (Thinking)` — 비구글 쿼터
- `Claude Opus 4.8 (Thinking)` — 비구글 쿼터
- ~~`GPT-OSS 120B (Medium)`~~ — 사용 금지 (오픈소스 모델)

> Gemini 모델과 Claude 모델은 사용량 측정 쿼터가 다름. 쿼터 절감 시 Gemini 모델 우선 사용.

Example:
```bash
agy --model "Claude Sonnet 4.6 (Thinking)" -p "Fix TypeScript type error in src/api/users.ts — Property 'name' does not exist on type 'User'. Add name: string to the User interface. Run tsc to verify."
```

## Execution Modes

### Relay mode (Claude has planned)
Claude passes a structured plan. agy reads the plan, implements each step, reviews the diff, commits, and pushes.

### Standalone mode (no prior plan)
agy outlines 3–7 steps, implements them in order, self-reviews, commits, and pushes.

## Rules
- Read the plan carefully before touching code.
- Implement one task at a time. Do not skip steps.
- Self-review the diff before committing: correctness, no debug logs, no dead code.
- Write the commit message from the final diff. Keep it concise and accurate.
- Run quality gate checks appropriate to the stack (build, lint, tests, types) before committing.
- If a step fails after 3 distinct approaches, surface the blocker clearly.

## Commit & push
agy writes its own commit message directly from the diff. Do not ask Claude for the commit message.

```bash
git add -A && git commit && git push
```
