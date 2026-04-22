#!/bin/bash
set -e

detect_jq_install_cmd() {
  local id_all

  if [ "$(uname -s)" = "Darwin" ]; then
    echo "brew install jq"
    return
  fi

  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id_all=" ${ID:-} ${ID_LIKE:-} "

    if [[ "$id_all" == *" debian "* ]] || [[ "$id_all" == *" ubuntu "* ]]; then
      echo "sudo apt install jq"
      return
    fi

    if [[ "$id_all" == *" fedora "* ]] || [[ "$id_all" == *" rhel "* ]] || [[ "$id_all" == *" centos "* ]]; then
      echo "sudo dnf install jq"
      return
    fi

    if [[ "$id_all" == *" arch "* ]]; then
      echo "sudo pacman -S jq"
      return
    fi
  fi

  echo "install jq — see https://jqlang.org/download/"
}

detect_shell() {
  case "${SHELL:-}" in
    */zsh)  echo "zsh" ;;
    */bash) echo "bash" ;;
    */fish) echo "fish" ;;
    *)      echo "unknown" ;;
  esac
}

rcfile_for_shell() {
  local shell="$1"
  case "$shell" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash)
      if [[ "${OSTYPE:-}" == darwin* ]]; then echo "$HOME/.bash_profile"
      else echo "$HOME/.bashrc"
      fi ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *)    echo "" ;;
  esac
}

echo "🪙 frugal-harness installer"
echo ""

# Prerequisites check
echo "Checking prerequisites..."

MISSING=0

if ! command -v claude &> /dev/null; then
  echo "  ✗ Claude Code not found → npm install -g @anthropic-ai/claude-code"
  MISSING=1
else
  echo "  ✓ Claude Code"
fi

if ! command -v codex &> /dev/null; then
  echo "  ✗ Codex CLI not found  → npm install -g @openai/codex"
  MISSING=1
else
  echo "  ✓ Codex CLI"
fi

if ! command -v gemini &> /dev/null; then
  echo "  ✗ Gemini CLI not found → npm install -g @google/gemini-cli"
  MISSING=1
else
  echo "  ✓ Gemini CLI"
fi

if ! command -v jq &> /dev/null; then
  echo "  ✗ jq not found        → $(detect_jq_install_cmd)"
  MISSING=1
else
  echo "  ✓ jq"
fi

if [ $MISSING -eq 1 ]; then
  echo ""
  echo "⚠ Install missing tools above, then re-run this script."
  exit 1
fi

echo ""
echo "All prerequisites met. Installing..."

REPO_RAW="https://raw.githubusercontent.com/DevSonny/frugal-harness/main"
SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# Backup existing files
if [ -f "$CLAUDE_MD" ]; then
  cp "$CLAUDE_MD" "${CLAUDE_MD}${BACKUP_SUFFIX}"
  echo "  ↩ Backed up existing CLAUDE.md"
fi

# Create skills dir
mkdir -p "$SKILLS_DIR"

# Download CLAUDE.md
curl -fsSL "$REPO_RAW/CLAUDE.md" -o "$CLAUDE_MD"

# Download skill files
SKILLS=(plan exec docs review ship)
for skill_name in "${SKILLS[@]}"; do
  local_path="$SKILLS_DIR/${skill_name}.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  curl -fsSL "$REPO_RAW/skills/${skill_name}.md" -o "$local_path"
done

# Install usage scripts
SCRIPTS_DIR="$HOME/.local/share/frugal-harness/scripts"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR" "$BIN_DIR"
for s in usage.sh usage-statusline.sh lib-claude-window.sh; do
  curl -fsSL "$REPO_RAW/scripts/$s" -o "$SCRIPTS_DIR/$s"
  chmod +x "$SCRIPTS_DIR/$s"
done
ln -sf "$SCRIPTS_DIR/usage.sh" "$BIN_DIR/usage"
echo "  ✓ usage scripts → $SCRIPTS_DIR"
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
  _rc="$(rcfile_for_shell "$(detect_shell)")"; _sh="$(detect_shell)"
  if [ "$_sh" = "fish" ]; then
    echo "    ⚠ Run: fish_add_path $HOME/.local/bin"
  elif [ -n "$_rc" ]; then
    echo "    ⚠ Add to $_rc: export PATH=\"\$HOME/.local/bin:\$PATH\""
  else
    echo "    ⚠ Add to your shell rc: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

# Configure Claude Code statusline
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
if [ -f "$CLAUDE_SETTINGS" ]; then
  cp "$CLAUDE_SETTINGS" "${CLAUDE_SETTINGS}${BACKUP_SUFFIX}"
  tmp=$(mktemp)
  jq --arg cmd "bash $SCRIPTS_DIR/usage-statusline.sh" \
     '.statusLine = {type: "command", command: $cmd}' \
     "$CLAUDE_SETTINGS" > "$tmp" && mv "$tmp" "$CLAUDE_SETTINGS"
else
  jq -n --arg cmd "bash $SCRIPTS_DIR/usage-statusline.sh" \
     '{statusLine: {type: "command", command: $cmd}}' > "$CLAUDE_SETTINGS"
fi
echo "  ✓ Claude Code statusline configured"

# Pin Gemini default model to gemini-2.5-flash-lite (cheapest)
GEMINI_SETTINGS="$HOME/.gemini/settings.json"
mkdir -p "$HOME/.gemini"
if [ -f "$GEMINI_SETTINGS" ]; then
  cp "$GEMINI_SETTINGS" "${GEMINI_SETTINGS}${BACKUP_SUFFIX}"
  tmp=$(mktemp)
  jq '.model = {name: "gemini-2.5-flash-lite"}' "$GEMINI_SETTINGS" > "$tmp" && mv "$tmp" "$GEMINI_SETTINGS"
else
  jq -n '{model: {name: "gemini-2.5-flash-lite"}}' > "$GEMINI_SETTINGS"
fi
echo "  ✓ Gemini default model: gemini-2.5-flash-lite"

echo "✅ frugal-harness installed!"
echo ""
echo "🔑 API Key Setup (do this manually):"
echo "   Get your key: https://aistudio.google.com/apikey"
echo ""
_detected_shell="$(detect_shell)"
_detected_rc="$(rcfile_for_shell "$_detected_shell")"
case "$_detected_shell" in
  zsh)
    echo "   Detected: zsh"
    echo "   echo 'export GEMINI_API_KEY=\"your_api_key_here\"' >> $_detected_rc"
    echo "   source $_detected_rc"
    ;;
  bash)
    echo "   Detected: bash"
    echo "   echo 'export GEMINI_API_KEY=\"your_api_key_here\"' >> $_detected_rc"
    echo "   source $_detected_rc"
    ;;
  fish)
    echo "   Detected: fish"
    echo "   set -Ux GEMINI_API_KEY \"your_api_key_here\""
    ;;
  *)
    echo "   Could not detect shell (SHELL=${SHELL:-unset}). Choose your config file:"
    echo ""
    echo "   zsh:"
    echo "     echo 'export GEMINI_API_KEY=\"your_api_key_here\"' >> ~/.zshrc && source ~/.zshrc"
    echo "   bash (Linux):"
    echo "     echo 'export GEMINI_API_KEY=\"your_api_key_here\"' >> ~/.bashrc && source ~/.bashrc"
    echo "   bash (macOS):"
    echo "     echo 'export GEMINI_API_KEY=\"your_api_key_here\"' >> ~/.bash_profile && source ~/.bash_profile"
    echo "   fish:"
    echo "     set -Ux GEMINI_API_KEY \"your_api_key_here\""
    ;;
esac
echo ""
echo "   Open a new terminal, then verify:"
echo "     1) [ -n \"\$GEMINI_API_KEY\" ] && echo 'OK: env var set' || echo 'FAIL: not set'"
echo "     2) echo \"Key prefix: \${GEMINI_API_KEY:0:6}...\""
echo "     3) gemini -p 'say hi'   # optional — uses 1 free-tier request"
echo ""
echo "Agents:"
echo "  /plan    → Claude Code (Opus)"
echo "  /exec    → Codex CLI"
echo "  /docs    → Gemini CLI (free)"
echo "  /review  → Claude Code"
echo "  /ship    → Claude Code"
echo ""
echo "Total cost: ~\$40/mo (Claude Pro + ChatGPT Plus)"
echo "Gemini CLI: free"
