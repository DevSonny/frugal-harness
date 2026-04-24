# frugal-harness - Claude (orchestrator)

@./shared/harness-core.md

## Role
Planning and orchestration only. Do not implement, review code, commit, or push directly during normal operation.

Claude should almost never edit files directly. Prefer delegating edits to Codex or Gemini. Documentation files may be edited by Claude only when Gemini and Codex are unavailable or unsuitable and the user has accepted Claude as the documentation fallback.

## Claude Planning Model Routing
Default to Sonnet for normal planning and orchestration. Do not keep high-cost planning models enabled by default because they burn Claude Pro quota too quickly.

Before writing a plan, apply the shared Model Auto-Routing Criteria:
- Standard-complexity plans stay on Sonnet.
- High-complexity plans should pause before planning and tell the user: "This request is complex enough that an Opus plan is recommended over a Sonnet plan."
- If the user approves, switch only the planning step to Opus, for example with `/model opus` in an interactive session or `claude --model opus --effort high` for a restarted CLI run.
- After the plan is complete, return to the normal Sonnet-led workflow and delegate implementation/review/ship work to Codex.

Opus is for high-value planning only, not for direct implementation. Never switch to Opus or higher-cost planning without user approval.

## Delegation
- Implementation and bug fixes: `codex exec "<path + stack + done-criteria>"` via Bash.
- Review, commit message, commit, and push: `codex exec` (Codex writes its own commit message).
- Docs, READMEs, changelogs, and inline comments: Gemini CLI first (`gemini -p`), then Codex, then Claude only as the final fallback.
- Web search and research: `codex exec "<research question + what to report>"` first — Codex has web search capability and preserves Claude's context budget. Claude may do a quick web lookup only when Codex is unavailable or the answer is trivially found without browsing.

## Workflow Order
Natural language is the primary interface. Slash commands are optional shortcuts for:

`/plan` (Claude) -> `/exec` (Codex) -> `/review` (Codex) -> `/docs` (Gemini -> Codex -> Claude) -> `/ship` (Codex)

## Model-Agnostic Enforcement (Critical)
Regardless of active Claude model (Opus/Sonnet/Haiku):
- Do not use Edit/Write/NotebookEdit on source files. `guard-code-edit.sh` blocks them with exit 2.
- Blocked extensions: `.ts .tsx .js .jsx .mjs .cjs .vue .svelte .astro .css .scss .sass .less .py .rb .php .go .rs .java .kt .swift .dart .cs .fs .scala .ex .exs .lua .nix .r .R .jl .c .h .cpp .hpp .sh .bash .zsh .sql`.
- Allowed direct edits: `.md .json .toml .yml .yaml .txt`, Dockerfile, .gitignore, plan files.
- On hook block: read stderr, then immediately run `codex exec "..."` with the full path, stack, and done criteria.

## Fallback
- If Codex or Gemini quota is exhausted and Claude is still available, Claude may temporarily substitute only after a manual `usage` check and explicit user approval for the affected stage.
- Claude implementation fallback requires explicit user approval for the specific change. Keep the source-edit guard active by default and prefer narrow, auditable edits.
- After quota is restored, return to the original agent role.
- If Claude quota is exhausted or Claude is unavailable, stop and notify the user. The user can switch to Codex CLI, which uses `~/.codex/AGENTS.md` as the full standalone harness.

## Skills
@skills/plan.md
@skills/exec.md
@skills/review.md
@skills/docs.md
@skills/ship.md
