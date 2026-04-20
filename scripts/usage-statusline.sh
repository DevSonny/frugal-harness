#!/usr/bin/env bash
# Statusline: real usage data for Claude Code, Codex, Gemini

CLAUDE_SESSION_LIMIT=${CLAUDE_SESSION_LIMIT:-475}
CLAUDE_WEEKLY_LIMIT=${CLAUDE_WEEKLY_LIMIT:-2700}

# shellcheck source=/dev/null
source "$(dirname "$0")/lib-claude-window.sh"

input=$(cat)
project_dir=$(printf '%s' "$input" | jq -r '.workspace.project_dir')
model_name=$(printf '%s' "$input"  | jq -r '.model.display_name')
cwd=$(printf '%s' "$input"         | jq -r '.cwd')

branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

CY=$'\033[36m' MG=$'\033[35m' GN=$'\033[32m'
YL=$'\033[33m' RD=$'\033[31m' DM=$'\033[2m'  RS=$'\033[0m'

color_pct() {
  local p=$1
  if   (( p >= 50 )); then printf '%s' "$GN"
  elif (( p >= 20 )); then printf '%s' "$YL"
  else                     printf '%s' "$RD"
  fi
}

out=""
[ -n "$project_dir" ] && out+=$(printf '%b%s%b' "$CY" "$(basename "$project_dir")" "$RS")
[ -n "$model_name"  ] && out+=$(printf ' %b%s%b' "$MG" "$model_name" "$RS")
[ -n "$branch"      ] && out+=$(printf ' %b⎇ %s%b' "$GN" "$branch" "$RS")

# ── Claude Code: rolling 5h and 7d windows ──────────────────────
s_msgs=0 w_msgs=0
if command -v jq >/dev/null 2>&1; then
  IFS=$'\t' read -r s_msgs w_msgs _ _ _ _ < <(claude_window_stats)
fi
s_used_pct=$(( s_msgs * 100 / CLAUDE_SESSION_LIMIT ))
(( s_used_pct > 100 )) && s_used_pct=100
w_used_pct=$(( w_msgs * 100 / CLAUDE_WEEKLY_LIMIT  ))
(( w_used_pct > 100 )) && w_used_pct=100
s_left=$(( 100 - s_used_pct ))
w_left=$(( 100 - w_used_pct ))
c_s=$(color_pct "$s_left"); c_w=$(color_pct "$w_left")
out+=$(printf '  %bClaude%b %bsession %s%%%b %bweek %s%%%b' \
  "$DM" "$RS" "$c_s" "$s_left" "$RS" "$c_w" "$w_left" "$RS")

# ── Codex: real rate_limits from rollout JSONL ──────────────────
ROLLOUT=$(ls -1t "$HOME"/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -1 || true)
cx5h="?" cxwk="?"
if [ -n "$ROLLOUT" ] && command -v jq >/dev/null 2>&1; then
  rl=$(grep '"type":"token_count"' "$ROLLOUT" 2>/dev/null | tail -1 | \
       jq -r '[
         (100 - (.payload.rate_limits.primary.used_percent|floor)|tostring),
         (100 - (.payload.rate_limits.secondary.used_percent|floor)|tostring)
       ] | @tsv' 2>/dev/null || true)
  [ -n "$rl" ] && IFS=$'\t' read -r cx5h cxwk <<< "$rl"
fi
if [ "$cx5h" != "?" ]; then
  c5=$(color_pct "$cx5h"); cw=$(color_pct "$cxwk")
  out+=$(printf '  %bCodex%b %b5h %s%%%b %bweek %s%%%b' \
    "$DM" "$RS" "$c5" "$cx5h" "$RS" "$cw" "$cxwk" "$RS")
else
  out+=$(printf '  %bCodex%b ?' "$DM" "$RS")
fi

# ── Gemini: today's API call count ──────────────────────────────
TODAY=$(date +%F)
gm=0
GEMINI_DIR="$HOME/.gemini/tmp"
if command -v jq >/dev/null 2>&1 && [ -d "$GEMINI_DIR" ]; then
  while IFS= read -r -d '' f; do
    fdate=$(basename "$f" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
    [ "$fdate" = "$TODAY" ] || continue
    n=$(jq '[.messages[]?|select(.type=="gemini")]|length' "$f" 2>/dev/null || echo 0)
    (( gm += n )) || true
  done < <(find "$GEMINI_DIR" -type f -path '*/chats/*.json' -print0 2>/dev/null)
fi
out+=$(printf '  %bGemini%b %s calls today' "$DM" "$RS" "$gm")

printf '%s\n' "$out"
