#!/usr/bin/env bash
# Computes current-session token costs for Claude Code, Codex, and Gemini.

cost_from_tokens() {
  awk -v in_tok="${1:-0}" \
      -v cached_tok="${2:-0}" \
      -v cache_creation_tok="${3:-0}" \
      -v out_tok="${4:-0}" \
      -v input_rate="${5:-0}" \
      -v cached_rate="${6:-0}" \
      -v cache_creation_rate="${7:-0}" \
      -v output_rate="${8:-0}" \
      'BEGIN {
        cost = ((in_tok * input_rate) + (cached_tok * cached_rate) + (cache_creation_tok * cache_creation_rate) + (out_tok * output_rate)) / 1000000
        printf "%.2f\n", cost
      }'
}

claude_session_cost() {
  local transcript_path="${1:-}"
  local totals

  if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ] || ! command -v jq >/dev/null 2>&1; then
    printf '?\n'
    return
  fi

  totals=$(jq -s -r '
    reduce (.[] | select(.type == "assistant") | .message.usage // empty) as $u
      ({input: 0, output: 0, cache_read: 0, cache_creation: 0};
       .input += ($u.input_tokens // 0) |
       .output += ($u.output_tokens // 0) |
       .cache_read += ($u.cache_read_input_tokens // 0) |
       .cache_creation += ($u.cache_creation_input_tokens // 0))
    | [.input, .cache_read, .cache_creation, .output] | @tsv
  ' "$transcript_path" 2>/dev/null) || totals=""

  if [ -z "$totals" ]; then
    printf '?\n'
    return
  fi

  local input cache_read cache_creation output
  IFS=$'\t' read -r input cache_read cache_creation output <<< "$totals"
  cost_from_tokens "$input" "$cache_read" "$cache_creation" "$output" 3.00 0.30 3.75 15.00
}

codex_session_cost() {
  local rollout line usage

  if ! command -v jq >/dev/null 2>&1; then
    printf '?\n'
    return
  fi

  rollout=$(ls -1t "$HOME"/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -1 || true)
  if [ -z "$rollout" ] || [ ! -f "$rollout" ]; then
    printf '?\n'
    return
  fi

  line=$(grep '"type":"token_count"' "$rollout" 2>/dev/null | tail -1 || true)
  if [ -z "$line" ]; then
    printf '?\n'
    return
  fi

  usage=$(printf '%s\n' "$line" | jq -r '
    (.payload.info.total_token_usage //
     .event_msg.payload.info.total_token_usage //
     empty) as $u
    | [($u.input_tokens // 0), ($u.cached_input_tokens // 0), ($u.output_tokens // 0)] | @tsv
  ' 2>/dev/null) || usage=""

  if [ -z "$usage" ]; then
    printf '?\n'
    return
  fi

  local input cached output uncached
  IFS=$'\t' read -r input cached output <<< "$usage"
  uncached=$(( input - cached ))
  (( uncached < 0 )) && uncached=0
  cost_from_tokens "$uncached" "$cached" 0 "$output" 5.00 0.50 0 30.00
}

gemini_session_cost() {
  local gemini_dir="$HOME/.gemini/tmp"
  local today_start latest usage

  if ! command -v jq >/dev/null 2>&1 || [ ! -d "$gemini_dir" ]; then
    printf '0.00\n'
    return
  fi

  today_start=$(date -j -f '%Y-%m-%d %H:%M:%S' "$(date +%F) 00:00:00" '+%s' 2>/dev/null \
             || date -d "$(date +%F) 00:00:00" '+%s' 2>/dev/null \
             || printf '0')

  latest=$(
    find "$gemini_dir" -type f -path '*/chats/session-*.json' -print0 2>/dev/null |
      while IFS= read -r -d '' f; do
        mtime=$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f" 2>/dev/null || printf '0')
        [ "$mtime" -ge "$today_start" ] || continue
        printf '%s\t%s\n' "$mtime" "$f"
      done |
      sort -rn |
      awk 'NR == 1 { sub(/^[^\t]*\t/, ""); print }'
  )

  if [ -z "$latest" ] || [ ! -f "$latest" ]; then
    printf '0.00\n'
    return
  fi

  usage=$(jq -r '
    reduce (.messages[]? | select(.type == "gemini") | .tokens // empty) as $t
      ({input: 0, output: 0, cached: 0};
       .input += ($t.input // 0) |
       .output += ($t.output // 0) |
       .cached += ($t.cached // 0))
    | [.input, .cached, .output] | @tsv
  ' "$latest" 2>/dev/null) || usage=""

  if [ -z "$usage" ]; then
    printf '0.00\n'
    return
  fi

  local input cached output uncached
  IFS=$'\t' read -r input cached output <<< "$usage"
  uncached=$(( input - cached ))
  (( uncached < 0 )) && uncached=0
  cost_from_tokens "$uncached" "$cached" 0 "$output" 0.10 0.01 0 0.40
}
