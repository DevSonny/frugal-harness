#!/bin/bash
set -e

echo "🗑️  frugal-harness uninstaller"
echo ""

SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"
SKILLS=(plan exec docs review ship)

# Check if anything is installed
FOUND=0
if [ -f "$CLAUDE_MD" ]; then FOUND=1; fi
for skill_name in "${SKILLS[@]}"; do
  if [ -f "$SKILLS_DIR/${skill_name}.md" ]; then FOUND=1; fi
done

if [ $FOUND -eq 0 ]; then
  echo "Nothing to uninstall — frugal-harness files not found."
  exit 0
fi

echo "This will backup and remove:"
[ -f "$CLAUDE_MD" ] && echo "  $CLAUDE_MD"
for skill_name in "${SKILLS[@]}"; do
  [ -f "$SKILLS_DIR/${skill_name}.md" ] && echo "  $SKILLS_DIR/${skill_name}.md"
done

echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Backing up and removing..."

if [ -f "$CLAUDE_MD" ]; then
  cp "$CLAUDE_MD" "${CLAUDE_MD}${BACKUP_SUFFIX}"
  rm "$CLAUDE_MD"
  echo "  ↩ Backed up and removed CLAUDE.md"
fi

for skill_name in "${SKILLS[@]}"; do
  local_path="$SKILLS_DIR/${skill_name}.md"
  if [ -f "$local_path" ]; then
    cp "$local_path" "${local_path}${BACKUP_SUFFIX}"
    rm "$local_path"
    echo "  ↩ Backed up and removed skills/${skill_name}.md"
  fi
done

if [ -d "$SKILLS_DIR" ] && [ -z "$(ls -A "$SKILLS_DIR")" ]; then
  rmdir "$SKILLS_DIR"
  echo "  ✓ Removed empty skills/ directory"
fi

echo ""
echo "✅ frugal-harness uninstalled!"
echo "   Backups saved with suffix: ${BACKUP_SUFFIX}"
