#!/usr/bin/env bash
# Regenerates all probe captures for `tldr available`.
#
# Usage:   bash research/tldr/deep/available.probes/probe.sh
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

echo "Probing tldr available against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small function with arithmetic expressions (CSE candidates).
probe "01-happy" "tldr available backend/providers/yahoo.py _to_finite_float"

# P02: happy-scale — larger function with more blocks.
probe "02-happy-scale" "tldr available backend/providers/yahoo.py fetch_historical_data"

# P03: missing required arg — FUNCTION omitted.
probe "03-missing-arg" "tldr available backend/providers/yahoo.py"

# P04: bad path.
probe "04-badpath" "tldr available /no/such/file.py some_fn"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr available backend/providers/yahoo.py _to_finite_float -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr available backend/providers/yahoo.py _to_finite_float -f text"

# P07: format compact.
probe "07-format-compact" "tldr available backend/providers/yahoo.py _to_finite_float -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr available backend/providers/yahoo.py _to_finite_float -f dot"

# P09: --check on a specific expression — modal output.
probe "09-check" "tldr available backend/providers/yahoo.py _to_finite_float --check 'float(value)'"

# P10: --at-line — show expressions at a line.
probe "10-at-line" "tldr available backend/providers/yahoo.py _to_finite_float --at-line 21"

# P11: --killed-by — show what kills an expression.
probe "11-killed-by" "tldr available backend/providers/yahoo.py _to_finite_float --killed-by 'value'"

# P12: --cse-only — skip per-block details.
probe "12-cse-only" "tldr available backend/providers/yahoo.py _to_finite_float --cse-only"

# P13: function name not found.
probe "13-function-not-found" "tldr available backend/providers/yahoo.py no_such_function"

# P14: bad --lang.
probe "14-bad-lang" "tldr available backend/providers/yahoo.py _to_finite_float -l brainfuck"

# P15: non-source file (markdown).
probe "15-non-source-md" "tldr available README.md anything"

# P16: --check on an expression that DOESN'T exist in the function.
probe "16-check-missing" "tldr available backend/providers/yahoo.py _to_finite_float --check 'totally_made_up'"

# P17: --at-line out of range.
probe "17-at-line-oor" "tldr available backend/providers/yahoo.py _to_finite_float --at-line 999999"

# P18: -q quiet.
probe "18-quiet" "tldr available backend/providers/yahoo.py _to_finite_float -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
