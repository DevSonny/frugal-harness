#!/bin/bash
set -e

{

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
if [ -n "${FRUGAL_MAIN:-}" ] && [ -n "${FRUGAL_HELPERS:-}" ]; then
  main_choice="$FRUGAL_MAIN"
  helper_choice="$FRUGAL_HELPERS"
  deploy_choice="${FRUGAL_DEPLOY_CLAUDE:-yes}"
else
  echo "Step 1: Which is your main handler? (The agent you talk to directly)"
  echo "  1) Claude Code"
  echo "  2) agy (Antigravity CLI)"
  echo "  3) Codex CLI"
  printf "Choice [%s]: " "${FRUGAL_MAIN:-1}"
  read -r main_choice < /dev/tty
  main_choice="${main_choice:-${FRUGAL_MAIN:-1}}"

  case "$main_choice" in
    1|claude) FRUGAL_MAIN="claude" ;;
    2|agy)    FRUGAL_MAIN="agy" ;;
    3|codex)  FRUGAL_MAIN="codex" ;;
    *)        echo "Invalid choice. Defaulting to claude."; FRUGAL_MAIN="claude" ;;
  esac

  echo ""
  echo "Step 2: Install helper agents? (for delegation/fallback)"
  if [ "$FRUGAL_MAIN" = "claude" ]; then
    echo "  1) Both Codex and agy"
    echo "  2) Codex only"
    echo "  3) agy only"
    echo "  4) None"
  elif [ "$FRUGAL_MAIN" = "agy" ]; then
    echo "  1) Both Claude and Codex"
    echo "  2) Claude only"
    echo "  3) Codex only"
    echo "  4) None"
  elif [ "$FRUGAL_MAIN" = "codex" ]; then
    echo "  1) Both Claude and agy"
    echo "  2) Claude only"
    echo "  3) agy only"
    echo "  4) None"
  fi
  printf "Choice [1]: "
  read -r helper_choice < /dev/tty
  helper_choice="${helper_choice:-1}"
  
  if [ "$FRUGAL_MAIN" = "claude" ]; then
    case "$helper_choice" in
      1) FRUGAL_HELPERS="codex,agy" ;;
      2) FRUGAL_HELPERS="codex" ;;
      3) FRUGAL_HELPERS="agy" ;;
      4) FRUGAL_HELPERS="none" ;;
      *) FRUGAL_HELPERS="codex,agy" ;;
    esac
  elif [ "$FRUGAL_MAIN" = "agy" ]; then
    case "$helper_choice" in
      1) FRUGAL_HELPERS="claude,codex" ;;
      2) FRUGAL_HELPERS="claude" ;;
      3) FRUGAL_HELPERS="codex" ;;
      4) FRUGAL_HELPERS="none" ;;
      *) FRUGAL_HELPERS="claude,codex" ;;
    esac
  elif [ "$FRUGAL_MAIN" = "codex" ]; then
    case "$helper_choice" in
      1) FRUGAL_HELPERS="claude,agy" ;;
      2) FRUGAL_HELPERS="claude" ;;
      3) FRUGAL_HELPERS="agy" ;;
      4) FRUGAL_HELPERS="none" ;;
      *) FRUGAL_HELPERS="claude,agy" ;;
    esac
  fi

  if [ "$FRUGAL_MAIN" != "claude" ]; then
    echo ""
    echo "Step 3: Deploy CLAUDE.md anyway?"
    echo "  Even though Claude is not your main handler, you can deploy CLAUDE.md"
    echo "  so that if you ever open Claude Code, it knows about your helpers."
    printf "Deploy CLAUDE.md? (y/n) [%s]: " "${FRUGAL_DEPLOY_CLAUDE:-y}"
    read -r deploy_choice < /dev/tty
    deploy_choice="${deploy_choice:-${FRUGAL_DEPLOY_CLAUDE:-y}}"
    case "$deploy_choice" in
      y|Y|yes) FRUGAL_DEPLOY_CLAUDE="yes" ;;
      n|N|no)  FRUGAL_DEPLOY_CLAUDE="no" ;;
      *)       FRUGAL_DEPLOY_CLAUDE="yes" ;;
    esac
  else
    FRUGAL_DEPLOY_CLAUDE="yes"
  fi
fi

# Determine install flags
INSTALL_CODEX=0
INSTALL_AGY=0
INSTALL_CLAUDE=0

if [ "$FRUGAL_MAIN" = "codex" ] || [[ "$FRUGAL_HELPERS" == *"codex"* ]]; then INSTALL_CODEX=1; fi
if [ "$FRUGAL_MAIN" = "agy" ] || [[ "$FRUGAL_HELPERS" == *"agy"* ]]; then INSTALL_AGY=1; fi
if [ "$FRUGAL_MAIN" = "claude" ] || [[ "$FRUGAL_HELPERS" == *"claude"* ]]; then INSTALL_CLAUDE=1; fi

# Save configuration
CONFIG_FILE="$HOME/.frugal-harness/config.sh"
mkdir -p "$HOME/.frugal-harness"
echo "FRUGAL_MAIN=$FRUGAL_MAIN" > "$CONFIG_FILE"
echo "FRUGAL_HELPERS=$FRUGAL_HELPERS" >> "$CONFIG_FILE"
echo "FRUGAL_DEPLOY_CLAUDE=$FRUGAL_DEPLOY_CLAUDE" >> "$CONFIG_FILE"


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
  for wrapper_type in "main" "helper"; do
    local_path="$SHARED_DIR/codex-wrapper-${wrapper_type}.md"
    if [ -f "$local_path" ]; then
      cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
    fi
    if [ -f "$SCRIPT_DIR/shared/codex-wrapper-${wrapper_type}.md" ]; then
      cp "$SCRIPT_DIR/shared/codex-wrapper-${wrapper_type}.md" "$local_path"
    else
      curl -fsSL "$REPO_RAW/shared/codex-wrapper-${wrapper_type}.md" -o "$local_path"
    fi
  done
fi

if [ "$INSTALL_AGY" = "1" ]; then
  for wrapper_type in "main" "helper"; do
    local_path="$SHARED_DIR/agy-wrapper-${wrapper_type}.md"
    if [ -f "$local_path" ]; then
      cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
    fi
    if [ -f "$SCRIPT_DIR/shared/agy-wrapper-${wrapper_type}.md" ]; then
      cp "$SCRIPT_DIR/shared/agy-wrapper-${wrapper_type}.md" "$local_path"
    else
      curl -fsSL "$REPO_RAW/shared/agy-wrapper-${wrapper_type}.md" -o "$local_path"
    fi
  done
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

# Install usage scripts and config utility (guard-code-edit.sh is intentionally excluded)
SCRIPTS_DIR="$HOME/.local/share/frugal-harness/scripts"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR" "$BIN_DIR"
for s in usage.sh usage.js usage-statusline.sh frugal-config.sh; do
  if [ -f "$SCRIPT_DIR/scripts/$s" ]; then
    cp "$SCRIPT_DIR/scripts/$s" "$SCRIPTS_DIR/$s"
  else
    curl -fsSL "$REPO_RAW/scripts/$s" -o "$SCRIPTS_DIR/$s"
  fi
  chmod +x "$SCRIPTS_DIR/$s"
done
ln -sf "$SCRIPTS_DIR/usage.sh" "$BIN_DIR/usage"
ln -sf "$SCRIPTS_DIR/frugal-config.sh" "$BIN_DIR/frugal-config"
echo "  ✓ usage and config scripts → $SCRIPTS_DIR"
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


# Optional Claude Code skills
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Optional Claude Code Skills"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ★ caveman  (STRONGLY RECOMMENDED)"
echo "    Cuts token usage up to 75% with no loss of technical accuracy."
echo "    Claude speaks terse caveman-style — same substance, much less output."
echo ""
echo "  · superpowers"
echo "    Adds powerful new slash commands and capabilities to Claude Code."
echo "    Installs the superpowers plugin via claude plugin marketplace."
echo ""

if [ "${FRUGAL_INSTALL_CAVEMAN:-}" = "1" ]; then
  _install_caveman=y
elif [ "${FRUGAL_INSTALL_CAVEMAN:-}" = "0" ]; then
  _install_caveman=n
else
  printf "Install caveman? [Y/n] "
  read -r _install_caveman < /dev/tty || true
  _install_caveman="${_install_caveman:-y}"
fi

if [[ "$_install_caveman" =~ ^[Yy]$ ]]; then
  if ! command -v claude &>/dev/null; then
    echo "  ✗ caveman: claude CLI not found — skipping"
  else
    echo "  → Installing caveman plugin..."
    if claude plugin install caveman 2>&1; then
      echo "  ✓ caveman installed"
    else
      echo "  ✗ caveman install failed — run manually: claude plugin install caveman"
    fi
  fi

  if [ "$INSTALL_CODEX" = "1" ]; then
    CAVEMAN_JS="$HOME/.claude/plugins/marketplaces/caveman/bin/install.js"
    if [ -f "$CAVEMAN_JS" ]; then
      if node "$CAVEMAN_JS" --only codex >/dev/null 2>&1; then
        echo "  ✓ caveman → Codex"
      else
        echo "  ✗ caveman → Codex 실패"
      fi
    else
      if npx -y github:JuliusBrussee/caveman -- --only codex >/dev/null 2>&1; then
        echo "  ✓ caveman → Codex"
      else
        echo "  ✗ caveman → Codex 실패"
      fi
    fi
  fi

  if [ "$INSTALL_AGY" = "1" ]; then
    CAVEMAN_JS="$HOME/.claude/plugins/marketplaces/caveman/bin/install.js"
    if [ -f "$CAVEMAN_JS" ]; then
      if node "$CAVEMAN_JS" --only antigravity --force >/dev/null 2>&1; then
        echo "  ✓ caveman → agy"
      else
        echo "  ✗ caveman → agy 실패"
      fi
    else
      if npx -y github:JuliusBrussee/caveman -- --only antigravity --force >/dev/null 2>&1; then
        echo "  ✓ caveman → agy"
      else
        echo "  ✗ caveman → agy 실패"
      fi
    fi
  fi
else
  echo "  · caveman skipped"
fi

echo ""

if [ "${FRUGAL_INSTALL_SUPERPOWERS:-}" = "1" ]; then
  _install_superpowers=y
elif [ "${FRUGAL_INSTALL_SUPERPOWERS:-}" = "0" ]; then
  _install_superpowers=n
else
  printf "Install superpowers? [Y/n] "
  read -r _install_superpowers < /dev/tty || true
  _install_superpowers="${_install_superpowers:-y}"
fi

if [[ "$_install_superpowers" =~ ^[Yy]$ ]]; then
  if ! command -v claude &>/dev/null; then
    echo "  ✗ superpowers: claude CLI not found — skipping"
  else
    echo "  → Installing superpowers plugin..."
    if claude plugin install superpowers 2>&1; then
      echo "  ✓ superpowers installed"
    else
      echo "  ✗ superpowers install failed — run manually: claude plugin install superpowers"
    fi
  fi
else
  echo "  · superpowers skipped"
fi

echo ""
echo "✅ frugal-harness installed!"
echo ""
echo ""
echo "Configured Agents:"
echo "  Main handler → $FRUGAL_MAIN"
echo "  Helpers      → $FRUGAL_HELPERS"
echo ""

# Cost estimation
if [ "$FRUGAL_MAIN" = "claude" ]; then
  if [[ "$FRUGAL_HELPERS" == *"codex"* ]] && [[ "$FRUGAL_HELPERS" == *"agy"* ]]; then
    echo "Total cost: ~\$60/mo"
  elif [[ "$FRUGAL_HELPERS" == *"codex"* ]] || [[ "$FRUGAL_HELPERS" == *"agy"* ]]; then
    echo "Total cost: ~\$40/mo"
  else
    echo "Total cost: ~\$20/mo"
  fi
elif [ "$FRUGAL_MAIN" = "agy" ] || [ "$FRUGAL_MAIN" = "codex" ]; then
  if [[ "$FRUGAL_HELPERS" == *"claude"* ]]; then
    echo "Total cost: ~\$40/mo"
  else
    echo "Total cost: ~\$20/mo"
  fi
fi

}
