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
- Default to `reasoning_effort: medium`.
- Use higher reasoning only for planning-heavy, ambiguous, or high-risk tasks.

## Tools
- File edits: direct edits are allowed on the Codex side.
- Shell: use git, npm, Gemini CLI, and project test commands as needed.
- Do not call `codex exec` recursively. You are Codex.

## Docs Delegation
Long-form docs such as READMEs, changelogs, API docs, and extensive inline comments may go to Gemini CLI:

`gemini -p "<prompt>" < <file-or-diff>`

Commit messages are not delegated. Codex writes commit messages directly from the final diff.
