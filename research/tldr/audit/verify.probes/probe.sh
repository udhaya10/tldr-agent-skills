#!/usr/bin/env bash
# Regenerates all probe captures for `tldr verify`.
#
# Usage:   bash research/tldr/audit/verify.probes/probe.sh
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

echo "Probing tldr verify against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir with --quick.
probe "01-happy" "tldr verify backend/providers --quick"

# P02: happy-scale — full backend with --quick.
probe "02-happy-scale" "tldr verify backend --quick"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr verify /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr verify backend/providers --quick -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr verify backend/providers --quick -f text"

# P07: format compact.
probe "07-format-compact" "tldr verify backend/providers --quick -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr verify backend/providers --quick -f dot"

# P09: --quick.
probe "09-quick" "tldr verify backend/providers --quick"

# P10: --detail (specific sub-analysis).
probe "10-detail-contracts" "tldr verify backend/providers --quick --detail contracts"

# P11: --detail bogus.
probe "11-detail-bogus" "tldr verify backend/providers --quick --detail wat"

# P12: bad --lang.
probe "12-bad-lang" "tldr verify backend/providers --quick -l brainfuck"

# P13: -l python explicit.
probe "13-lang-python" "tldr verify backend/providers --quick -l python"

# P14: -l typescript on python.
probe "14-lang-mismatch" "tldr verify backend/providers --quick -l typescript"

# P15: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "15-empty-dir" "tldr verify $EMPTY_DIR --quick"
rmdir "$EMPTY_DIR"

# P16: single file.
probe "16-single-file" "tldr verify backend/providers/yahoo.py --quick"

# P17: non-source markdown.
probe "17-non-source-md" "tldr verify README.md --quick"

# P18: -o text legacy.
probe "18-output-flag-text" "tldr verify backend/providers --quick -o text"

# P19: -o bogus.
probe "19-output-flag-bogus" "tldr verify backend/providers --quick -o wat"

# P20: -q quiet.
probe "20-quiet" "tldr verify backend/providers --quick -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
