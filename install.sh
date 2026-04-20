#!/usr/bin/env bash
set -e

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

backup() {
  if [ -f "$1" ]; then
    cp "$1" "$1.bak"
    echo "  Backed up $1 → $1.bak"
  fi
}

echo "Installing frugal-harness to $CLAUDE_DIR ..."
mkdir -p "$SKILLS_DIR"

backup "$CLAUDE_DIR/CLAUDE.md"
cp CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
echo "  Copied CLAUDE.md"

for skill in skills/*.md; do
  backup "$SKILLS_DIR/$(basename $skill)"
  cp "$skill" "$SKILLS_DIR/$(basename $skill)"
  echo "  Copied $skill"
done

echo ""
echo "Done! Restart Claude Code to apply."
echo "완료! Claude Code를 재시작하면 적용됩니다."
