#!/usr/bin/env bash
# Computes Claude Code rolling-window usage.
# Prints TSV: session_msgs <tab> weekly_msgs <tab> session_in <tab> session_out <tab> weekly_in <tab> weekly_out

claude_window_stats() {
  local now cutoff_5h cutoff_7d
  now=$(date +%s)
  cutoff_5h=$(( now - 5  * 3600  ))
  cutoff_7d=$(( now - 7  * 86400 ))

  local s_msgs=0 w_msgs=0 s_in=0 s_out=0 w_in=0 w_out=0
  local f ts it ot cr cw ts_clean epoch

  for f in "$HOME"/.claude/projects/*/*.jsonl; do
    [ -f "$f" ] || continue
    while IFS=$'\t' read -r ts it ot cr cw; do
      [ -z "$ts" ] && continue
      ts_clean="${ts%.*}"
      epoch=$(date -j -u -f '%Y-%m-%dT%H:%M:%S' "$ts_clean" '+%s' 2>/dev/null) || continue
      (( epoch < cutoff_7d )) && continue
      (( w_msgs++ )) || true
      (( w_in  += it + cr + cw )) || true
      (( w_out += ot )) || true
      if (( epoch >= cutoff_5h )); then
        (( s_msgs++ )) || true
        (( s_in  += it + cr + cw )) || true
        (( s_out += ot )) || true
      fi
    done < <(
      jq -r 'select(.type=="assistant") |
             [.timestamp,
              (.message.usage.input_tokens              //0),
              (.message.usage.output_tokens             //0),
              (.message.usage.cache_read_input_tokens   //0),
              (.message.usage.cache_creation_input_tokens//0)] | @tsv' \
        "$f" 2>/dev/null
    )
  done

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$s_msgs" "$w_msgs" "$s_in" "$s_out" "$w_in" "$w_out"
}
