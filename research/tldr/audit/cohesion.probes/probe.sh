#!/usr/bin/env bash
# Regenerates all probe captures for `tldr cohesion`.
#
# Usage:   bash research/tldr/audit/cohesion.probes/probe.sh
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

echo "Probing tldr cohesion against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single file with classes.
probe "01-happy" "tldr cohesion backend/providers/base.py"

# P02: happy-scale — directory with multiple classes.
probe "02-happy-scale" "tldr cohesion backend/providers"

# P03: missing required arg.
probe "03-missing-arg" "tldr cohesion"

# P04: bad path.
probe "04-badpath" "tldr cohesion /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr cohesion backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr cohesion backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr cohesion backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr cohesion backend/providers -f dot"

# P09: --min-methods 10 — filter to large classes.
probe "09-min-methods-high" "tldr cohesion backend/providers --min-methods 10"

# P10: --min-methods 0.
probe "10-min-methods-zero" "tldr cohesion backend/providers --min-methods 0"

# P11: --include-dunder flag.
probe "11-include-dunder" "tldr cohesion backend/providers --include-dunder"

# P12: --timeout 1 (very short).
probe "12-timeout-short" "tldr cohesion backend --timeout 1"

# P13: --project-root.
probe "13-project-root" "tldr cohesion backend/providers/base.py --project-root backend"

# P14: bad --lang.
probe "14-bad-lang" "tldr cohesion backend/providers -l brainfuck"

# P15: -l typescript on python.
probe "15-lang-mismatch" "tldr cohesion backend/providers -l typescript"

# P16: -q quiet.
probe "16-quiet" "tldr cohesion backend/providers -q"

# P17: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "17-empty-dir" "tldr cohesion $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P18: non-python file (markdown).
probe "18-non-python-md" "tldr cohesion README.md"

# P19: file with no classes (function-only).
probe "19-no-classes" "tldr cohesion backend/db.py"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
