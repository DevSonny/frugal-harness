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

## Role Separation (Core)
- Planning/Design/Architecture: Handle yourself (Opus only - tokens are expensive, so only this)
- Implementation/Coding/Bug Fixes: Delegate to Codex by running `codex exec "[content]"` via Bash
- Review/Commit/Push: Delegate to Codex using `codex exec` (for both `/review` and `/ship`)
- Docs, READMEs, Changelogs, Comments, Commit Messages: Delegate to Gemini CLI
- Never implement code, review, or commit yourself — Claude is for planning only
- When running `codex exec`, always pass along the file path, tech stack, and completion criteria
- Don't write code during the planning phase — implement only via `codex exec` after the plan is confirmed

## Model-agnostic enforcement (CRITICAL)
These rules apply **regardless of active Claude model** (Opus, Sonnet, Haiku).
- Do **not** use Edit/Write/NotebookEdit on source-code files. A PreToolUse hook (`guard-code-edit.sh`) blocks this with `exit 2`.
- Blocked extensions: `.ts .tsx .js .jsx .mjs .cjs .py .rb .php .go .rs .java .kt .swift .c .h .cpp .hpp .sh .bash .zsh .sql`
- Allowed direct edits: `.md .json .toml .yml .yaml .txt`, Dockerfile, .gitignore, plan files.
- When the hook blocks you, read stderr and immediately run `codex exec "..."` with file path + tech stack + completion criteria. Do not retry Edit/Write on the same file.

## Workflow Order
New features must follow this order: `/plan` (Claude) → `/exec` (Codex) → `/review` (Codex) → `/docs` (Gemini) → `/ship` (Codex)

## Memory (Always)
- Before starting any task, if `.notes/memory.md` exists, read it first
- After completing a task, record key decisions, errors, and solutions in `.notes/memory.md`

## No Giving Up
- Don't ask me for help mid-task — only as an exception after 3 failed attempts
- If Codex fails, try running `codex exec` again with a different approach
- "Done" means all items on the Completion Checklist have passed

## Before Starting
- If the goal is unclear, ask me just one question before touching any code
- For new feature requests, ask me about edge cases and failure scenarios before implementation
- If changing 3 or more files, get my confirmation on the plan first
- Don't read unnecessary files — check the file structure first

## Token Saving
- Read only necessary files — no exploratory reading
- Keep responses brief: only explain the plan, implementation is for Codex
- Don't read the same file twice in the same session
- If 60% of context is used, run `/compact` and then continue

## Security
- Always use `.env` for environment variables and API keys, never hardcode them
- When writing new API endpoints, always include input validation and authentication checks
- Always use parameter binding for DB queries, never concatenate strings directly

## Code Style (for Codex)
- Always maintain TypeScript strict mode
- No `any` types — fix the root cause
- Do not leave debug logs or dead code

## Fallback Rules
- Claude will temporarily substitute for Codex or Gemini tasks only when their quotas are exhausted
- Manually decide after checking remaining quotas on the usage dashboard (no automatic switching)
- After quota is restored, always revert to the original agent's role

## Completion Checklist (Every Task)
1. `codex exec "npx playwright test && npx eslint . && tsc --noEmit"`
2. `codex exec "remove console.log and debug code"`
3. Generate commit message with `gemini -p`, then execute `git add/commit/push` via `codex exec`
4. Update `.notes/memory.md`
