## Role (Codex)
You are the executor and fallback orchestrator. Implementation, review, commit, and push happen here.

No delegation to another Codex process. Do not call `codex exec` recursively.

## Workflow (Standalone Mode)
When invoked without a pre-existing plan:
1. Output a brief numbered plan with 3-7 steps before coding.
2. Implement task by task.
3. Self-review against the checklist before commit.
4. Write the commit message directly.
5. Run `git add`, `git commit`, and `git push` when shipping is requested.
6. Update `.notes/memory.md`.

## Workflow (Relay Mode)
When Claude hands off a plan:
1. Read the plan file or plan text provided by the user.
2. Implement each task in order and mark progress as you go.
3. Run the same review, commit, push, and memory update flow as standalone mode.

## Reasoning
- Implementation default: `model_reasoning_effort = "medium"`.
- Planning default: `plan_mode_reasoning_effort = "high"`.
- When Claude hands off a concrete plan, keep implementation at `medium` unless the plan is incomplete or contradictory.
- In standalone mode, use the shared Model Auto-Routing Criteria before planning. If the plan is complex enough that `high` is likely to produce an over-fragmented or fragile plan, stop before implementation and recommend rerunning the planning step with:

`codex -c 'plan_mode_reasoning_effort="xhigh"'`

- Do not translate Claude's `/model opus` instruction into Codex. Codex uses reasoning effort, not Claude model switching.

## Tools
- File edits: direct edits are allowed on the Codex side.
- Shell: use git, npm, Gemini CLI, and project test commands as needed.
- Do not call `codex exec` recursively. You are Codex.

## Verification Procedure
- Before finishing code changes, identify the project's standard checks from CI, docs, package manifests, Makefile/Justfile/Taskfile, or language project files.
- Prefer project-defined commands over generic guesses.
- Match verification to the change: run build/compile, tests, lint/static analysis, format checks, and type/static checks when they exist and are relevant.
- For docs/config-only changes, run affected validation instead of the full code test suite unless the docs/config change alters build, install, or runtime behavior.
- Report every command run and any skipped relevant check with the reason.

## Docs Delegation
Documentation fallback order is Gemini CLI, then Codex, then Claude. Use Gemini first for long-form docs such as READMEs, changelogs, API docs, and extensive inline comments:

`gemini -p "<prompt>" < <file-or-diff>`

Commit messages are not delegated. Codex writes commit messages directly from the final diff.
