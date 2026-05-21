#!/usr/bin/env bash
# Regenerates all probe captures for `tldr coverage`.
#
# Usage:   bash research/tldr/audit/coverage.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# FIXTURE-INPUT command per Journal 04 §13: needs LCOV/Cobertura/coverage.py.
# Fixtures live at research/fixtures/coverage/.

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
FIXTURES="$PROJECT_ROOT/research/fixtures/coverage"
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

echo "Probing tldr coverage against fixtures in $FIXTURES ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — LCOV fixture, auto-detect format.
probe "01-happy" "tldr coverage $FIXTURES/sample.lcov"

# P02: happy-scale — same with --by-file --uncovered.
probe "02-happy-scale" "tldr coverage $FIXTURES/sample.lcov --by-file --uncovered"

# P03: missing required arg.
probe "03-missing-arg" "tldr coverage"

# P04: bad path.
probe "04-badpath" "tldr coverage /no/such/file.lcov"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr coverage $FIXTURES/sample.lcov -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr coverage $FIXTURES/sample.lcov -f text"

# P07: format compact.
probe "07-format-compact" "tldr coverage $FIXTURES/sample.lcov -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr coverage $FIXTURES/sample.lcov -f dot"

# P09: -R cobertura on .xml fixture.
probe "09-report-cobertura" "tldr coverage $FIXTURES/sample.xml -R cobertura"

# P10: -R coveragepy on .json fixture.
probe "10-report-coveragepy" "tldr coverage $FIXTURES/coveragepy.json -R coveragepy"

# P11: -R lcov on .lcov.
probe "11-report-lcov" "tldr coverage $FIXTURES/sample.lcov -R lcov"

# P12: -R auto (default) on each.
probe "12-report-auto-lcov" "tldr coverage $FIXTURES/sample.lcov -R auto"

# P13: -R mismatch (cobertura format on .lcov file).
probe "13-report-mismatch" "tldr coverage $FIXTURES/sample.lcov -R cobertura"

# P14: --threshold 100 (everything fails).
probe "14-threshold-100" "tldr coverage $FIXTURES/sample.lcov --threshold 100"

# P15: --threshold 0 (everything passes).
probe "15-threshold-0" "tldr coverage $FIXTURES/sample.lcov --threshold 0"

# P16: --uncovered-only.
probe "16-uncovered-only" "tldr coverage $FIXTURES/sample.lcov --uncovered-only"

# P17: --filter.
probe "17-filter" "tldr coverage $FIXTURES/sample.lcov --filter 'src/main*' --by-file"

# P18: --sort asc.
probe "18-sort-asc" "tldr coverage $FIXTURES/sample.lcov --sort asc --by-file"

# P19: --sort desc.
probe "19-sort-desc" "tldr coverage $FIXTURES/sample.lcov --sort desc --by-file"

# P20: --base-path.
probe "20-base-path" "tldr coverage $FIXTURES/sample.lcov --base-path /tmp --by-file"

# P21: bad --report-format value.
probe "21-bad-report-format" "tldr coverage $FIXTURES/sample.lcov -R wat"

# P22: bad --sort value.
probe "22-bad-sort" "tldr coverage $FIXTURES/sample.lcov --sort wat"

# P23: -q quiet.
probe "23-quiet" "tldr coverage $FIXTURES/sample.lcov -q"

# P24: malformed LCOV (empty file).
EMPTY_FILE="$(mktemp -t empty.lcov.XXXXXX)"
probe "24-empty-file" "tldr coverage $EMPTY_FILE"
rm -f "$EMPTY_FILE"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
