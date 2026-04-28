#!/usr/bin/env bash
# PreToolUse guard: block Edit/Write/NotebookEdit on source-code files so that
# code implementation is always delegated to Codex (via `codex exec`) regardless
# of which Claude model (Opus, Sonnet, Haiku) is active.
#
# Claude Code passes a JSON payload on stdin like:
#   {"tool_input": {"file_path": "/abs/path/to/file.ts", ...}, ...}
#
# Exit codes:
#   0  allow the tool call
#   2  block the tool call; stderr is delivered to Claude as error context

if ! command -v node >/dev/null 2>&1; then
  exit 0
fi

path=$(node -e '
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => { input += chunk; });
process.stdin.on("end", () => {
  try {
    const payload = JSON.parse(input);
    process.stdout.write((payload.tool_input && payload.tool_input.file_path) || "");
  } catch {}
});
' 2>/dev/null)
[ -z "$path" ] && exit 0

case "$path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue|*.svelte|*.astro|\
  *.css|*.scss|*.sass|*.less|\
  *.py|*.rb|*.php|\
  *.go|*.rs|*.java|*.kt|*.swift|*.dart|\
  *.cs|*.fs|*.scala|*.ex|*.exs|\
  *.lua|*.nix|*.r|*.R|*.jl|\
  *.c|*.h|*.cpp|*.hpp|\
  *.sh|*.bash|*.zsh|\
  *.sql)
    cat >&2 <<EOF
BLOCKED: $path is a source-code file.

CLAUDE.md rule: all code implementation must be delegated to Codex,
regardless of which Claude model is active (Opus, Sonnet, Haiku).

Do NOT retry Edit/Write on this file. Instead, run:

  codex exec "<task description with file path, tech stack, and acceptance criteria>"

Allowed direct edits (not blocked): .md .json .toml .yml .yaml .txt, Dockerfile, .gitignore, plan files.
EOF
    exit 2
    ;;
esac

exit 0
