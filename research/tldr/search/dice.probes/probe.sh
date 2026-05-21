#!/usr/bin/env bash
# Regenerates all probe captures for `tldr dice`.
#
# Usage:   bash research/tldr/search/dice.probes/probe.sh
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

echo "Probing tldr dice against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — compare a file with itself (expect dice=1.0).
probe "01-happy" "tldr dice backend/providers/base.py backend/providers/base.py"

# P02: happy-scale — compare two related sibling files; expected moderate
# similarity since yahoo.py and dhan.py both implement Provider.
probe "02-happy-scale" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py"

# P03: missing required arg — TARGET2 omitted.
probe "03-missing-arg" "tldr dice backend/providers/yahoo.py"

# P04: bad path on TARGET1.
probe "04-badpath" "tldr dice /no/such/file.py backend/providers/yahoo.py"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr dice backend/providers/base.py backend/providers/base.py -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text (via -f) — markdown rendering of the report.
probe "06-format-text" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py -f text"

# P07: format compact.
probe "07-format-compact" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr dice backend/providers/base.py backend/providers/base.py -f dot"

# P09: --normalize none — should yield LOWER coefficient than default (all).
probe "09-norm-none" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize none"

# P10: --normalize identifiers.
probe "10-norm-identifiers" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize identifiers"

# P11: --normalize literals.
probe "11-norm-literals" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize literals"

# P12: --normalize <bogus> — silently falls back to All per source (dice.rs:79).
probe "12-norm-bogus" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize wat"

# P13: --language explicit override.
probe "13-language-flag" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py --language python"

# P14: file::function shorthand — but per source (dice.rs:156-166), the
# function name is IGNORED and the WHOLE FILE is used. Test should yield
# similar result to P02 (file vs file).
probe "14-function-spec" "tldr dice backend/providers/yahoo.py::fetch_historical_data backend/providers/dhan.py::fetch_historical_data"

# P15: file:start:end block target — compare 20-line block ranges.
probe "15-block-range" "tldr dice backend/providers/yahoo.py:38:80 backend/providers/dhan.py:48:100"

# P16: Block out-of-range — start past EOF gives empty block.
probe "16-block-oor" "tldr dice backend/providers/yahoo.py:99999:99999 backend/providers/base.py:99999:99999"

# P17: `-o text` — legacy --output flag. Per source (dice.rs:104-108), when
# --output=text, effective_format becomes Text regardless of -f.
probe "17-output-text" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py -o text"

# P18: -o text with -f compact — does -o win or -f?
probe "18-output-text-vs-format-compact" "tldr dice backend/providers/yahoo.py backend/providers/dhan.py -o text -f compact"

# P19: Mismatched languages (Python vs JSON file).
probe "19-mixed-langs" "tldr dice backend/providers/base.py package.json"

# P20: Both targets identical block range from same file.
probe "20-same-block" "tldr dice backend/providers/base.py:1:10 backend/providers/base.py:1:10"

# P21: -q quiet — suppresses progress.
probe "21-quiet" "tldr dice backend/providers/base.py backend/providers/base.py -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
