#!/usr/bin/env bash
# Regenerates all probe captures for `tldr reaching-defs`.
#
# Usage:   bash research/tldr/deep/reaching-defs.probes/probe.sh
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

echo "Probing tldr reaching-defs against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small function.
probe "01-happy" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float"

# P02: happy-scale — larger function with more defs.
probe "02-happy-scale" "tldr reaching-defs backend/providers/yahoo.py fetch_historical_data"

# P03: missing required arg — FUNCTION omitted.
probe "03-missing-arg" "tldr reaching-defs backend/providers/yahoo.py"

# P04: bad path.
probe "04-badpath" "tldr reaching-defs /no/such/file.py some_fn"

# P05: format reject sarif. (Source code claims fallback to JSON;
# but global validate_format_for_command may reject first.)
probe "05-format-reject-sarif" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f text"

# P07: format compact.
probe "07-format-compact" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f compact"

# P08: format dot. (Source code says silent fallback to JSON.)
probe "08-format-dot" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f dot"

# P09: --var filter (filter to specific variable).
probe "09-var-filter" "tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --var df"

# P10: --line filter — only show definitions reaching this line.
probe "10-line-filter" "tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --line 60"

# P11: --show-in-out — include per-block GEN/KILL/IN/OUT.
probe "11-show-in-out" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float --show-in-out"

# P12: --chains-only — show only chains.
probe "12-chains-only" "tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --chains-only"

# P13: --show-chains=false — hide chains.
probe "13-show-chains-false" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float --show-chains=false"

# P14: --show-uninitialized=false — hide uninit warnings.
probe "14-show-uninit-false" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float --show-uninitialized=false"

# P15: --params — comma-separated parameter names.
probe "15-params" "tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --params 'self,symbol,start_date,end_date'"

# P16: function not found.
probe "16-function-not-found" "tldr reaching-defs backend/providers/yahoo.py no_such_function"

# P17: bad --lang.
probe "17-bad-lang" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float -l brainfuck"

# P18: --var that doesn't exist in the function.
probe "18-var-not-found" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float --var nonexistent_var"

# P19: --line out of function range.
probe "19-line-oor" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float --line 999999"

# P20: -q quiet.
probe "20-quiet" "tldr reaching-defs backend/providers/yahoo.py _to_finite_float -q"

# P21: non-source markdown file.
probe "21-non-source-md" "tldr reaching-defs README.md anything"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
