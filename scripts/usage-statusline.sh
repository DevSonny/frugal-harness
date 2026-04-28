#!/usr/bin/env bash
set -euo pipefail

_self="$0"
while [ -L "$_self" ]; do
  _dir="$(cd "$(dirname "$_self")" && pwd)"
  _self="$(readlink "$_self")"
  case "$_self" in
    /*) ;;
    *) _self="$_dir/$_self" ;;
  esac
done
SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"

if ! command -v node >/dev/null 2>&1; then
  printf 'frugal-harness: Node.js required for usage statusline\n'
  exit 0
fi

exec node "$SCRIPT_DIR/usage.js" --statusline
