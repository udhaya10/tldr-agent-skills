#!/usr/bin/env bash
# Regenerates all probe captures for `tldr specs`.
#
# Usage:   bash research/tldr/audit/specs.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# FIXTURE-INPUT command: requires pytest test files.
# Reuses fixtures from research/fixtures/invariants/.

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

echo "Probing tldr specs against fixtures in $FIXTURES ..."
cd "$FIXTURES" || { echo "Fixture dir not found: $FIXTURES" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single test file.
probe "01-happy" "tldr specs --from-tests $FIXTURES/test_src.py"

# P02: happy-scale — directory.
probe "02-happy-scale" "tldr specs --from-tests $FIXTURES"

# P03: missing required arg (no --from-tests).
probe "03-missing-arg" "tldr specs"

# P04: bad path.
probe "04-badpath" "tldr specs --from-tests /no/such/tests"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr specs --from-tests $FIXTURES/test_src.py -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr specs --from-tests $FIXTURES/test_src.py -f text"

# P07: format compact.
probe "07-format-compact" "tldr specs --from-tests $FIXTURES/test_src.py -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr specs --from-tests $FIXTURES/test_src.py -f dot"

# P09: --function filter.
probe "09-function-filter" "tldr specs --from-tests $FIXTURES/test_src.py --function add"

# P10: --function not found.
probe "10-function-not-found" "tldr specs --from-tests $FIXTURES/test_src.py --function no_such_function"

# P11: --source cross-reference.
probe "11-source-flag" "tldr specs --from-tests $FIXTURES/test_src.py --source $FIXTURES"

# P12: --source bad path.
probe "12-source-bad" "tldr specs --from-tests $FIXTURES/test_src.py --source /no/such/source"

# P13: bad --lang.
probe "13-bad-lang" "tldr specs --from-tests $FIXTURES/test_src.py -l brainfuck"

# P14: -l python explicit.
probe "14-lang-python" "tldr specs --from-tests $FIXTURES/test_src.py -l python"

# P15: -l typescript (mismatch).
probe "15-lang-mismatch" "tldr specs --from-tests $FIXTURES/test_src.py -l typescript"

# P16: legacy -o text.
probe "16-output-flag-text" "tldr specs --from-tests $FIXTURES/test_src.py -o text"

# P17: legacy -o bogus.
probe "17-output-flag-bogus" "tldr specs --from-tests $FIXTURES/test_src.py -o wat"

# P18: --from-tests is not a test file (regular .py).
probe "18-from-tests-not-test" "tldr specs --from-tests $FIXTURES/src.py"

# P19: -q quiet.
probe "19-quiet" "tldr specs --from-tests $FIXTURES/test_src.py -q"

# P20: empty dir as tests.
EMPTY_DIR="$(mktemp -d)"
probe "20-empty-tests-dir" "tldr specs --from-tests $EMPTY_DIR"
rmdir "$EMPTY_DIR"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
