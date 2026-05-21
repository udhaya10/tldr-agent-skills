#!/usr/bin/env bash
# Regenerates all probe captures for `tldr inheritance`.
#
# Usage:   bash research/tldr/audit/inheritance.probes/probe.sh
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

echo "Probing tldr inheritance against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir with classes.
probe "01-happy" "tldr inheritance backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr inheritance backend"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr inheritance /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr inheritance backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr inheritance backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr inheritance backend/providers -f compact"

# P08: format dot (SUPPORTED).
probe "08-format-dot" "tldr inheritance backend/providers -f dot"

# P09: --class focus.
probe "09-class-focus" "tldr inheritance backend/providers --class YahooProvider"

# P10: --class not found.
probe "10-class-not-found" "tldr inheritance backend/providers --class NoSuchClass"

# P11: --depth requires --class — without --class.
probe "11-depth-without-class" "tldr inheritance backend/providers --depth 2"

# P12: --depth with --class.
probe "12-depth-with-class" "tldr inheritance backend/providers --class YahooProvider --depth 1"

# P13: --no-patterns.
probe "13-no-patterns" "tldr inheritance backend/providers --no-patterns"

# P14: --no-external.
probe "14-no-external" "tldr inheritance backend/providers --no-external"

# P15: bad --lang.
probe "15-bad-lang" "tldr inheritance backend/providers -l brainfuck"

# P16: -l python explicit.
probe "16-lang-python" "tldr inheritance backend/providers -l python"

# P17: -l typescript on python.
probe "17-lang-mismatch" "tldr inheritance backend/providers -l typescript"

# P18: legacy -o dot.
probe "18-legacy-output-dot" "tldr inheritance backend/providers -o dot"

# P19: legacy -o bogus.
probe "19-legacy-output-bogus" "tldr inheritance backend/providers -o wat"

# P20: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "20-empty-dir" "tldr inheritance $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P21: non-source markdown.
probe "21-non-source-md" "tldr inheritance README.md"

# P22: single Python file.
probe "22-single-file" "tldr inheritance backend/providers/base.py"

# P23: -q quiet.
probe "23-quiet" "tldr inheritance backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
