# Delegation Profile
# DEFAULT checked-in copy. At install time render-profile.sh regenerates this at
# ~/.claude/shared/delegation-profile.md from ~/.config/frugal/profile.json.
# Do not edit directly. Re-run `frugal config` to change it.

Subscribed worker agents: Antigravity, Codex.

Routing: complexity-auto. Apply the shared Model Auto-Routing Criteria in harness-core.md:
- Standard tasks: plan on Sonnet, Codex effort `medium`.
- Complex tasks: plan on Opus (after user approval), Codex effort `xhigh`.

Per-role delegation priority (try the first agent; fall back down the list if it is unavailable or out of quota):
- Plan: Claude
- Implementation (exec): Antigravity -> Codex
- Review: Antigravity -> Codex
- Docs: Antigravity -> Codex
- Ship (commit/push): Codex -> Antigravity

Invocation forms:
- Antigravity: `agy -p "<task>"` (add `--dangerously-skip-permissions` for autonomous file edits).
- Codex: `codex exec "<task>" < /dev/null`.
