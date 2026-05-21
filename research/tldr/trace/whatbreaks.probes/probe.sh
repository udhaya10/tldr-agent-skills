#!/usr/bin/env bash
# Regenerates all probe captures for `tldr whatbreaks`.
#
# Usage:   bash research/tldr/trace/whatbreaks.probes/probe.sh
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

echo "Probing tldr whatbreaks against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — function target (auto-detect).
probe "01-happy-function" "tldr whatbreaks fetch_historical_data backend -l python"

# P02: happy-scale — file target (auto-detect should pick file).
probe "02-happy-file" "tldr whatbreaks backend/providers/base.py backend -l python"

# P03: missing required arg — TARGET omitted.
probe "03-missing-arg" "tldr whatbreaks"

# P04: bad path.
probe "04-badpath" "tldr whatbreaks foo /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr whatbreaks fetch_historical_data backend -l python -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr whatbreaks fetch_historical_data backend -l python -f text"

# P07: format compact.
probe "07-format-compact" "tldr whatbreaks fetch_historical_data backend -l python -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr whatbreaks fetch_historical_data backend -l python -f dot"

# P09: --type function — force function path.
probe "09-type-function" "tldr whatbreaks backend/providers/base.py backend -l python --type function"

# P10: --type file — force file path even on a function name.
probe "10-type-file" "tldr whatbreaks fetch_historical_data backend -l python --type file"

# P11: --type module — module target (dotted python path).
probe "11-type-module" "tldr whatbreaks backend.providers.base backend -l python --type module"

# P12: invalid --type.
probe "12-type-bogus" "tldr whatbreaks foo backend -l python --type widget"

# P13: --depth 1 — shallow traversal.
probe "13-depth-one" "tldr whatbreaks fetch_historical_data backend -l python -d 1"

# P14: --depth 10 — deep traversal.
probe "14-depth-ten" "tldr whatbreaks fetch_historical_data backend -l python -d 10"

# P15: --quick — skip slow analyses.
probe "15-quick" "tldr whatbreaks backend/providers/base.py backend -l python --quick"

# P16: PATH as a FILE (not directory) — should hit require_directory check.
probe "16-file-as-path" "tldr whatbreaks foo backend/providers/base.py"

# P17: bad --lang.
probe "17-bad-lang" "tldr whatbreaks fetch_historical_data backend -l brainfuck"

# P18: target not found (function that doesn't exist).
probe "18-target-not-found" "tldr whatbreaks no_such_function_anywhere backend -l python"

# P19: -q quiet.
probe "19-quiet" "tldr whatbreaks fetch_historical_data backend -l python -q"

# P20: module-form target without --type (auto-detect ambiguity).
probe "20-module-autodetect" "tldr whatbreaks backend.providers.base backend -l python"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
