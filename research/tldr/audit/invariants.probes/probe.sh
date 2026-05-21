#!/usr/bin/env bash
# Regenerates all probe captures for `tldr invariants`.
#
# Usage:   bash research/tldr/audit/invariants.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# FIXTURE-INPUT command: requires source + tests fixtures.
# Fixtures live at research/fixtures/invariants/.

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
FIXTURES="$PROJECT_ROOT/research/fixtures/invariants"
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

echo "Probing tldr invariants against fixtures in $FIXTURES ..."
cd "$FIXTURES" || { echo "Fixture dir not found: $FIXTURES" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — src.py with test_src.py.
probe "01-happy" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py"

# P02: happy-scale — filter to specific function.
probe "02-happy-scale" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py --function clamp"

# P03: missing required arg (no FILE).
probe "03-missing-arg" "tldr invariants --from-tests $FIXTURES/test_src.py"

# P04: bad path for FILE.
probe "04-badpath" "tldr invariants /no/such/file.py --from-tests $FIXTURES/test_src.py"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -f text"

# P07: format compact.
probe "07-format-compact" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -f dot"

# P09: --min-obs 5 (filter low-observation invariants).
probe "09-min-obs-mid" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py --min-obs 5"

# P10: --min-obs 999 (filter all).
probe "10-min-obs-high" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py --min-obs 999"

# P11: --function not found.
probe "11-function-not-found" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py --function no_such_function"

# P12: missing --from-tests (required).
probe "12-missing-from-tests" "tldr invariants $FIXTURES/src.py"

# P13: bad --from-tests path.
probe "13-bad-from-tests" "tldr invariants $FIXTURES/src.py --from-tests /no/such/tests"

# P14: --from-tests pointing to a non-test source file (still valid path).
probe "14-from-tests-not-tests" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/src.py"

# P15: bad --lang.
probe "15-bad-lang" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -l brainfuck"

# P16: -l python explicit.
probe "16-lang-python" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -l python"

# P17: -l typescript (mismatch).
probe "17-lang-mismatch" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -l typescript"

# P18: legacy -o text.
probe "18-output-flag-text" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -o text"

# P19: legacy -o bogus value.
probe "19-output-flag-bogus" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -o wat"

# P20: --from-tests is directory (not file).
probe "20-from-tests-dir" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES"

# P21: -q quiet.
probe "21-quiet" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py -q"

# P22: --min-obs 0 (literal zero, edge case).
probe "22-min-obs-zero" "tldr invariants $FIXTURES/src.py --from-tests $FIXTURES/test_src.py --min-obs 0"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
