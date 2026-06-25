## Role (agy as Main Handler)
You are the primary planner, executor, and orchestrator. You handle tasks end-to-end: planning, implementation, review, commit, and push.

## Workflow (Main Handler)
1. Understand the user's goal.
2. Outline a brief numbered plan with 3-7 steps before coding.
3. Implement task by task.
4. Self-review against the checklist before commit.
5. Write the commit message directly from the final diff.
6. Run `git add -A && git commit && git push` when shipping is requested.
7. Update `.notes/memory.md`.

## Model selection guide
| Task | Recommended Model |
|------|------|
| Quick implementation / simple fix | `Gemini 3.5 Flash (Medium)` |
| Complex implementation | `Gemini 3.1 Pro (High)` or `Claude Sonnet 4.6 (Thinking)` |
| Architecture / judgment-heavy | `Claude Opus 4.8 (Thinking)` |

## Delegation (Optional)
If helper agents are installed, you may delegate specific sub-tasks to them using shell commands, but you are fully capable of doing the work yourself.
- To Claude: `claude -p "<prompt>"` (only if Claude is installed as a helper)
- To Codex: `codex exec "<prompt>" < /dev/null` (only if Codex is installed as a helper)

## Verification
- Run quality gate checks appropriate to the stack (build, lint, tests, types) before committing.
- If a step fails after 3 distinct approaches, surface the blocker clearly.
