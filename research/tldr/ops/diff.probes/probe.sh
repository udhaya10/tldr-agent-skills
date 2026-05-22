#!/usr/bin/env bash
# Regenerates all probe captures for `tldr diff`.
#
# Usage:   bash research/tldr/ops/diff.probes/probe.sh
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

echo "Probing tldr diff against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — diff two similar files.
probe "01-happy" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py"

# P02: happy-scale — diff at L6 file granularity on two dirs.
probe "02-happy-scale" "tldr diff backend/providers backend --granularity file"

# P03: missing required arg (only FILE_A).
probe "03-missing-arg" "tldr diff backend/providers/yahoo.py"

# P04: bad path (FILE_A).
probe "04-badpath" "tldr diff /no/such/a.py backend/providers/yahoo.py"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f text"

# P07: format compact.
probe "07-format-compact" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f dot"

# P09: --granularity token (L1).
probe "09-granularity-token" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g token"

# P10: --granularity expression (L2).
probe "10-granularity-expression" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g expression"

# P11: --granularity statement (L3).
probe "11-granularity-statement" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g statement"

# P12: --granularity class (L5).
probe "12-granularity-class" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g class"

# P13: --granularity file (L6, needs dirs).
probe "13-granularity-file" "tldr diff backend/providers backend/providers -g file"

# P14: --granularity module (L7).
probe "14-granularity-module" "tldr diff backend/providers backend/providers -g module"

# P15: --granularity architecture (L8).
probe "15-granularity-arch" "tldr diff backend backend -g architecture"

# P16: --granularity bogus.
probe "16-granularity-bogus" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g wat"

# P17: --semantic-only.
probe "17-semantic-only" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py --semantic-only"

# P18: -O output to file.
OUT_FILE="$(mktemp -t diff-out.XXXXXX)"
probe "18-output-file" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -O $OUT_FILE"
echo "=== output file content (first 20 lines) ===" >> "${CMD_DIR}/18-output-file.out"
head -20 "$OUT_FILE" >> "${CMD_DIR}/18-output-file.out" 2>/dev/null || true
rm -f "$OUT_FILE"

# P19: diff identical files (same path twice).
probe "19-identical" "tldr diff backend/providers/yahoo.py backend/providers/yahoo.py"

# P20: bad --lang.
probe "20-bad-lang" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -l brainfuck"

# P21: -l python explicit.
probe "21-lang-python" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -l python"

# P22: -l typescript on python.
probe "22-lang-mismatch" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -l typescript"

# P23: dir vs file (granularity mismatch).
probe "23-dir-vs-file" "tldr diff backend backend/providers/yahoo.py"

# P24: -q quiet.
probe "24-quiet" "tldr diff backend/providers/yahoo.py backend/providers/dhan.py -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
