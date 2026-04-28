#!/bin/bash
set -e

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

ensure_json_file() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  if [ ! -f "$file" ]; then
    printf '{}\n' > "$file"
  fi
}

set_claude_settings() {
  local file="$1"
  local status_cmd="$2"
  local guard_cmd="$3"

  ensure_json_file "$file"
  node -e '
const fs = require("fs");
const [file, statusCmd, guardCmd] = process.argv.slice(1);
let data = {};
try { data = JSON.parse(fs.readFileSync(file, "utf8")); } catch {}
data.statusLine = { type: "command", command: statusCmd };
data.model = "sonnet";
data.hooks = data.hooks && typeof data.hooks === "object" ? data.hooks : {};
data.hooks.PreToolUse = [{
  matcher: "Edit|Write|NotebookEdit",
  hooks: [{ type: "command", command: guardCmd }]
}];
fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
' "$file" "$status_cmd" "$guard_cmd"
}

set_gemini_settings() {
  local file="$1"

  ensure_json_file "$file"
  node -e '
const fs = require("fs");
const [file] = process.argv.slice(1);
let data = {};
try { data = JSON.parse(fs.readFileSync(file, "utf8")); } catch {}
data.model = { name: "gemini-2.5-flash-lite" };
fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
' "$file"
}

set_toml_root_key() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp

  tmp=$(mktemp)
  awk -v key="$key" -v value="$value" '
    BEGIN { done = 0; in_root = 1 }
    in_root && $1 == key && $2 == "=" {
      if (!done) {
        print key " = \"" value "\""
        done = 1
      }
      next
    }
    /^\[/ {
      if (!done) {
        print key " = \"" value "\""
        done = 1
      }
      in_root = 0
    }
    { print }
    END {
      if (!done) {
        print key " = \"" value "\""
      }
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

echo "🪙 frugal-harness installer"
echo ""

# Prerequisites check
echo "Checking prerequisites..."

MISSING=0
CLI_MISSING=0

if ! command -v node &> /dev/null; then
  echo "  ✗ Node.js not found → install Node.js first"
  MISSING=1
else
  echo "  ✓ Node.js ($(node --version 2>/dev/null || echo unknown))"
fi

if ! command -v npm &> /dev/null; then
  echo "  ✗ npm not found → install Node.js with npm first"
  MISSING=1
else
  echo "  ✓ npm ($(npm --version 2>/dev/null || echo unknown))"
fi

if [ $MISSING -eq 1 ]; then
  echo ""
  echo "⚠ Install Node.js/npm first, then re-run this script."
  echo "   macOS: https://nodejs.org/ or brew install node"
  echo "   Linux/WSL: use your distro package manager, nvm, or https://nodejs.org/"
  exit 1
fi

if ! command -v claude &> /dev/null; then
  echo "  ✗ Claude Code not found"
  CLI_MISSING=1
else
  echo "  ✓ Claude Code"
fi

if ! command -v codex &> /dev/null; then
  echo "  ✗ Codex CLI not found"
  CLI_MISSING=1
else
  echo "  ✓ Codex CLI"
fi

if ! command -v gemini &> /dev/null; then
  echo "  ✗ Gemini CLI not found"
  CLI_MISSING=1
else
  echo "  ✓ Gemini CLI"
fi

if [ $CLI_MISSING -eq 1 ] && [ "${FRUGAL_SKIP_CLI_INSTALL:-0}" != "1" ]; then
  echo ""
  echo "Installing missing CLIs using official install paths..."

  if ! command -v claude &> /dev/null; then
    echo "  → Installing Claude Code via official native installer"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  if ! command -v codex &> /dev/null; then
    echo "  → Installing Codex CLI via npm"
    npm install -g @openai/codex
  fi

  if ! command -v gemini &> /dev/null; then
    echo "  → Installing Gemini CLI via npm"
    npm install -g @google/gemini-cli
  fi
elif [ $CLI_MISSING -eq 1 ]; then
  echo ""
  echo "⚠ CLI auto-install skipped because FRUGAL_SKIP_CLI_INSTALL=1."
  echo "   Install missing tools manually, then re-run this script."
  exit 1
fi

echo ""
echo "All prerequisites met. Installing..."

REPO_RAW="https://raw.githubusercontent.com/DevSonny/frugal-harness/main"
SKILLS_DIR="$HOME/.claude/skills"
SHARED_DIR="$HOME/.claude/shared"
CLAUDE_SCRIPTS_DIR="$HOME/.claude/scripts"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
CODEX_AGENTS="$HOME/.codex/AGENTS.md"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# Backup existing files
if [ -f "$CLAUDE_MD" ]; then
  cp "$CLAUDE_MD" "${CLAUDE_MD}${BACKUP_SUFFIX}"
  echo "  ↩ Backed up existing CLAUDE.md"
fi

if [ -f "$CODEX_AGENTS" ]; then
  cp "$CODEX_AGENTS" "${CODEX_AGENTS}${BACKUP_SUFFIX}"
  echo "  ↩ Backed up existing AGENTS.md"
fi

# Create Claude runtime dirs
mkdir -p "$SKILLS_DIR" "$SHARED_DIR" "$CLAUDE_SCRIPTS_DIR"

# Download CLAUDE.md
curl -fsSL "$REPO_RAW/CLAUDE.md" -o "$CLAUDE_MD"

# Download shared harness files
for shared_name in harness-core codex-wrapper; do
  local_path="$SHARED_DIR/${shared_name}.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  curl -fsSL "$REPO_RAW/shared/${shared_name}.md" -o "$local_path"
done

# Download Claude-side sync script for Codex AGENTS.md
SYNC_SCRIPT="$CLAUDE_SCRIPTS_DIR/sync-agents.sh"
if [ -f "$SYNC_SCRIPT" ]; then
  cp "$SYNC_SCRIPT" "${SYNC_SCRIPT}${BACKUP_SUFFIX}"
fi
curl -fsSL "$REPO_RAW/scripts/sync-agents.sh" -o "$SYNC_SCRIPT"
chmod +x "$SYNC_SCRIPT"

# Download skill files
SKILLS=(plan exec docs review ship)
for skill_name in "${SKILLS[@]}"; do
  local_path="$SKILLS_DIR/${skill_name}.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  curl -fsSL "$REPO_RAW/skills/${skill_name}.md" -o "$local_path"
done

# Register skills as Claude Code slash commands
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"
for skill_name in "${SKILLS[@]}"; do
  cp "$SKILLS_DIR/${skill_name}.md" "$COMMANDS_DIR/${skill_name}.md"
done
echo "  ✓ Slash commands registered → $COMMANDS_DIR"

# Install usage scripts
SCRIPTS_DIR="$HOME/.local/share/frugal-harness/scripts"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR" "$BIN_DIR"
for s in usage.sh usage.js usage-statusline.sh guard-code-edit.sh; do
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
fi
set_claude_settings "$CLAUDE_SETTINGS" \
  "bash $SCRIPTS_DIR/usage-statusline.sh" \
  "bash $SCRIPTS_DIR/guard-code-edit.sh"
echo "  ✓ Claude Code model: sonnet (Opus recommended only for complex plans)"
echo "  ✓ PreToolUse hook installed: guard-code-edit.sh"

# Pin Codex defaults
CODEX_CONFIG="$HOME/.codex/config.toml"
mkdir -p "$HOME/.codex"
if [ -f "$CODEX_CONFIG" ]; then
  cp "$CODEX_CONFIG" "${CODEX_CONFIG}${BACKUP_SUFFIX}"
else
  : > "$CODEX_CONFIG"
fi
set_toml_root_key "$CODEX_CONFIG" "model" "gpt-5.5"
set_toml_root_key "$CODEX_CONFIG" "model_reasoning_effort" "medium"
set_toml_root_key "$CODEX_CONFIG" "plan_mode_reasoning_effort" "high"
echo "  ✓ Codex default model: gpt-5.5 (plan high, implementation medium)"

# Build Codex standalone harness
"$SYNC_SCRIPT"
echo "  ✓ Codex AGENTS.md generated"

# Pin Gemini default model to gemini-2.5-flash-lite (cheapest)
GEMINI_SETTINGS="$HOME/.gemini/settings.json"
mkdir -p "$HOME/.gemini"
if [ -f "$GEMINI_SETTINGS" ]; then
  cp "$GEMINI_SETTINGS" "${GEMINI_SETTINGS}${BACKUP_SUFFIX}"
fi
set_gemini_settings "$GEMINI_SETTINGS"
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
echo "Agents & models:"
echo "  /plan    → Claude Code  sonnet               (recommend Opus only for complex plans)"
echo "  /exec    → Codex CLI    gpt-5.5              (build, medium effort)"
echo "  /review  → Codex CLI    gpt-5.5              (review, medium effort)"
echo "  /docs    → Gemini CLI   gemini-2.5-flash-lite (free — docs)"
echo "  /ship    → Codex CLI    gpt-5.5              (commit & push, medium effort)"
echo ""
echo "Total cost: ~\$40/mo (Claude Pro + ChatGPT Plus)"
echo "Gemini CLI: free"
