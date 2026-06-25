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
fi

# Save config
mkdir -p "$HOME/.frugal-harness"
echo "FRUGAL_MAIN=$FRUGAL_MAIN" > "$CONFIG_FILE"
echo "FRUGAL_HELPERS=$FRUGAL_HELPERS" >> "$CONFIG_FILE"
echo "FRUGAL_DEPLOY_CLAUDE=$FRUGAL_DEPLOY_CLAUDE" >> "$CONFIG_FILE"

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
