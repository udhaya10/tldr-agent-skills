#!/usr/bin/env bash
# Regenerates all probe captures for `tldr complexity`.
#
# Usage:   bash research/tldr/audit/complexity.probes/probe.sh
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

echo "Probing tldr complexity against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small function.
probe "01-happy" "tldr complexity backend/providers/yahoo.py _to_finite_float"

# P02: happy-scale — larger function.
probe "02-happy-scale" "tldr complexity backend/providers/yahoo.py fetch_historical_data"

# P03: missing required arg.
probe "03-missing-arg" "tldr complexity backend/providers/yahoo.py"

# P04: bad path.
probe "04-badpath" "tldr complexity /no/such/file.py some_fn"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr complexity backend/providers/yahoo.py _to_finite_float -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr complexity backend/providers/yahoo.py _to_finite_float -f text"

# P07: format compact.
probe "07-format-compact" "tldr complexity backend/providers/yahoo.py _to_finite_float -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr complexity backend/providers/yahoo.py _to_finite_float -f dot"

# P09: function not found.
probe "09-function-not-found" "tldr complexity backend/providers/yahoo.py no_such_function"

# P10: bad --lang.
probe "10-bad-lang" "tldr complexity backend/providers/yahoo.py _to_finite_float -l brainfuck"

# P11: non-source markdown file.
probe "11-non-source-md" "tldr complexity README.md anything"

# P12: directory as FILE.
probe "12-directory-arg" "tldr complexity backend anything"

# P13: -l python explicit on .py.
probe "13-lang-python" "tldr complexity backend/providers/yahoo.py _to_finite_float -l python"

# P14: -l typescript on .py — silent mismatch.
probe "14-lang-mismatch" "tldr complexity backend/providers/yahoo.py _to_finite_float -l typescript"

# P15: -q quiet.
probe "15-quiet" "tldr complexity backend/providers/yahoo.py _to_finite_float -q"

# -----------------------------------------------------------------------------
# Daemon route probes
# -----------------------------------------------------------------------------

# P16: cold daemon.
tldr daemon stop > /dev/null 2>&1 || true
probe "16-cold-daemon" "tldr complexity backend/providers/yahoo.py fetch_historical_data"

# P17: warm daemon.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "17-warm-daemon" "tldr complexity backend/providers/yahoo.py fetch_historical_data"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
