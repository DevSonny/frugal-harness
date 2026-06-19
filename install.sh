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

if ! command -v agy &> /dev/null; then
  echo "  ✗ Antigravity CLI not found"
  CLI_MISSING=1
else
  echo "  ✓ Antigravity CLI"
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

  if ! command -v agy &> /dev/null; then
    echo "  → Installing Antigravity CLI via native installer"
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

# Local override for testing: FRUGAL_LOCAL=/path/to/repo bash install.sh
# When set, copy from the local repo instead of curling from GitHub.
fetch_file() {
  local rel="$1" dest="$2"
  if [ -n "${FRUGAL_LOCAL:-}" ]; then
    cp "$FRUGAL_LOCAL/$rel" "$dest"
  else
    curl -fsSL "$REPO_RAW/$rel" -o "$dest"
  fi
}
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
mkdir -p "$SHARED_DIR" "$CLAUDE_SCRIPTS_DIR"

# Download CLAUDE.md
fetch_file "CLAUDE.md" "$CLAUDE_MD"

# Download shared harness files
for shared_name in harness-core codex-wrapper delegation-profile; do
  local_path="$SHARED_DIR/${shared_name}.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
  fi
  fetch_file "shared/${shared_name}.md" "$local_path"
done

# Download Claude-side sync script for Codex AGENTS.md
SYNC_SCRIPT="$CLAUDE_SCRIPTS_DIR/sync-agents.sh"
if [ -f "$SYNC_SCRIPT" ]; then
  cp "$SYNC_SCRIPT" "${SYNC_SCRIPT}${BACKUP_SUFFIX}"
fi
fetch_file "scripts/sync-agents.sh" "$SYNC_SCRIPT"
chmod +x "$SYNC_SCRIPT"

# Remove legacy slash commands — the harness is natural-language only now
LEGACY_SKILLS=(plan exec docs review ship)
COMMANDS_DIR="$HOME/.claude/commands"
for skill_name in "${LEGACY_SKILLS[@]}"; do
  for legacy in "$SKILLS_DIR/${skill_name}.md" "$COMMANDS_DIR/${skill_name}.md"; do
    if [ -f "$legacy" ]; then
      cp "$legacy" "${legacy}${BACKUP_SUFFIX}"
      rm -f "$legacy"
    fi
  done
done
if [ -d "$SKILLS_DIR" ] && [ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
  rmdir "$SKILLS_DIR"
fi
echo "  ✓ Legacy slash commands removed (natural-language workflow)"

# Install usage scripts
SCRIPTS_DIR="$HOME/.local/share/frugal-harness/scripts"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR" "$BIN_DIR"
for s in usage.sh usage.js usage-statusline.sh guard-code-edit.sh render-profile.sh frugal-config.sh; do
  fetch_file "scripts/$s" "$SCRIPTS_DIR/$s"
  chmod +x "$SCRIPTS_DIR/$s"
done
ln -sf "$SCRIPTS_DIR/usage.sh" "$BIN_DIR/usage"
ln -sf "$SCRIPTS_DIR/frugal-config.sh" "$BIN_DIR/frugal"
echo "  ✓ usage + frugal scripts → $SCRIPTS_DIR"
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
echo "  ✓ PreToolUse hook installed: guard-code-edit.sh (guiding, not blocking)"

# Detect which worker agents are installed (subscribed by default)
INSTALLED_AGENTS=()
command -v agy &> /dev/null && INSTALLED_AGENTS+=(antigravity)
command -v codex &> /dev/null && INSTALLED_AGENTS+=(codex)

# Back up agent config files before render-profile.sh rewrites them
CODEX_CONFIG="$HOME/.codex/config.toml"
ANTIGRAVITY_SETTINGS="$HOME/.gemini/antigravity-cli/settings.json"
if command -v codex &> /dev/null; then
  mkdir -p "$HOME/.codex"
  [ -f "$CODEX_CONFIG" ] && cp "$CODEX_CONFIG" "${CODEX_CONFIG}${BACKUP_SUFFIX}"
fi
if command -v agy &> /dev/null; then
  mkdir -p "$HOME/.gemini/antigravity-cli"
  [ -f "$ANTIGRAVITY_SETTINGS" ] && cp "$ANTIGRAVITY_SETTINGS" "${ANTIGRAVITY_SETTINGS}${BACKUP_SUFFIX}"
fi

# Write the default delegation profile (priority: antigravity -> codex; ship codex -> antigravity)
PROFILE="$HOME/.config/frugal/profile.json"
mkdir -p "$(dirname "$PROFILE")"
node -e '
const fs = require("fs");
const [out, installedCsv] = process.argv.slice(1);
const installed = (installedCsv || "").split(",").filter(Boolean);
const order = (pref) => pref.filter((a) => installed.includes(a));
const worker = order(["antigravity", "codex"]);
const ship = order(["codex", "antigravity"]);
const profile = {
  agents: worker,
  roles: { plan: ["claude"], exec: worker, review: worker, docs: worker, ship },
  routing: "complexity-auto",
};
fs.writeFileSync(out, JSON.stringify(profile, null, 2) + "\n");
' "$PROFILE" "$(IFS=,; echo "${INSTALLED_AGENTS[*]:-}")"
echo "  ✓ Default delegation profile → $PROFILE"

# Apply the profile: render delegation-profile.md, pin subscribed-agent defaults, regenerate AGENTS.md
"$SCRIPTS_DIR/render-profile.sh"
echo "  ✓ Codex AGENTS.md + delegation profile generated"
if [ ${#INSTALLED_AGENTS[@]} -eq 0 ]; then
  echo "  ⚠ No worker CLIs detected — only Claude planning is configured. Install Codex/Antigravity, then run: frugal config"
fi

# Install Claude Code plugins (caveman) if claude CLI is available
if command -v claude &> /dev/null; then
  if claude plugin list 2>/dev/null | grep -q "caveman@caveman"; then
    echo "  ✓ Claude Code plugin caveman already installed"
  else
    echo "  → Installing Claude Code plugin: caveman"
    claude plugin install caveman@caveman 2>&1 | sed 's/^/    /' || echo "  ⚠ caveman plugin install failed — run manually: claude plugin install caveman"
  fi
fi

# Install mattpocock/skills globally (grill-me, grill-with-docs, and 32 more)
if command -v npx &> /dev/null; then
  if [ -d "$HOME/.agents/skills/grill-me" ]; then
    echo "  ✓ mattpocock/skills already installed"
  else
    echo "  → Installing mattpocock/skills (grill-me, grill-with-docs, +32 more)"
    npx skills@latest add mattpocock/skills -g 2>&1 | grep -E "Done|error|Error|✓|✗|Installed" | sed 's/^/    /' || true
    [ -d "$HOME/.agents/skills/grill-me" ] && echo "  ✓ mattpocock/skills installed" || echo "  ⚠ mattpocock/skills install may have failed — run manually: npx skills@latest add mattpocock/skills -g"
  fi
fi

echo "✅ frugal-harness installed!"
echo ""
echo "🔑 Authentication Setup:"
echo "   Run the following command to login to your Antigravity subscription:"
echo "     agy login"
echo ""
echo "   Verify your login with:"
echo "     agy -p 'say hi'"
echo ""
echo "Delegation priority (plan is always Claude):"
node -e '
const fs = require("fs");
const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const N = { claude: "Claude", antigravity: "Antigravity", codex: "Codex" };
const fmt = (l) => (l && l.length ? l.map((a) => N[a] || a).join(" -> ") : "(unset)");
for (const [r, label] of [["plan","plan"],["exec","exec"],["review","review"],["docs","docs"],["ship","ship"]]) {
  console.log("  " + label.padEnd(7) + "→ " + fmt((p.roles || {})[r]));
}
' "$PROFILE"
echo ""
echo "Model routing: complexity-auto (standard → Sonnet plan / Codex medium, complex → Opus plan / Codex xhigh)"
echo "Change per-role priority anytime with:  frugal config"
echo ""
echo "Total cost: ~\$40/mo (Claude Pro + ChatGPT Plus)"
