#!/usr/bin/env bash
# Regenerates all probe captures for `tldr deps`.
#
# Usage:   bash research/tldr/ops/deps.probes/probe.sh
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

echo "Probing tldr deps against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr deps backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr deps backend"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr deps /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr deps backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr deps backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr deps backend/providers -f compact"

# P08: format dot (SUPPORTED for deps).
probe "08-format-dot" "tldr deps backend/providers -f dot"

# P09: --include-external.
probe "09-include-external" "tldr deps backend/providers --include-external"

# P10: --collapse-packages.
probe "10-collapse-packages" "tldr deps backend/providers --collapse-packages"

# P11: --depth 1.
probe "11-depth-low" "tldr deps backend --depth 1"

# P12: --depth 0 (edge).
probe "12-depth-zero" "tldr deps backend --depth 0"

# P13: --show-cycles.
probe "13-show-cycles" "tldr deps backend --show-cycles"

# P14: --max-cycle-length 1.
probe "14-max-cycle-len-low" "tldr deps backend --max-cycle-length 1"

# P15: -l python explicit.
probe "15-lang-python" "tldr deps backend -l python"

# P16: -l typescript on python.
probe "16-lang-mismatch" "tldr deps backend -l typescript"

# P17: bad --lang.
probe "17-bad-lang" "tldr deps backend -l brainfuck"

# P18: legacy -o text.
probe "18-output-flag-text" "tldr deps backend/providers -o text"

# P19: legacy -o dot.
probe "19-output-flag-dot" "tldr deps backend/providers -o dot"

# P20: legacy -o bogus.
probe "20-output-flag-bogus" "tldr deps backend/providers -o wat"

# P21: empty dir (schema-cleanup-v2 P2.BUG-10 short-circuit).
EMPTY_DIR="$(mktemp -d)"
probe "21-empty-dir" "tldr deps $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P22: non-source markdown.
probe "22-non-source-md" "tldr deps README.md"

# P23: file as PATH.
probe "23-file-as-path" "tldr deps backend/providers/yahoo.py"

# P24: -q quiet.
probe "24-quiet" "tldr deps backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
