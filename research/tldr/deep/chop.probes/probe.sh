#!/usr/bin/env bash
# Regenerates all probe captures for `tldr chop`.
#
# Usage:   bash research/tldr/deep/chop.probes/probe.sh
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

echo "Probing tldr chop against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — _to_finite_float spans lines 18-25. Chop from 21 to 25
# (lines anchored by PDG nodes; 20 and 24 produce empty chops because
# they're a docstring/comment/brace line — see Source Code Reality).
probe "01-happy" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25"

# P02: happy-scale — fetch_historical_data spans 38-85. Chop from 40 to 80.
probe "02-happy-scale" "tldr chop backend/providers/yahoo.py fetch_historical_data 40 80"

# P03: missing required arg — target_line omitted.
probe "03-missing-arg" "tldr chop backend/providers/yahoo.py _to_finite_float 20"

# P04: bad path.
probe "04-badpath" "tldr chop /no/such/file.py some_fn 1 10"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f text"

# P07: format compact.
probe "07-format-compact" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f dot"

# P09: same source and target line.
probe "09-same-line" "tldr chop backend/providers/yahoo.py _to_finite_float 20 20"

# P10: source > target (reversed direction).
probe "10-reversed" "tldr chop backend/providers/yahoo.py _to_finite_float 25 20"

# P11: function not found.
probe "11-function-not-found" "tldr chop backend/providers/yahoo.py no_such_function 10 20"

# P12: source line out of function range.
probe "12-source-oor" "tldr chop backend/providers/yahoo.py _to_finite_float 99999 100000"

# P13: target line out of function range.
probe "13-target-oor" "tldr chop backend/providers/yahoo.py _to_finite_float 20 99999"

# P14: bad --lang.
probe "14-bad-lang" "tldr chop backend/providers/yahoo.py _to_finite_float 20 24 -l brainfuck"

# P14a: in-range line that has NO PDG node (docstring/brace/comment).
# Demonstrates the silent-empty-chop failure mode where the line is
# valid (inside the function bounds) but no PDG node anchors there.
probe "14a-empty-pdg-node" "tldr chop backend/providers/yahoo.py _to_finite_float 20 24"

# P15: legacy hidden -o text output flag.
probe "15-output-flag-text" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -o text"

# P16: non-source file (markdown) — silent language fallback?
probe "16-non-source-md" "tldr chop README.md anything 1 10"

# P17: -q quiet.
probe "17-quiet" "tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -q"

# P18: negative source line — clap may reject due to u32 type.
probe "18-negative-line" "tldr chop backend/providers/yahoo.py _to_finite_float -5 24"

# P19: zero source line (u32 allows but semantically invalid).
probe "19-zero-line" "tldr chop backend/providers/yahoo.py _to_finite_float 0 24"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
