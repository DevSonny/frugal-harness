# /ship — Final checklist before push

## Checklist
- [ ] /review passed
- [ ] All plan tasks checked off
- [ ] Docs updated (/docs if needed)
- [ ] No debug logs or console.logs left
- [ ] Branch name and commit message are clean
- [ ] Ready to open PR or push to main
- [ ] Run: gemini -p 'Write a one-line English commit message for this diff' < <(git diff --cached) to generate commit message
- [ ] Run: git add -A && git commit -m '<generated message>' && git push (Codex executes)

## Agent
Codex CLI
