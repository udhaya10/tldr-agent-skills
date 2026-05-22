#!/usr/bin/env bash
# Regenerates all probe captures for `tldr todo`.
#
# Usage:   bash research/tldr/ops/todo.probes/probe.sh
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

echo "Probing tldr todo against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir with --quick.
probe "01-happy" "tldr todo backend/providers --quick"

# P02: happy-scale — full backend with --quick.
probe "02-happy-scale" "tldr todo backend --quick"

# P03: missing required arg.
probe "03-missing-arg" "tldr todo"

# P04: bad path.
probe "04-badpath" "tldr todo /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr todo backend/providers --quick -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr todo backend/providers --quick -f text"

# P07: format compact.
probe "07-format-compact" "tldr todo backend/providers --quick -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr todo backend/providers --quick -f dot"

# P09: --quick mode.
probe "09-quick" "tldr todo backend/providers --quick"

# P10: --detail dead.
probe "10-detail-dead" "tldr todo backend/providers --quick --detail dead"

# P11: --detail complexity.
probe "11-detail-complexity" "tldr todo backend/providers --quick --detail complexity"

# P12: --detail bogus.
probe "12-detail-bogus" "tldr todo backend/providers --quick --detail wat"

# P13: --max-items 1.
probe "13-max-items-low" "tldr todo backend/providers --quick --max-items 1"

# P14: --max-items 0 (per --help: show all).
probe "14-max-items-zero" "tldr todo backend/providers --quick --max-items 0"

# P15: -O output to file.
OUT_FILE="$(mktemp -t todo-out.XXXXXX)"
probe "15-output-file" "tldr todo backend/providers --quick -O $OUT_FILE"
echo "=== output file content (first 30 lines) ===" >> "${CMD_DIR}/15-output-file.out"
head -30 "$OUT_FILE" >> "${CMD_DIR}/15-output-file.out" 2>/dev/null || true
rm -f "$OUT_FILE"

# P16: bad --lang.
probe "16-bad-lang" "tldr todo backend/providers --quick -l brainfuck"

# P17: -l python explicit.
probe "17-lang-python" "tldr todo backend/providers --quick -l python"

# P18: -l typescript on python.
probe "18-lang-mismatch" "tldr todo backend/providers --quick -l typescript"

# P19: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "19-empty-dir" "tldr todo $EMPTY_DIR --quick"
rmdir "$EMPTY_DIR"

# P20: single file.
probe "20-single-file" "tldr todo backend/providers/yahoo.py --quick"

# P21: non-source markdown.
probe "21-non-source-md" "tldr todo README.md --quick"

# P22: -q quiet.
probe "22-quiet" "tldr todo backend/providers --quick -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
