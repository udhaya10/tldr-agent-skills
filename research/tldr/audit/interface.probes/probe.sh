#!/usr/bin/env bash
# Regenerates all probe captures for `tldr interface`.
#
# Usage:   bash research/tldr/audit/interface.probes/probe.sh
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

echo "Probing tldr interface against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single file.
probe "01-happy" "tldr interface backend/providers/base.py"

# P02: happy-scale — directory.
probe "02-happy-scale" "tldr interface backend/providers"

# P03: missing required arg.
probe "03-missing-arg" "tldr interface"

# P04: bad path.
probe "04-badpath" "tldr interface /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr interface backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr interface backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr interface backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr interface backend/providers -f dot"

# P09: --project-root.
probe "09-project-root" "tldr interface backend/providers/yahoo.py --project-root backend"

# P10: bad --lang.
probe "10-bad-lang" "tldr interface backend/providers -l brainfuck"

# P11: -l python explicit.
probe "11-lang-python" "tldr interface backend/providers -l python"

# P12: -l typescript on python.
probe "12-lang-mismatch" "tldr interface backend/providers -l typescript"

# P13: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "13-empty-dir" "tldr interface $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P14: non-source markdown.
probe "14-non-source-md" "tldr interface README.md"

# P15: -q quiet.
probe "15-quiet" "tldr interface backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
