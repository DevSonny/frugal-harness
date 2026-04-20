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
  if [ -z "$GEMINI_API_KEY" ]; then
    echo "  ⚠ GEMINI_API_KEY not set"
  else
    echo "  ✓ GEMINI_API_KEY already set"
  fi
fi

if [ $MISSING -eq 1 ]; then
  echo ""
  echo "⚠ Install missing tools above, then re-run this script."
  exit 1
fi

echo ""
echo "All prerequisites met. Installing..."

# Set up GEMINI_API_KEY if not already configured
if command -v gemini &> /dev/null && [ -z "$GEMINI_API_KEY" ]; then
  echo ""
  echo "Gemini API key setup"
  echo "  Get a free key at: https://aistudio.google.com/apikey"
  echo ""
  read -p "  Enter your GEMINI_API_KEY (or press Enter to skip): " -r GEMINI_KEY_INPUT </dev/tty
  if [ -n "$GEMINI_KEY_INPUT" ]; then
    # Detect shell config file
    if [ -f "$HOME/.zshrc" ]; then
      SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
      SHELL_RC="$HOME/.bashrc"
    else
      SHELL_RC="$HOME/.zshrc"
    fi
    # Remove any existing GEMINI_API_KEY line and append new one
    if grep -q "GEMINI_API_KEY" "$SHELL_RC" 2>/dev/null; then
      sed -i.bak '/GEMINI_API_KEY/d' "$SHELL_RC"
    fi
    echo "export GEMINI_API_KEY=\"$GEMINI_KEY_INPUT\"" >> "$SHELL_RC"
    export GEMINI_API_KEY="$GEMINI_KEY_INPUT"
    echo "  ✓ GEMINI_API_KEY added to $SHELL_RC"
    echo "    Run: source $SHELL_RC"
  else
    echo "  Skipped. Set GEMINI_API_KEY manually later."
  fi
fi

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
echo "Agents:"
echo "  /plan    → Claude Code (Opus)"
echo "  /exec    → Codex CLI"
echo "  /docs    → Gemini CLI (free)"
echo "  /review  → Claude Code"
echo "  /ship    → Claude Code"
echo ""
echo "Total cost: ~\$40/mo (Claude Pro + ChatGPT Plus)"
echo "Gemini CLI: free"
