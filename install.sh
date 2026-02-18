#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

# Determine project root
if [ -n "${1:-}" ]; then
  root="$(cd "$1" && pwd)"
elif [[ "$script_dir" == *node_modules* ]]; then
  root="${script_dir%%/node_modules/*}"
else
  # npm prep phase (cache dir) — skip silently
  exit 0
fi

mkdir -p "$root/.claude/rubric"

# Install all skills
skill_count=0
for d in "$script_dir"/skills/*/; do
  name=$(basename "$d")
  mkdir -p "$root/.claude/skills/$name"
  cp -r "$d"* "$root/.claude/skills/$name/"
  skill_count=$((skill_count + 1))
done

# Copy rubric files, don't overwrite if target has local edits
rubric_count=0
for f in "$script_dir"/rubric/*.md; do
  target="$root/.claude/rubric/$(basename "$f")"
  if [ -f "$target" ]; then
    if ! diff -q "$f" "$target" > /dev/null 2>&1; then
      echo "  skip: $(basename "$f") (local changes)"
      continue
    fi
  fi
  cp "$f" "$target"
  rubric_count=$((rubric_count + 1))
done

echo "lens-scanner installed to $root/.claude/"
echo "  skills: $skill_count ($(ls "$root/.claude/skills/" | grep -E 'code-scan|ai-smell-scan' | tr '\n' ' '))"
echo "  rubric: $rubric_count files"
