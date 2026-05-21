#!/usr/bin/env bash
# Regenerates all probe captures for `tldr cognitive`.
#
# Usage:   bash research/tldr/audit/cognitive.probes/probe.sh
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

echo "Probing tldr cognitive against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single file.
probe "01-happy" "tldr cognitive backend/providers/yahoo.py"

# P02: happy-scale — directory.
probe "02-happy-scale" "tldr cognitive backend/providers"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr cognitive /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr cognitive backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr cognitive backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr cognitive backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr cognitive backend/providers -f dot"

# P09: --function specific.
probe "09-function" "tldr cognitive backend/providers/yahoo.py --function fetch_historical_data"

# P10: --function not found.
probe "10-function-not-found" "tldr cognitive backend/providers/yahoo.py --function no_such_function"

# P11: --threshold 0 — should flag everything as violation.
probe "11-threshold-zero" "tldr cognitive backend/providers --threshold 0"

# P12: --threshold 9999 — should flag nothing.
probe "12-threshold-high" "tldr cognitive backend/providers --threshold 9999"

# P13: --high-threshold 5 — many high-severity violations.
probe "13-high-threshold-low" "tldr cognitive backend/providers --high-threshold 5 --threshold 1"

# P14: --show-contributors flag.
probe "14-show-contributors" "tldr cognitive backend/providers/yahoo.py --show-contributors --function fetch_historical_data"

# P15: --include-cyclomatic flag.
probe "15-include-cyclomatic" "tldr cognitive backend/providers --include-cyclomatic"

# P16: --top 1 — only top 1 function.
probe "16-top-one" "tldr cognitive backend/providers --top 1"

# P17: --top 0 (all).
probe "17-top-zero" "tldr cognitive backend/providers --top 0"

# P18: --exclude pattern.
probe "18-exclude" "tldr cognitive backend/providers --exclude '*.test.py' --exclude '__init__.py'"

# P19: --max-files 1.
probe "19-max-files-low" "tldr cognitive backend/providers --max-files 1"

# P20: --include-hidden flag.
probe "20-include-hidden" "tldr cognitive backend/providers --include-hidden"

# P21: bad --lang.
probe "21-bad-lang" "tldr cognitive backend/providers -l brainfuck"

# P22: -l typescript on python dir (no matching files).
probe "22-lang-mismatch" "tldr cognitive backend/providers -l typescript"

# P23: -q quiet.
probe "23-quiet" "tldr cognitive backend/providers -q"

# P24: empty directory.
EMPTY_DIR="$(mktemp -d)"
probe "24-empty-dir" "tldr cognitive $EMPTY_DIR"
rmdir "$EMPTY_DIR"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
