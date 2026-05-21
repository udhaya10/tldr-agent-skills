#!/usr/bin/env bash
# Regenerates all probe captures for `tldr clones`.
#
# Usage:   bash research/tldr/audit/clones.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# SLOW COMMAND (per Journal 04 §13): scoped to backend/providers/ (4 files)
# for P01/P02. Full-backend probes intentionally avoided — clones detection
# is O(N²) and takes >30s on 56 files.

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

TARGET_REPO="${TARGET_REPO:-/Users/udhayakumar/Workspace/17-Roshan-Projects/Stock-Monitor}"

probe() {
    local slug="$1"
    shift
    local cmd="$*"

    echo "$cmd" > "${CMD_DIR}/${slug}.cmd"

    local out_tmp err_tmp
    out_tmp="$(mktemp)"
    err_tmp="$(mktemp)"
    bash -c "$cmd" > "$out_tmp" 2> "$err_tmp"
    local rc=$?

    local lines
    lines=$(wc -l < "$out_tmp")
    if [ "$lines" -gt 500 ]; then
        {
            head -n 400 "$out_tmp"
            echo ""
            echo "... [$((lines - 450)) lines truncated, full output regeneratable via probe.sh] ..."
            echo ""
            tail -n 50 "$out_tmp"
        } > "${CMD_DIR}/${slug}.out"
    else
        cp "$out_tmp" "${CMD_DIR}/${slug}.out"
    fi

    {
        cat "$err_tmp"
        echo "exit=${rc}"
    } > "${CMD_DIR}/${slug}.err"

    rm -f "$out_tmp" "$err_tmp"
    printf "  %-30s exit=%d  stdout=%d lines\n" "$slug" "$rc" "$lines"
}

echo "Probing tldr clones against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2) — scoped to backend/providers/ for speed
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr clones backend/providers"

# P02: happy-scale — larger but still bounded.
probe "02-happy-scale" "tldr clones backend/providers --threshold 0.5"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr clones /no/such/dir"

# P05: format reject dot? Clones SUPPORTS sarif and dot. Try invalid.
# Try -f bogus instead (clap should reject any non-existent format).
probe "05-format-reject-bogus" "tldr clones backend/providers -f wat"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr clones backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr clones backend/providers -f compact"

# P08: format sarif (SUPPORTED by clones).
probe "08-format-sarif" "tldr clones backend/providers -f sarif"

# P09: format dot (SUPPORTED by clones).
probe "09-format-dot" "tldr clones backend/providers -f dot"

# P10: --threshold 0.99 — high similarity threshold (likely empty).
probe "10-threshold-high" "tldr clones backend/providers --threshold 0.99"

# P11: --threshold 0.0 — no threshold (likely max clones).
probe "11-threshold-zero" "tldr clones backend/providers --threshold 0.0"

# P12: --min-tokens 100 — high tokens (likely empty).
probe "12-min-tokens-high" "tldr clones backend/providers --min-tokens 100"

# P13: --min-lines 50.
probe "13-min-lines-high" "tldr clones backend/providers --min-lines 50"

# P14: --type-filter 1 (Type-1 exact only).
probe "14-type-filter-1" "tldr clones backend/providers --type-filter 1"

# P15: --type-filter bogus — silent fallback to all.
probe "15-type-filter-bogus" "tldr clones backend/providers --type-filter wat"

# P16: --normalize none.
probe "16-normalize-none" "tldr clones backend/providers --normalize none"

# P17: --normalize bogus — silent fallback to all.
probe "17-normalize-bogus" "tldr clones backend/providers --normalize wat"

# P18: --language python (local flag).
probe "18-language-local" "tldr clones backend/providers --language python"

# P19: --language typescript on python-only — empty result.
probe "19-language-mismatch" "tldr clones backend/providers --language typescript"

# P20: -l python (global flag).
probe "20-global-lang" "tldr clones backend/providers -l python"

# P21: --include-within-file flag.
probe "21-include-within-file" "tldr clones backend/providers --include-within-file"

# P22: --show-classes flag.
probe "22-show-classes" "tldr clones backend/providers --show-classes"

# P23: --max-clones 1.
probe "23-max-clones-low" "tldr clones backend/providers --max-clones 1"

# P24: --max-files 1.
probe "24-max-files-low" "tldr clones backend/providers --max-files 1"

# P25: --exclude-tests --exclude-generated.
probe "25-excludes" "tldr clones backend/providers --exclude-tests --exclude-generated"

# P26: legacy -o sarif via --output.
probe "26-legacy-output-sarif" "tldr clones backend/providers -o sarif"

# P27: -q quiet.
probe "27-quiet" "tldr clones backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
