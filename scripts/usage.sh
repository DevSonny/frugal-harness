#!/usr/bin/env bash
set -euo pipefail

CLAUDE_SESSION_LIMIT=${CLAUDE_SESSION_LIMIT:-475}
CLAUDE_WEEKLY_LIMIT=${CLAUDE_WEEKLY_LIMIT:-2700}

# shellcheck source=/dev/null
_self="$0"; while [ -L "$_self" ]; do _self="$(readlink "$_self")"; done
SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
source "$SCRIPT_DIR/lib-claude-window.sh"

GN=$'\033[32m' YL=$'\033[33m' RD=$'\033[31m'
CY=$'\033[36m' DM=$'\033[2m'  RS=$'\033[0m'
LINE='━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
TODAY=$(date +%F)
NOW=$(date '+%Y-%m-%d %H:%M')

color_pct() {   # color_pct <remaining_int>
  local p=$1
  if   (( p >= 50 )); then printf '%s' "$GN"
  elif (( p >= 20 )); then printf '%s' "$YL"
  else                     printf '%s' "$RD"
  fi
}

bar() {   # bar <remaining_int>
  local p=$1 used filled empty
  used=$(( 100 - p ))
  filled=$(( used  / 5 )); (( filled > 20 )) && filled=20
  empty=$(( 20 - filled ))
  local c; c=$(color_pct "$p")
  printf '%b' "$c"
  printf '%0.s█' $(seq 1 $filled 2>/dev/null) 2>/dev/null || true
  printf '%b' "$RS"
  printf '%0.s░' $(seq 1 $empty  2>/dev/null) 2>/dev/null || true
}

fmt_k() {
  local v="${1:-0}"
  if [[ "$v" =~ ^[0-9]+$ ]] && (( v > 0 )); then
    if   (( v >= 1000000 )); then awk -v n="$v" 'BEGIN{out=sprintf("%.1f",n/1000000);sub(/\.0$/,"",out);print out"M"}'
    elif (( v >= 1000    )); then awk -v n="$v" 'BEGIN{out=sprintf("%.1f",n/1000);sub(/\.0$/,"",out);print out"k"}'
    else printf '%s' "$v"
    fi
  else
    printf '%s' "${v:-0}"
  fi
}

reset_str() {   # reset_str <unix_seconds>
  date -r "$1" '+%m/%d %H:%M' 2>/dev/null || date -d "@$1" '+%m/%d %H:%M' 2>/dev/null || echo "?"
}

printf '%s\n' "$LINE"
printf ' CLI USAGE  (%s)\n' "$NOW"
printf '%s\n' "$LINE"

# ── Claude Code ─────────────────────────────────────────────────
printf '%bClaude Code%b  %b(rolling window from project JSONL)%b\n' "$CY" "$RS" "$DM" "$RS"

s_msgs=0 w_msgs=0 s_in=0 s_out=0 w_in=0 w_out=0
if command -v jq >/dev/null 2>&1; then
  IFS=$'\t' read -r s_msgs w_msgs s_in s_out w_in w_out < <(claude_window_stats)
fi
s_used_pct=$(( s_msgs * 100 / CLAUDE_SESSION_LIMIT ))
(( s_used_pct > 100 )) && s_used_pct=100
w_used_pct=$(( w_msgs * 100 / CLAUDE_WEEKLY_LIMIT ))
(( w_used_pct > 100 )) && w_used_pct=100
s_left=$(( 100 - s_used_pct ))
w_left=$(( 100 - w_used_pct ))

c_sess=$(color_pct "$s_left"); c_wk=$(color_pct "$w_left")
printf '   Session 5h: '; bar "$s_left"
printf '  %b%s%%%b left  (%s/%s msgs used)\n' "$c_sess" "$s_left" "$RS" "$s_msgs" "$CLAUDE_SESSION_LIMIT"
printf '   Weekly 7d:  '; bar "$w_left"
printf '  %b%s%%%b left  (%s/%s msgs used)\n' "$c_wk" "$w_left" "$RS" "$w_msgs" "$CLAUDE_WEEKLY_LIMIT"
printf '   Tokens 5h:   in %s / out %s\n' "$(fmt_k "$s_in")" "$(fmt_k "$s_out")"
printf '   Tokens 7d:   in %s / out %s\n' "$(fmt_k "$w_in")" "$(fmt_k "$w_out")"
printf '   %bLimits (approx): session=%s msgs / week=%s msgs.%b\n' \
  "$DM" "$CLAUDE_SESSION_LIMIT" "$CLAUDE_WEEKLY_LIMIT" "$RS"
printf '   %bCalibrate: CLAUDE_SESSION_LIMIT=N CLAUDE_WEEKLY_LIMIT=N usage%b\n' "$DM" "$RS"

# ── Codex CLI ───────────────────────────────────────────────────
printf '\n'
ROLLOUT=$(ls -1t "$HOME"/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -1 || true)

if [[ -n "$ROLLOUT" ]] && command -v jq >/dev/null 2>&1; then
  snap_ts=$(stat -c %Y "$ROLLOUT" 2>/dev/null || stat -f %m "$ROLLOUT" 2>/dev/null || echo 0)
  snap_age=$(( $(date +%s) - snap_ts ))
  snap_min=$(( snap_age / 60 ))

  rl=$(grep '"type":"token_count"' "$ROLLOUT" 2>/dev/null | tail -1 | \
       jq -r '.payload.rate_limits' 2>/dev/null)

  if [[ -n "$rl" ]]; then
    cx5h_used=$(printf '%s' "$rl" | jq -r '.primary.used_percent | floor')
    cx5h_left=$(( 100 - cx5h_used ))
    cx5h_reset=$(printf '%s' "$rl" | jq -r '.primary.resets_at')

    cxwk_used=$(printf '%s' "$rl" | jq -r '.secondary.used_percent | floor')
    cxwk_left=$(( 100 - cxwk_used ))
    cxwk_reset=$(printf '%s' "$rl" | jq -r '.secondary.resets_at')

    cx_plan=$(printf '%s' "$rl" | jq -r '.plan_type')
    cx_model=$(grep '"type":"token_count"' "$ROLLOUT" 2>/dev/null | tail -1 | \
               jq -r '.payload.model // "gpt-5.5"' 2>/dev/null || echo "gpt-5.5")

    printf '%bCodex CLI%b  %b(%s · %s · data from %sm ago)%b\n' \
      "$CY" "$RS" "$DM" "$cx_plan" "$cx_model" "$snap_min" "$RS"

    c5h_c=$(color_pct "$cx5h_left"); cwk_c=$(color_pct "$cxwk_left")
    printf '   5h limit:  '; bar "$cx5h_left"
    printf '  %b%s%%%b left  (resets %s)\n' "$c5h_c" "$cx5h_left" "$RS" "$(reset_str "$cx5h_reset")"
    printf '   Weekly:    '; bar "$cxwk_left"
    printf '  %b%s%%%b left  (resets %s)\n' "$cwk_c" "$cxwk_left" "$RS" "$(reset_str "$cxwk_reset")"
  else
    printf '%bCodex CLI%b  %b(no rate_limits data found)%b\n' "$CY" "$RS" "$DM" "$RS"
  fi
else
  printf '%bCodex CLI%b  %b(no session rollout found)%b\n' "$CY" "$RS" "$DM" "$RS"
fi

# ── Gemini CLI ──────────────────────────────────────────────────
printf '\n'
gm_calls=0 gm_today=0 gm_in=0 gm_out=0 gm_cached=0
gm_today_in=0 gm_today_out=0
gm_model=$(jq -r '.model.name // "gemini-2.5-flash-lite"' "$HOME/.gemini/settings.json" 2>/dev/null || echo "gemini-2.5-flash-lite")

GEMINI_DIR="$HOME/.gemini/tmp"
if command -v jq >/dev/null 2>&1 && [[ -d "$GEMINI_DIR" ]]; then
  while IFS= read -r -d '' f; do
    fdate=$(basename "$f" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
    while IFS=$'\t' read -r in_t out_t cach m; do
      (( gm_calls++       )) || true
      (( gm_in    += in_t )) || true
      (( gm_out   += out_t)) || true
      (( gm_cached+= cach )) || true
      true
      if [[ "$fdate" == "$TODAY" ]]; then
        (( gm_today++         )) || true
        (( gm_today_in += in_t)) || true
        (( gm_today_out+= out_t))|| true
      fi
    done < <(
      jq -r '.messages[]? | select(.type=="gemini") |
             "\(.tokens.input//0)\t\(.tokens.output//0)\t\(.tokens.cached//0)\t\(.model//"")"' \
        "$f" 2>/dev/null
    )
  done < <(find "$GEMINI_DIR" -type f -path '*/chats/*.json' -print0 2>/dev/null)
fi

printf '%bGemini CLI%b  %b(%s)%b\n' "$CY" "$RS" "$DM" "$gm_model" "$RS"
printf '   Today:     %s API calls — in %s / out %s\n' \
  "$gm_today" "$(fmt_k "$gm_today_in")" "$(fmt_k "$gm_today_out")"
printf '   All time:  %s API calls — in %s / out %s / cached %s\n' \
  "$gm_calls" "$(fmt_k "$gm_in")" "$(fmt_k "$gm_out")" "$(fmt_k "$gm_cached")"
printf '   %b(Google quota is server-side only)%b\n' "$DM" "$RS"

printf '%s\n' "$LINE"
