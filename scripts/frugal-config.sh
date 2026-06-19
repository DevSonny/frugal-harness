#!/usr/bin/env bash
set -euo pipefail

# Interactive configuration for frugal-harness. Asks which worker agents you
# subscribe to and the per-role delegation priority, writes the JSON profile,
# and regenerates the delegation profile + Codex harness. Run it directly in a
# terminal (it uses plain `read`). Kept compatible with bash 3.2 (macOS).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER="$SCRIPT_DIR/render-profile.sh"
[ -x "$RENDER" ] || RENDER="$HOME/.local/share/frugal-harness/scripts/render-profile.sh"
PROFILE="$HOME/.config/frugal/profile.json"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required." >&2
  exit 1
fi

echo "🪙 frugal config — agent subscription & delegation priority"
echo ""
echo "Plan is always handled by Claude. You choose which worker agents handle"
echo "implementation, review, docs, and ship, and in what order."
echo ""

ask_yes_no() {
  # $1 prompt, $2 default (y/n)
  local prompt="$1" def="$2" ans
  read -r -p "$prompt " ans || ans=""
  ans="${ans:-$def}"
  case "$ans" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

SUBS=()

# Detect + confirm Antigravity
if command -v agy >/dev/null 2>&1; then
  ask_yes_no "Subscribe to Antigravity (agy)? [Y/n]" "y" && SUBS+=(antigravity)
else
  echo "  (Antigravity CLI 'agy' not found — skipping)"
fi

# Detect + confirm Codex
if command -v codex >/dev/null 2>&1; then
  ask_yes_no "Subscribe to Codex? [Y/n]" "y" && SUBS+=(codex)
else
  echo "  (Codex CLI 'codex' not found — skipping)"
fi

if [ ${#SUBS[@]} -eq 0 ]; then
  echo ""
  echo "⚠ No worker agents selected. Plan stays on Claude; nothing to delegate to."
fi

# is_sub <agent> — true if the agent is subscribed
is_sub() {
  local a
  for a in "${SUBS[@]:-}"; do [ "$a" = "$1" ] && return 0; done
  return 1
}

# order_by <pref...> — echo the subscribed agents in the given preference order
order_by() {
  local a out=""
  for a in "$@"; do
    if is_sub "$a"; then out="$out $a"; fi
  done
  echo "${out# }"
}

DEFAULT_ORDER="$(order_by antigravity codex)"
SHIP_DEFAULT="$(order_by codex antigravity)"

# Per-role priority stored in plain variables (bash 3.2 has no assoc arrays)
ROLE_exec=""; ROLE_review=""; ROLE_docs=""; ROLE_ship=""

if [ ${#SUBS[@]} -le 1 ]; then
  ROLE_exec="$DEFAULT_ORDER"; ROLE_review="$DEFAULT_ORDER"
  ROLE_docs="$DEFAULT_ORDER"; ROLE_ship="$DEFAULT_ORDER"
else
  echo ""
  echo "Set priority per role. Enter a comma-separated order from: $DEFAULT_ORDER"
  echo "(press Enter to accept the shown default)"
  for r in exec review docs ship; do
    if [ "$r" = "ship" ]; then def="$SHIP_DEFAULT"; else def="$DEFAULT_ORDER"; fi
    def_csv="${def// /,}"
    read -r -p "  $r priority [$def_csv]: " ans || ans=""
    ans="${ans:-$def_csv}"
    ans="${ans//,/ }"
    chosen=""
    for tok in $ans; do
      if is_sub "$tok"; then chosen="$chosen $tok"; fi
    done
    chosen="${chosen# }"
    [ -n "$chosen" ] || chosen="$def"
    case "$r" in
      exec) ROLE_exec="$chosen" ;;
      review) ROLE_review="$chosen" ;;
      docs) ROLE_docs="$chosen" ;;
      ship) ROLE_ship="$chosen" ;;
    esac
  done
fi

# Build profile.json via node for safe JSON
mkdir -p "$(dirname "$PROFILE")"
SUBS_CSV="${SUBS[*]:-}"; SUBS_CSV="${SUBS_CSV// /,}"
node -e '
const fs = require("fs");
const [out, subsCsv, exec_, review_, docs_, ship_] = process.argv.slice(1);
const toList = (s) => (s || "").split(/[ ,]+/).filter(Boolean);
const profile = {
  agents: toList(subsCsv),
  roles: {
    plan: ["claude"],
    exec: toList(exec_),
    review: toList(review_),
    docs: toList(docs_),
    ship: toList(ship_),
  },
  routing: "complexity-auto",
};
fs.writeFileSync(out, JSON.stringify(profile, null, 2) + "\n");
' "$PROFILE" "$SUBS_CSV" "$ROLE_exec" "$ROLE_review" "$ROLE_docs" "$ROLE_ship"

echo ""
echo "Wrote $PROFILE"

if [ -x "$RENDER" ]; then
  "$RENDER"
else
  echo "⚠ render-profile.sh not found; profile saved but not applied." >&2
  exit 1
fi

echo ""
echo "✅ Delegation profile updated. Summary:"
echo "  plan   → Claude"
printf '  %-6s → %s\n' "exec" "${ROLE_exec:-(unset)}"
printf '  %-6s → %s\n' "review" "${ROLE_review:-(unset)}"
printf '  %-6s → %s\n' "docs" "${ROLE_docs:-(unset)}"
printf '  %-6s → %s\n' "ship" "${ROLE_ship:-(unset)}"
