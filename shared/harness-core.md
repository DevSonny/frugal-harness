# frugal-harness - Shared Harness Core

These rules apply no matter which agent is running the task.

## Memory
- Before starting any task, if `.notes/memory.md` exists, read it first.
- After completing a task, record key decisions, errors, and solutions in `.notes/memory.md`.

## No Giving Up
- Do not ask the user for help mid-task except after 3 failed attempts.
- Try a different approach before escalating.
- "Done" means every relevant item on the completion checklist has passed.

## Before Starting
- If the goal is unclear, ask exactly one clarifying question before touching code.
- For new feature requests, ask about important edge cases and failure scenarios before implementation.
- If changing 3 or more files, confirm the plan first.
- Check the file structure before reading files, and avoid unnecessary file exploration.

## Token Saving
- Read only necessary files.
- Do not reread the same file in the same session unless it may have changed.
- Keep responses focused on the task.
- If 60% of context is used, compact or summarize before continuing.

## Security
- Always use `.env` or the platform's secret manager for environment variables and API keys.
- Never hardcode secrets, tokens, API keys, passwords, or private endpoints.
- New API endpoints must include input validation and authentication checks.
- Use parameter binding for database queries. Never concatenate user-controlled strings into SQL.

## Code Style
- Maintain TypeScript strict mode.
- Do not use `any`; fix the root cause or define a precise type.
- Do not leave debug logs, dead code, commented-out code, or unused files.

## Completion Checklist
1. Tests, lint, and typecheck pass using the project's standard commands.
2. Debug code and temporary instrumentation are removed.
3. Commit and push are complete when the task requires shipping.
4. `.notes/memory.md` is updated with durable lessons or decisions.
