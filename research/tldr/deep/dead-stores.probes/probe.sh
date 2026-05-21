#!/usr/bin/env bash
# Regenerates all probe captures for `tldr dead-stores`.
#
# Usage:   bash research/tldr/deep/dead-stores.probes/probe.sh
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

echo "Probing tldr dead-stores against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small function.
probe "01-happy" "tldr dead-stores backend/providers/yahoo.py _to_finite_float"

# P02: happy-scale — larger function with more assignments.
probe "02-happy-scale" "tldr dead-stores backend/providers/yahoo.py fetch_historical_data"

# P03: missing required arg — FUNCTION omitted.
probe "03-missing-arg" "tldr dead-stores backend/providers/yahoo.py"

# P04: bad path.
probe "04-badpath" "tldr dead-stores /no/such/file.py some_fn"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -f text"

# P07: format compact.
probe "07-format-compact" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -f dot"

# P09: --compare flag — include live-vars comparison.
probe "09-compare" "tldr dead-stores backend/providers/yahoo.py fetch_historical_data --compare"

# P10: function not found.
probe "10-function-not-found" "tldr dead-stores backend/providers/yahoo.py no_such_function"

# P11: bad --lang.
probe "11-bad-lang" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -l brainfuck"

# P12: non-source file (markdown).
probe "12-non-source-md" "tldr dead-stores README.md anything"

# P13: legacy -o text flag.
probe "13-output-flag-text" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -o text"

# P14: -q quiet.
probe "14-quiet" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -q"

# P15: directory as FILE.
probe "15-directory-arg" "tldr dead-stores backend anything"

# P16: -l python explicit on .py.
probe "16-lang-python" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -l python"

# P17: -l typescript on .py file — silent mismatch?
probe "17-lang-mismatch" "tldr dead-stores backend/providers/yahoo.py _to_finite_float -l typescript"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
