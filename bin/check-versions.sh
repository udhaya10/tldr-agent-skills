#!/usr/bin/env bash
# check-versions.sh — report version + deprecation state of all tldr-* skills in this repo.
#
# Usage:   bash bin/check-versions.sh
# Output:  Per-skill table with version, deprecation status, and replacement (if deprecated).
#
# Use this as a sanity check before publishing changes — if a skill's
# version hasn't been bumped after changes, this won't catch it (the
# script only reads what's in the frontmatter), but it does surface
# missing fields and the overall deprecation picture.
#
# Exit codes:
#   0 — every active skill has a version; deprecation map is consistent
#   1 — one or more active skills are missing version metadata
#   2 — script invocation error

set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

active=0
deprecated=0
missing_version=0

printf '\n%-30s %-12s %-12s %s\n' "SKILL" "VERSION" "STATUS" "REPLACED-BY"
printf '%-30s %-12s %-12s %s\n' "------------------------------" "------------" "------------" "------------------------"

for skill_dir in tldr-*/; do
  name=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"
  [ -f "$file" ] || continue

  # Extract version (looks for "  version:" inside the metadata block).
  version=$(awk '
    /^metadata:/ {in_meta=1; next}
    in_meta && /^  version:/ {gsub(/.*: *"|".*/, ""); print; exit}
    !/^[[:space:]]/ && !/^---/ {in_meta=0}
  ' "$file")

  # Extract deprecation status.
  is_deprecated=$(awk '
    /^metadata:/ {in_meta=1; next}
    in_meta && /^  deprecated:/ {gsub(/.*: *"|".*/, ""); print; exit}
    !/^[[:space:]]/ && !/^---/ {in_meta=0}
  ' "$file")

  # Extract replaced-by (if deprecated).
  replaced_by=$(awk '
    /^metadata:/ {in_meta=1; next}
    in_meta && /^  replaced-by:/ {gsub(/.*: *"|".*/, ""); print; exit}
    !/^[[:space:]]/ && !/^---/ {in_meta=0}
  ' "$file")

  if [ "$is_deprecated" = "true" ]; then
    status="DEPRECATED"
    deprecated=$((deprecated+1))
    printf '%-30s %-12s %-12s %s\n' "$name" "${version:--}" "$status" "${replaced_by:--}"
  else
    active=$((active+1))
    status="active"
    if [ -z "$version" ]; then
      missing_version=$((missing_version+1))
      version="(MISSING)"
    fi
    printf '%-30s %-12s %-12s %s\n' "$name" "$version" "$status" "-"
  fi
done

echo
echo "Summary:"
echo "  Active skills:     $active"
echo "  Deprecated stubs:  $deprecated"
echo "  Total folders:     $((active+deprecated))"
if [ $missing_version -gt 0 ]; then
  echo
  echo "  ⚠️  $missing_version active skill(s) missing version metadata."
  exit 1
fi

echo
echo "To compare against installed versions, run:"
echo "  npx skills list -g | grep tldr-"
echo
echo "To install or update from this repo:"
echo "  npx skills add udhaya10/tldr-agent-skills --all -g"
echo "  npx skills update -g"
