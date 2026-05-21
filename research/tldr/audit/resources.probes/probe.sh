#!/usr/bin/env bash
# Regenerates all probe captures for `tldr resources`.
#
# Usage:   bash research/tldr/audit/resources.probes/probe.sh
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

echo "Probing tldr resources against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single file, default checks.
probe "01-happy" "tldr resources backend/providers/yahoo.py"

# P02: happy-scale — with function filter.
probe "02-happy-scale" "tldr resources backend/providers/yahoo.py fetch_historical_data"

# P03: missing required arg.
probe "03-missing-arg" "tldr resources"

# P04: bad path.
probe "04-badpath" "tldr resources /no/such/file.py"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr resources backend/providers/yahoo.py -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr resources backend/providers/yahoo.py -f text"

# P07: format compact.
probe "07-format-compact" "tldr resources backend/providers/yahoo.py -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr resources backend/providers/yahoo.py -f dot"

# P09: --check-leaks.
probe "09-check-leaks" "tldr resources backend/providers/yahoo.py --check-leaks"

# P10: --check-double-close.
probe "10-check-double-close" "tldr resources backend/providers/yahoo.py --check-double-close"

# P11: --check-use-after-close.
probe "11-check-uac" "tldr resources backend/providers/yahoo.py --check-use-after-close"

# P12: --check-all.
probe "12-check-all" "tldr resources backend/providers/yahoo.py --check-all"

# P13: --suggest-context.
probe "13-suggest-context" "tldr resources backend/providers/yahoo.py --suggest-context"

# P14: --show-paths.
probe "14-show-paths" "tldr resources backend/providers/yahoo.py --show-paths"

# P15: --constraints.
probe "15-constraints" "tldr resources backend/providers/yahoo.py --constraints"

# P16: --summary.
probe "16-summary" "tldr resources backend/providers/yahoo.py --summary"

# P17: --project-root.
probe "17-project-root" "tldr resources backend/providers/yahoo.py --project-root backend"

# P18: function not found.
probe "18-function-not-found" "tldr resources backend/providers/yahoo.py no_such_function"

# P19: bad --lang.
probe "19-bad-lang" "tldr resources backend/providers/yahoo.py -l brainfuck"

# P20: -l python explicit.
probe "20-lang-python" "tldr resources backend/providers/yahoo.py -l python"

# P21: -l typescript on python.
probe "21-lang-mismatch" "tldr resources backend/providers/yahoo.py -l typescript"

# P22: non-source markdown.
probe "22-non-source-md" "tldr resources README.md"

# P23: directory as FILE.
probe "23-directory-arg" "tldr resources backend/providers"

# P24: -o legacy text.
probe "24-output-flag-text" "tldr resources backend/providers/yahoo.py -o text"

# P25: -q quiet.
probe "25-quiet" "tldr resources backend/providers/yahoo.py -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
