#!/usr/bin/env bash
# Regenerates all probe captures for `tldr smells`.
#
# Usage:   bash research/tldr/audit/smells.probes/probe.sh
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

echo "Probing tldr smells against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr smells backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr smells backend"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr smells /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr smells backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr smells backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr smells backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr smells backend/providers -f dot"

# P09: --threshold strict.
probe "09-threshold-strict" "tldr smells backend/providers -t strict"

# P10: --threshold relaxed.
probe "10-threshold-relaxed" "tldr smells backend/providers -t relaxed"

# P11: --threshold bogus (clap rejection).
probe "11-threshold-bogus" "tldr smells backend/providers -t wat"

# P12: --smell-type god-class.
probe "12-smell-type-godclass" "tldr smells backend/providers -s god-class"

# P13: --smell-type bogus.
probe "13-smell-type-bogus" "tldr smells backend/providers -s wat"

# P14: --smell-type requiring deep (low-cohesion without --deep).
probe "14-smell-needs-deep" "tldr smells backend/providers -s low-cohesion"

# P15: --suggest.
probe "15-suggest" "tldr smells backend/providers --suggest"

# P16: --deep.
probe "16-deep" "tldr smells backend/providers --deep"

# P17: --deep with --smell-type low-cohesion.
probe "17-deep-low-cohesion" "tldr smells backend/providers --deep -s low-cohesion"

# P18: --no-default-ignore.
probe "18-no-default-ignore" "tldr smells backend/providers --no-default-ignore"

# P19: --files (specific file).
probe "19-files-specific" "tldr smells backend --files backend/providers/yahoo.py"

# P20: --files with traversal (should error).
probe "20-files-traversal" "tldr smells backend --files ../../../../etc/passwd"

# P21: --include-tests.
probe "21-include-tests" "tldr smells backend --include-tests"

# P22: bad --lang.
probe "22-bad-lang" "tldr smells backend/providers -l brainfuck"

# P23: -l python explicit.
probe "23-lang-python" "tldr smells backend/providers -l python"

# P24: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "24-empty-dir" "tldr smells $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P25: non-source markdown.
probe "25-non-source-md" "tldr smells README.md"

# P26: -q quiet (should suppress deep-only warning).
probe "26-quiet" "tldr smells backend/providers -q"

# P27: cold daemon.
tldr daemon stop > /dev/null 2>&1 || true
probe "27-cold-daemon" "tldr smells backend/providers"

# P28: warm daemon.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "28-warm-daemon" "tldr smells backend/providers"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
