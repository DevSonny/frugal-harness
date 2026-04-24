# /review — Sanity check before commit

## When to use
Before every commit.

## Checklist
- Does the code match the plan?
- Any obvious bugs or edge cases missed?
- Are there hardcoded values that should be config?
- Is the diff clean and minimal?
- Are tests passing?
- Were relevant project quality checks run or clearly skipped with a reason?

## Output
LGTM or a list of issues to fix before committing.

## Agent
Codex CLI
