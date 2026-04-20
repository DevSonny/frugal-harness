#!/bin/bash
set -e

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

echo "✅ frugal-harness installed!"
echo ""
echo "🔑 API Key Setup (do this manually):"
echo "   Add to your ~/.zshrc or ~/.bashrc:"
echo ""
echo "   export GEMINI_API_KEY=\"your_api_key_here\""
echo ""
echo "   Then run: source ~/.zshrc"
echo "   Get your key: https://aistudio.google.com/apikey"
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
