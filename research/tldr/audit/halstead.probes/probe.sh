#!/usr/bin/env bash
# Regenerates all probe captures for `tldr halstead`.
#
# Usage:   bash research/tldr/audit/halstead.probes/probe.sh
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

echo "Probing tldr halstead against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single file.
probe "01-happy" "tldr halstead backend/providers/yahoo.py"

# P02: happy-scale — directory.
probe "02-happy-scale" "tldr halstead backend/providers"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr halstead /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr halstead backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr halstead backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr halstead backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr halstead backend/providers -f dot"

# P09: --function specific.
probe "09-function" "tldr halstead backend/providers/yahoo.py --function fetch_historical_data"

# P10: --function not found.
probe "10-function-not-found" "tldr halstead backend/providers/yahoo.py --function no_such_function"

# P11: --show-operators.
probe "11-show-operators" "tldr halstead backend/providers/yahoo.py --function fetch_historical_data --show-operators"

# P12: --show-operands.
probe "12-show-operands" "tldr halstead backend/providers/yahoo.py --function fetch_historical_data --show-operands"

# P13: --threshold-volume 0 (all warn).
probe "13-threshold-vol-zero" "tldr halstead backend/providers --threshold-volume 0"

# P14: --threshold-difficulty 0.
probe "14-threshold-diff-zero" "tldr halstead backend/providers --threshold-difficulty 0"

# P15: --top 1.
probe "15-top-one" "tldr halstead backend --top 1"

# P16: --top 0 (all).
probe "16-top-zero" "tldr halstead backend/providers --top 0"

# P17: --exclude.
probe "17-exclude" "tldr halstead backend/providers --exclude '__init__.py'"

# P18: --max-files 1.
probe "18-max-files-low" "tldr halstead backend/providers --max-files 1"

# P19: --include-hidden.
probe "19-include-hidden" "tldr halstead backend/providers --include-hidden"

# P20: bad --lang.
probe "20-bad-lang" "tldr halstead backend/providers -l brainfuck"

# P21: -l typescript on python.
probe "21-lang-mismatch" "tldr halstead backend/providers -l typescript"

# P22: -q quiet.
probe "22-quiet" "tldr halstead backend/providers -q"

# P23: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "23-empty-dir" "tldr halstead $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P24: non-python markdown file.
probe "24-non-source-md" "tldr halstead README.md"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
