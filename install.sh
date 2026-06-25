#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

  ensure_json_file "$file"
  node -e '
const fs = require("fs");
const [file, statusCmd] = process.argv.slice(1);
let data = {};
try { data = JSON.parse(fs.readFileSync(file, "utf8")); } catch {}
data.statusLine = { type: "command", command: statusCmd };
data.model = "sonnet";
// Remove legacy guard hook if present from prior installs
if (data.hooks && data.hooks.PreToolUse) {
  delete data.hooks.PreToolUse;
  if (Object.keys(data.hooks).length === 0) delete data.hooks;
}
fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
' "$file" "$status_cmd"
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

# Agent selection
echo ""
if [ -n "${FRUGAL_AGENT:-}" ]; then
  agent_choice="$FRUGAL_AGENT"
else
  echo "Which implementation agent(s) do you want to use?"
  echo "  1) Codex only"
  echo "  2) agy only"
  echo "  3) Both (Codex + agy)"
  printf "Choice [1]: "
  read -r agent_choice
  agent_choice="${agent_choice:-1}"
fi

case "$agent_choice" in
  1|codex) INSTALL_CODEX=1; INSTALL_AGY=0 ;;
  2|agy)   INSTALL_CODEX=0; INSTALL_AGY=1 ;;
  3|both)  INSTALL_CODEX=1; INSTALL_AGY=1 ;;
  *)       echo "Invalid choice, defaulting to Codex only."; INSTALL_CODEX=1; INSTALL_AGY=0 ;;
esac

echo ""
echo "Checking CLIs..."

CLI_MISSING=0

if ! command -v claude &> /dev/null; then
  echo "  ✗ Claude Code not found"
  CLI_MISSING=1
else
  echo "  ✓ Claude Code"
fi

if [ "$INSTALL_CODEX" = "1" ]; then
  if ! command -v codex &> /dev/null; then
    echo "  ✗ Codex CLI not found"
    CLI_MISSING=1
  else
    echo "  ✓ Codex CLI"
  fi
fi

if [ "$INSTALL_AGY" = "1" ]; then
  if ! command -v agy &> /dev/null; then
    echo "  ✗ agy not found"
    CLI_MISSING=1
  else
    echo "  ✓ agy"
  fi
fi

if [ $CLI_MISSING -eq 1 ] && [ "${FRUGAL_SKIP_CLI_INSTALL:-0}" != "1" ]; then
  echo ""
  echo "Installing missing CLIs using official install paths..."

  if ! command -v claude &> /dev/null; then
    echo "  → Installing Claude Code via official native installer"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  if [ "$INSTALL_CODEX" = "1" ] && ! command -v codex &> /dev/null; then
    echo "  → Installing Codex CLI via npm"
    npm install -g @openai/codex
  fi

  if [ "$INSTALL_AGY" = "1" ] && ! command -v agy &> /dev/null; then
    echo "  → Installing agy via official installer"
    curl -fsSL https://antigravity.google/cli/install.sh | bash
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
AGY_AGENTS="$HOME/.gemini/config/AGENTS.md"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# Backup existing files
if [ -f "$CLAUDE_MD" ]; then
  cp "$CLAUDE_MD" "${CLAUDE_MD}${BACKUP_SUFFIX}"
  echo "  ↩ Backed up existing CLAUDE.md"
fi

if [ "$INSTALL_CODEX" = "1" ] && [ -f "$CODEX_AGENTS" ]; then
  cp "$CODEX_AGENTS" "${CODEX_AGENTS}${BACKUP_SUFFIX}"
  echo "  ↩ Backed up existing AGENTS.md"
fi

if [ "$INSTALL_AGY" = "1" ] && [ -f "$AGY_AGENTS" ]; then
  cp "$AGY_AGENTS" "${AGY_AGENTS}${BACKUP_SUFFIX}"
  echo "  ↩ Backed up existing AGENTS.md (agy)"
fi

# Create Claude runtime dirs
mkdir -p "$SKILLS_DIR" "$SHARED_DIR" "$CLAUDE_SCRIPTS_DIR"

# Download CLAUDE.md
curl -fsSL "$REPO_RAW/CLAUDE.md" -o "$CLAUDE_MD"

# Download shared harness files
for shared_name in harness-core; do
  local_path="$SHARED_DIR/${shared_name}.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  curl -fsSL "$REPO_RAW/shared/${shared_name}.md" -o "$local_path"
done

if [ "$INSTALL_CODEX" = "1" ]; then
  local_path="$SHARED_DIR/codex-wrapper.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  if [ -f "$SCRIPT_DIR/shared/codex-wrapper.md" ]; then
    cp "$SCRIPT_DIR/shared/codex-wrapper.md" "$local_path"
  else
    curl -fsSL "$REPO_RAW/shared/codex-wrapper.md" -o "$local_path"
  fi
fi

if [ "$INSTALL_AGY" = "1" ]; then
  local_path="$SHARED_DIR/agy-wrapper.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  if [ -f "$SCRIPT_DIR/shared/agy-wrapper.md" ]; then
    cp "$SCRIPT_DIR/shared/agy-wrapper.md" "$local_path"
  else
    curl -fsSL "$REPO_RAW/shared/agy-wrapper.md" -o "$local_path"
  fi
fi

# Download Claude-side sync script for Codex AGENTS.md
SYNC_SCRIPT="$CLAUDE_SCRIPTS_DIR/sync-agents.sh"
if [ -f "$SYNC_SCRIPT" ]; then
  cp "$SYNC_SCRIPT" "${SYNC_SCRIPT}${BACKUP_SUFFIX}"
fi
if [ -f "$SCRIPT_DIR/scripts/sync-agents.sh" ]; then
  cp "$SCRIPT_DIR/scripts/sync-agents.sh" "$SYNC_SCRIPT"
else
  curl -fsSL "$REPO_RAW/scripts/sync-agents.sh" -o "$SYNC_SCRIPT"
fi
chmod +x "$SYNC_SCRIPT"

# Install usage scripts (guard-code-edit.sh is intentionally excluded)
SCRIPTS_DIR="$HOME/.local/share/frugal-harness/scripts"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR" "$BIN_DIR"
for s in usage.sh usage.js usage-statusline.sh; do
  if [ -f "$SCRIPT_DIR/scripts/$s" ]; then
    cp "$SCRIPT_DIR/scripts/$s" "$SCRIPTS_DIR/$s"
  else
    curl -fsSL "$REPO_RAW/scripts/$s" -o "$SCRIPTS_DIR/$s"
  fi
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

# Configure Claude Code settings (no guard hook)
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
if [ -f "$CLAUDE_SETTINGS" ]; then
  cp "$CLAUDE_SETTINGS" "${CLAUDE_SETTINGS}${BACKUP_SUFFIX}"
fi
set_claude_settings "$CLAUDE_SETTINGS" \
  "bash $SCRIPTS_DIR/usage-statusline.sh"
echo "  ✓ Claude Code model: sonnet (Opus recommended only for complex plans)"

# Pin Codex defaults
if [ "$INSTALL_CODEX" = "1" ]; then
  CODEX_CONFIG="$HOME/.codex/config.toml"
  mkdir -p "$HOME/.codex"
  if [ -f "$CODEX_CONFIG" ]; then
    cp "$CODEX_CONFIG" "${CODEX_CONFIG}${BACKUP_SUFFIX}"
  else
    : > "$CODEX_CONFIG"
  fi
  set_toml_root_key "$CODEX_CONFIG" "model" "gpt-5.5"
  set_toml_root_key "$CODEX_CONFIG" "model_reasoning_effort" "medium"
  set_toml_root_key "$CODEX_CONFIG" "plan_mode_reasoning_effort" "medium"
  echo "  ✓ Codex default model: gpt-5.5 (plan medium, implementation medium)"

fi

# Build standalone harnesses
"$SYNC_SCRIPT"
if [ "$INSTALL_CODEX" = "1" ]; then
  echo "  ✓ Codex AGENTS.md generated"
fi
if [ "$INSTALL_AGY" = "1" ]; then
  echo "  ✓ agy AGENTS.md generated"
fi


echo "✅ frugal-harness installed!"
echo ""
echo ""
echo "Agents & models:"
echo "  /plan    → Claude Code  sonnet               (recommend Opus only for complex plans)"
if [ "$INSTALL_CODEX" = "1" ]; then
  echo "  /exec    → Codex CLI    gpt-5.5              (build, medium effort)"
  echo "  /review  → Codex CLI    gpt-5.5              (review, medium effort)"
  echo "  /ship    → Codex CLI    gpt-5.5              (commit & push, medium effort)"
fi
if [ "$INSTALL_AGY" = "1" ]; then
  echo "  /exec    → agy                               (antigravity CLI, build)"
  echo "  /review  → agy                               (antigravity CLI, review)"
  echo "  /ship    → agy                               (antigravity CLI, commit & push)"
fi
echo "  /docs    → Gemini CLI   (not configured)"
echo ""
if [ "$INSTALL_CODEX" = "1" ] && [ "$INSTALL_AGY" = "1" ]; then
  echo "Total cost: ~\$40/mo (Claude Pro + ChatGPT Plus) + agy subscription"
elif [ "$INSTALL_CODEX" = "1" ]; then
  echo "Total cost: ~\$40/mo (Claude Pro + ChatGPT Plus)"
elif [ "$INSTALL_AGY" = "1" ]; then
  echo "Total cost: ~\$20/mo (Claude Pro) + agy subscription"
fi
