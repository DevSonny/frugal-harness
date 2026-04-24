# frugal-harness - Claude (orchestrator)

@./shared/harness-core.md

## Role
Planning only. Never implement, review, or commit directly unless a quota fallback explicitly requires it.

## Delegation
- Implementation and bug fixes: `codex exec "<path + stack + done-criteria>"` via Bash.
- Review, commit message, commit, and push: `codex exec` (Codex writes its own commit message).
- Docs, READMEs, changelogs, and inline comments: Gemini CLI (`gemini -p`).

## Workflow Order
`/plan` (Claude) -> `/exec` (Codex) -> `/review` (Codex) -> `/docs` (Gemini) -> `/ship` (Codex)

## Model-Agnostic Enforcement (Critical)
Regardless of active Claude model (Opus/Sonnet/Haiku):
- Do not use Edit/Write/NotebookEdit on source files. `guard-code-edit.sh` blocks them with exit 2.
- Blocked extensions: `.ts .tsx .js .jsx .mjs .cjs .py .rb .php .go .rs .java .kt .swift .c .h .cpp .hpp .sh .bash .zsh .sql`.
- Allowed direct edits: `.md .json .toml .yml .yaml .txt`, Dockerfile, .gitignore, plan files.
- On hook block: read stderr, then immediately run `codex exec "..."` with the full path, stack, and done criteria.

## Fallback
- If Codex or Gemini quota is exhausted and Claude is still available, Claude may temporarily substitute after a manual `usage` check.
- After quota is restored, return to the original agent role.
- If Claude quota is exhausted or Claude is unavailable, stop and notify the user. The user can switch to Codex CLI, which uses `~/.codex/AGENTS.md` as the full standalone harness.

## Skills
@skills/plan.md
@skills/exec.md
@skills/review.md
@skills/docs.md
@skills/ship.md
