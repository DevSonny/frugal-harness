#!/usr/bin/env bash
# PreToolUse guide: nudge Claude to prefer Codex for source-code edits.
# Does NOT block — exits 0 so the edit can still proceed.
#
# Claude Code passes a JSON payload on stdin like:
#   {"tool_input": {"file_path": "/abs/path/to/file.ts", ...}, ...}
#
# Exit codes:
#   0  allow the tool call (always)

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
HINT: $path is a source-code file.

Consider delegating to Codex or agy for implementation work:

  codex exec "<task description with file path, tech stack, and acceptance criteria>" < /dev/null
  agy --model "Gemini 3.1 Pro (Low)" -p "<task description>"

You may proceed with the direct edit if Codex is unavailable or the user has approved.
EOF
    ;;
esac

exit 0
