#!/bin/sh
# Links each skill in this repo into ~/.claude/skills so Claude Code picks it up, and stays current
# as the repo changes.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/.claude/skills"
for skill in "$here"/*/; do
  name="$(basename "$skill")"
  [ -f "$skill/SKILL.md" ] || continue
  ln -sfn "${skill%/}" "$HOME/.claude/skills/$name"
  echo "linked $name"
done
