#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

# Determine project root
if [ -n "${1:-}" ]; then
  # Explicit target: ./install.sh /path/to/project
  root="$(cd "$1" && pwd)"
elif [[ "$script_dir" == *node_modules* ]]; then
  # npm postinstall: walk up from node_modules
  root="${script_dir%%/node_modules/*}"
else
  echo "Usage: ./install.sh <project-root>"
  echo "  Or install via npm: npm install --save-dev <git-url>"
  exit 1
fi

mkdir -p "$root/.claude/skills/code-scan"
mkdir -p "$root/.claude/rubric"

cp "$script_dir/skill/SKILL.md" "$root/.claude/skills/code-scan/SKILL.md"

# Copy rubric files, don't overwrite if target has local edits
for f in "$script_dir"/rubric/*.md; do
  target="$root/.claude/rubric/$(basename "$f")"
  if [ -f "$target" ]; then
    if ! diff -q "$f" "$target" > /dev/null 2>&1; then
      echo "  skip: $(basename "$f") (local changes — see rubric/$(basename "$f") for latest)"
      continue
    fi
  fi
  cp "$f" "$target"
done

echo "claude-code-scan installed to $root/.claude/"
echo "  skill: .claude/skills/code-scan/SKILL.md"
echo "  rubric: .claude/rubric/ ($(ls "$root/.claude/rubric/"/*.md 2>/dev/null | wc -l | tr -d ' ') files)"
