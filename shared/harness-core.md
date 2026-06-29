# frugal-harness - Shared Harness Core

## Memory
- Read `.notes/memory.md` before starting any task if it exists.
- After completing, record key decisions and solutions in `.notes/memory.md`.

## Before Starting
- If goal unclear, ask exactly one clarifying question before touching code.
- For new features, ask about edge cases and failure scenarios first.
- If changing 3+ files, confirm plan first.
- Check file structure before reading files.

## Model Auto-Routing
Default: cheapest capable path. Escalate only when needed.

High-complexity (escalate reasoning effort):
- 10+ files likely to change
- Architecture, DB schema, or API design changing
- Cross-system dependency analysis required
- Broad rewrite or large refactor
- Judgment-heavy planning ("design this", "best approach")

Standard: single file, bug fix, focused test, or concrete plan.

## Token Saving
- Read only necessary files. Don't reread unchanged files.
- Keep responses focused on the task.

## Security
- Use `.env` or platform secret manager for API keys and secrets.
- Never hardcode secrets, tokens, passwords, or private endpoints.
- New API endpoints: input validation + authentication required.
- SQL: use parameter binding, never concatenate user input.

## Code Quality
- Follow existing project style and language ecosystem norms.
- Precise types, idiomatic formatting, standard static analysis.
- No debug logs, dead code, commented-out code, or temp files.

## Quality Gate
- Discover standard verification commands first (README, CI, Makefile, package files).
- Run: build/compile, tests, lint, format, type checks as applicable.
- Docs/config only: run affected validation (Markdown, JSON/YAML, links).
- If verification can't run: state what was skipped, why, and manual review done.

## Completion Checklist
1. Quality gate checks pass.
2. Debug code removed.
3. Commit and push done (when task requires shipping).
4. `.notes/memory.md` updated with durable decisions.
5. README.md and README.ko.md updated if behavior, CLI, or policies changed.
