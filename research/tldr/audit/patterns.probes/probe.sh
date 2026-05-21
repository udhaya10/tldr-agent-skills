#!/usr/bin/env bash
# Regenerates all probe captures for `tldr patterns`.
#
# Usage:   bash research/tldr/audit/patterns.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.

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

echo "Probing tldr patterns against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr patterns backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr patterns backend"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr patterns /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr patterns backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr patterns backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr patterns backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr patterns backend/providers -f dot"

# P09: --category (try various values).
probe "09-category-naming" "tldr patterns backend/providers --category naming"

# P10: --category error-handling.
probe "10-category-error" "tldr patterns backend/providers --category error-handling"

# P11: --category bogus (clap value_parser rejection).
probe "11-category-bogus" "tldr patterns backend/providers --category wat"

# P12: --min-confidence 0.0 (everything).
probe "12-min-conf-zero" "tldr patterns backend/providers --min-confidence 0.0"

# P13: --min-confidence 1.0 (perfect only).
probe "13-min-conf-perfect" "tldr patterns backend/providers --min-confidence 1.0"

# P14: --min-confidence 0.5 (default).
probe "14-min-conf-mid" "tldr patterns backend/providers --min-confidence 0.5"

# P15: --max-files 1.
probe "15-max-files-low" "tldr patterns backend --max-files 1"

# P16: --max-files 0 (unlimited).
probe "16-max-files-zero" "tldr patterns backend/providers --max-files 0"

# P17: --no-constraints.
probe "17-no-constraints" "tldr patterns backend/providers --no-constraints"

# P18: bad --lang.
probe "18-bad-lang" "tldr patterns backend/providers -l brainfuck"

# P19: -l python explicit.
probe "19-lang-python" "tldr patterns backend/providers -l python"

# P20: -l typescript on python.
probe "20-lang-mismatch" "tldr patterns backend/providers -l typescript"

# P21: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "21-empty-dir" "tldr patterns $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P22: non-source markdown.
probe "22-non-source-md" "tldr patterns README.md"

# P23: -q quiet.
probe "23-quiet" "tldr patterns backend/providers -q"

# P24: single file.
probe "24-single-file" "tldr patterns backend/providers/yahoo.py"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
