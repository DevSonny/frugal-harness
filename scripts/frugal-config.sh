#!/usr/bin/env bash

set -e

CONFIG_FILE="$HOME/.frugal-harness/config.sh"
SYNC_SCRIPT="$HOME/.claude/scripts/sync-agents.sh"

# Default config if not exists
if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$HOME/.frugal-harness"
  echo "FRUGAL_MAIN=claude" > "$CONFIG_FILE"
  echo "FRUGAL_HELPERS=codex,agy" >> "$CONFIG_FILE"
  echo "FRUGAL_DEPLOY_CLAUDE=yes" >> "$CONFIG_FILE"
fi

# Source current config
source "$CONFIG_FILE"

show_help() {
  echo "frugal-harness config utility"
  echo ""
  echo "Usage: frugal-config [options]"
  echo "Options:"
  echo "  --main <claude|agy|codex>        Set the main handler"
  echo "  --helpers <none|claude|agy|codex|claude,codex|claude,agy|agy,codex|all>"
  echo "                                   Set the helper agents"
  echo "  --deploy-claude <yes|no>         Deploy CLAUDE.md when Claude is not main"
  echo "  --interactive                    Run interactive setup"
  echo "  --help                           Show this help"
  echo ""
  echo "If no arguments are provided, it runs in interactive mode."
}

# Parse args
INTERACTIVE=1
if [ "$#" -gt 0 ]; then
  INTERACTIVE=0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --main)
      FRUGAL_MAIN="$2"
      shift 2
      ;;
    --helpers)
      FRUGAL_HELPERS="$2"
      shift 2
      ;;
    --deploy-claude)
      FRUGAL_DEPLOY_CLAUDE="$2"
      shift 2
      ;;
    --interactive)
      INTERACTIVE=1
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

if [ "$INTERACTIVE" -eq 1 ]; then
  echo "🪙 frugal-harness configuration"
  echo ""
  echo "Step 1: Which is your main handler? (The agent you talk to directly)"
  echo "  1) Claude Code (plans & orchestrates, delegates implementation)"
  echo "  2) agy (does everything end-to-end)"
  echo "  3) Codex CLI (does everything end-to-end)"
  printf "Choice [%s]: " "${FRUGAL_MAIN:-1}"
  read -r main_choice < /dev/tty
  main_choice="${main_choice:-$FRUGAL_MAIN}"

  case "$main_choice" in
    1|claude) FRUGAL_MAIN="claude" ;;
    2|agy)    FRUGAL_MAIN="agy" ;;
    3|codex)  FRUGAL_MAIN="codex" ;;
    *)        echo "Invalid choice. Leaving as $FRUGAL_MAIN." ;;
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
  printf "Choice: "
  read -r helper_choice < /dev/tty
  
  if [ "$FRUGAL_MAIN" = "claude" ]; then
    case "$helper_choice" in
      1) FRUGAL_HELPERS="codex,agy" ;;
      2) FRUGAL_HELPERS="codex" ;;
      3) FRUGAL_HELPERS="agy" ;;
      4) FRUGAL_HELPERS="none" ;;
    esac
  elif [ "$FRUGAL_MAIN" = "agy" ]; then
    case "$helper_choice" in
      1) FRUGAL_HELPERS="claude,codex" ;;
      2) FRUGAL_HELPERS="claude" ;;
      3) FRUGAL_HELPERS="codex" ;;
      4) FRUGAL_HELPERS="none" ;;
    esac
  elif [ "$FRUGAL_MAIN" = "codex" ]; then
    case "$helper_choice" in
      1) FRUGAL_HELPERS="claude,agy" ;;
      2) FRUGAL_HELPERS="claude" ;;
      3) FRUGAL_HELPERS="agy" ;;
      4) FRUGAL_HELPERS="none" ;;
    esac
  fi


  if [ "$FRUGAL_MAIN" != "claude" ]; then
    echo ""
    echo "Step 3: Deploy CLAUDE.md anyway?"
    echo "  Even though Claude is not your main handler, you can deploy CLAUDE.md"
    echo "  so that if you ever open Claude Code, it knows about your helpers."
    printf "Deploy CLAUDE.md? (y/n) [%s]: " "${FRUGAL_DEPLOY_CLAUDE:-n}"
    read -r deploy_choice < /dev/tty
    deploy_choice="${deploy_choice:-$FRUGAL_DEPLOY_CLAUDE}"
    case "$deploy_choice" in
      y|Y|yes) FRUGAL_DEPLOY_CLAUDE="yes" ;;
      n|N|no)  FRUGAL_DEPLOY_CLAUDE="no" ;;
    esac
  else
    FRUGAL_DEPLOY_CLAUDE="yes"
  fi

  echo ""
  echo "Step 4: Choose agy model tier:"
  echo "  1) Fast → Flash default"
  echo "  2) Balanced [recommended] → Pro Low/High"
  echo "  3) Quality → Pro High default, Opus for arch"
  echo "  4) Custom → Per-use selection"
  printf "Choice [%s]: " "${FRUGAL_AGY_TIER:-2}"
  read -r tier_choice < /dev/tty
  tier_choice="${tier_choice:-${FRUGAL_AGY_TIER:-2}}"
  FRUGAL_AGY_TIER="$tier_choice"

  echo ""
  echo "Step 5: Choose Docs agent:"
  echo "  1) agy (Gemini 3.1 Pro Low) [default]"
  echo "  2) Claude Code directly"
  echo "  3) Codex"
  printf "Choice [%s]: " "${docs_choice:-1}"
  read -r docs_choice < /dev/tty
  docs_choice="${docs_choice:-1}"
  
  case "$docs_choice" in
    1) FRUGAL_DOCS_AGENT="agy" ;;
    2) FRUGAL_DOCS_AGENT="claude" ;;
    3) FRUGAL_DOCS_AGENT="codex" ;;
    *) FRUGAL_DOCS_AGENT="agy" ;;
  esac

fi

# Apply tier settings to individual model vars
case "$FRUGAL_AGY_TIER" in
  1)
    FRUGAL_AGY_MODEL_FAST="Gemini 3.5 Flash (Medium)"
    FRUGAL_AGY_MODEL_BASIC="Gemini 3.5 Flash (High)"
    FRUGAL_AGY_MODEL_COMPLEX="Gemini 3.1 Pro (Low)"
    FRUGAL_AGY_MODEL_ARCH="Gemini 3.1 Pro (High)"
    FRUGAL_AGY_MODEL_REVIEW="Gemini 3.5 Flash (Medium)"
    FRUGAL_DOCS_AGY_MODEL="Gemini 3.5 Flash (Low)"
    ;;
  2)
    FRUGAL_AGY_MODEL_FAST="Gemini 3.5 Flash (Medium)"
    FRUGAL_AGY_MODEL_BASIC="Gemini 3.1 Pro (Low)"
    FRUGAL_AGY_MODEL_COMPLEX="Gemini 3.1 Pro (High)"
    FRUGAL_AGY_MODEL_ARCH="Claude Opus 4.6 (Thinking)"
    FRUGAL_AGY_MODEL_REVIEW="Gemini 3.1 Pro (Low)"
    FRUGAL_DOCS_AGY_MODEL="Gemini 3.5 Flash (Low)"
    ;;
  3)
    FRUGAL_AGY_MODEL_FAST="Gemini 3.1 Pro (Low)"
    FRUGAL_AGY_MODEL_BASIC="Gemini 3.1 Pro (High)"
    FRUGAL_AGY_MODEL_COMPLEX="Claude Sonnet 4.6 (Thinking)"
    FRUGAL_AGY_MODEL_ARCH="Claude Opus 4.6 (Thinking)"
    FRUGAL_AGY_MODEL_REVIEW="Gemini 3.1 Pro (High)"
    FRUGAL_DOCS_AGY_MODEL="Gemini 3.1 Pro (Low)"
    ;;
  4)
    # Leave as is or load from current
    : 
    ;;
  *)
    FRUGAL_AGY_TIER="2"
    FRUGAL_AGY_MODEL_FAST="Gemini 3.5 Flash (Medium)"
    FRUGAL_AGY_MODEL_BASIC="Gemini 3.1 Pro (Low)"
    FRUGAL_AGY_MODEL_COMPLEX="Gemini 3.1 Pro (High)"
    FRUGAL_AGY_MODEL_ARCH="Claude Opus 4.6 (Thinking)"
    FRUGAL_AGY_MODEL_REVIEW="Gemini 3.1 Pro (Low)"
    FRUGAL_DOCS_AGY_MODEL="Gemini 3.5 Flash (Low)"
    ;;
esac

# Save config
mkdir -p "$HOME/.frugal-harness"
echo "FRUGAL_MAIN=$FRUGAL_MAIN" > "$CONFIG_FILE"
echo "FRUGAL_HELPERS=$FRUGAL_HELPERS" >> "$CONFIG_FILE"
echo "FRUGAL_DEPLOY_CLAUDE=$FRUGAL_DEPLOY_CLAUDE" >> "$CONFIG_FILE"
echo "FRUGAL_AGY_TIER=$FRUGAL_AGY_TIER" >> "$CONFIG_FILE"
echo "FRUGAL_DOCS_AGENT=$FRUGAL_DOCS_AGENT" >> "$CONFIG_FILE"
echo "FRUGAL_AGY_MODEL_FAST=\"$FRUGAL_AGY_MODEL_FAST\"" >> "$CONFIG_FILE"
echo "FRUGAL_AGY_MODEL_BASIC=\"$FRUGAL_AGY_MODEL_BASIC\"" >> "$CONFIG_FILE"
echo "FRUGAL_AGY_MODEL_COMPLEX=\"$FRUGAL_AGY_MODEL_COMPLEX\"" >> "$CONFIG_FILE"
echo "FRUGAL_AGY_MODEL_ARCH=\"$FRUGAL_AGY_MODEL_ARCH\"" >> "$CONFIG_FILE"
echo "FRUGAL_AGY_MODEL_REVIEW=\"$FRUGAL_AGY_MODEL_REVIEW\"" >> "$CONFIG_FILE"
echo "FRUGAL_DOCS_AGY_MODEL=\"$FRUGAL_DOCS_AGY_MODEL\"" >> "$CONFIG_FILE"

echo ""
echo "Configuration saved:"
echo "  Main handler : $FRUGAL_MAIN"
echo "  Helpers      : $FRUGAL_HELPERS"
if [ "$FRUGAL_MAIN" != "claude" ]; then
  echo "  Deploy CLAUDE: $FRUGAL_DEPLOY_CLAUDE"
fi
echo ""

# Run sync-agents
if [ -f "$SYNC_SCRIPT" ]; then
  echo "Applying changes..."
  bash "$SYNC_SCRIPT"
  echo "Done!"
else
  echo "Warning: $SYNC_SCRIPT not found. Run installer to complete setup."
fi
