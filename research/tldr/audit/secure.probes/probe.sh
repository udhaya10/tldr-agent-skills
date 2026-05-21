#!/usr/bin/env bash
# Regenerates all probe captures for `tldr secure`.
#
# Usage:   bash research/tldr/audit/secure.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# SLOW COMMAND per Journal 04 §5 (Slow command warning): full-mode
# secure can take >30s. Happy probes scope to backend/providers/ (4 files).

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

echo "Probing tldr secure against $TARGET_REPO (scoped to backend/providers/ for happy) ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir (4 files).
probe "01-happy" "tldr secure backend/providers --quick"

# P02: happy-scale — quick mode on full backend.
probe "02-happy-scale" "tldr secure backend --quick"

# P03: missing required arg.
probe "03-missing-arg" "tldr secure"

# P04: bad path.
probe "04-badpath" "tldr secure /no/such/dir"

# P05: format reject dot (sarif may be supported — try dot).
probe "05-format-reject-dot" "tldr secure backend/providers --quick -f dot"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr secure backend/providers --quick -f text"

# P07: format compact.
probe "07-format-compact" "tldr secure backend/providers --quick -f compact"

# P08: format sarif (try, see if rejected).
probe "08-format-sarif" "tldr secure backend/providers --quick -f sarif"

# P09: --quick mode.
probe "09-quick" "tldr secure backend/providers --quick"

# P10: --detail subanalysis.
probe "10-detail-taint" "tldr secure backend/providers --quick --detail taint"

# P11: --detail bogus.
probe "11-detail-bogus" "tldr secure backend/providers --quick --detail wat"

# P12: -o output to file.
OUT_FILE="$(mktemp -t secure-out.XXXXXX)"
probe "12-output-file" "tldr secure backend/providers --quick -o $OUT_FILE"
echo "=== output file content (first 40 lines) ===" >> "${CMD_DIR}/12-output-file.out"
head -40 "$OUT_FILE" >> "${CMD_DIR}/12-output-file.out" 2>/dev/null || true
rm -f "$OUT_FILE"

# P13: --no-default-ignore.
probe "13-no-default-ignore" "tldr secure backend/providers --quick --no-default-ignore"

# P14: --include-tests.
probe "14-include-tests" "tldr secure backend --quick --include-tests"

# P15: bad --lang.
probe "15-bad-lang" "tldr secure backend/providers --quick -l brainfuck"

# P16: -l python explicit.
probe "16-lang-python" "tldr secure backend/providers --quick -l python"

# P17: -l typescript on python.
probe "17-lang-mismatch" "tldr secure backend/providers --quick -l typescript"

# P18: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "18-empty-dir" "tldr secure $EMPTY_DIR --quick"
rmdir "$EMPTY_DIR"

# P19: non-source markdown.
probe "19-non-source-md" "tldr secure README.md --quick"

# P20: single python file.
probe "20-single-file" "tldr secure backend/providers/yahoo.py --quick"

# P21: -q quiet.
probe "21-quiet" "tldr secure backend/providers --quick -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
