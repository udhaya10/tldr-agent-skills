#!/usr/bin/env bash
# Regenerates all probe captures for `tldr stats`.
#
# Usage:   bash research/tldr/ops/stats.probes/probe.sh
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

echo "Probing tldr stats ..."
cd "$TARGET_REPO" || cd "$HOME"

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — read stats (may be empty if daemon has never run).
probe "01-happy" "tldr stats"

# P02: happy-scale — text format.
probe "02-happy-scale" "tldr stats -f text"

# P03: no required args — N/A.
echo "No required args — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: no PATH/file arg — N/A.
echo "No PATH/file arg — N/A row in matrix" > "${CMD_DIR}/04-badpath.cmd"
echo "" > "${CMD_DIR}/04-badpath.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/04-badpath.err"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr stats -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text (explicit).
probe "06-format-text" "tldr stats -f text"

# P07: format compact.
probe "07-format-compact" "tldr stats -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr stats -f dot"

# P09: format json explicit.
probe "09-format-json" "tldr stats -f json"

# P10: bad --lang.
probe "10-bad-lang" "tldr stats -l brainfuck"

# P11: -l python explicit (should be IGNORED — stats is lang-agnostic).
probe "11-lang-python" "tldr stats -l python"

# P12: -q quiet.
probe "12-quiet" "tldr stats -q"

# P13: -v verbose.
probe "13-verbose" "tldr stats -v"

# P14: stats from non-project dir (stats is global — CWD-independent).
TMP_DIR="$(mktemp -d)"
probe "14-from-tmp" "cd $TMP_DIR && tldr stats"
rmdir "$TMP_DIR"

# P15: stats with extra positional (clap should reject).
probe "15-extra-arg" "tldr stats extra-positional"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
