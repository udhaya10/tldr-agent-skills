#!/usr/bin/env bash
# Regenerates all probe captures for `tldr slice`.
# Usage: bash research/tldr/deep/slice.probes/probe.sh
#
# `slice` requires three positionals (<FILE> <FUNCTION> <LINE>) and a known
# correct line number from inside the target function. P15 captures the full
# composition chain (`extract` -> parse line -> `slice`).

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

echo "Probing tldr slice against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path on a small known function
# get_db_connection is at L48 in backend/db.py (verified via tldr extract earlier).
# Slicing from line 49 (the first statement inside the function body).
probe "01-happy" "tldr slice backend/db.py get_db_connection 49"

# P02: happy scale on a larger function (apply_rows_to_database, in backend/scripts/)
probe "02-happy-scale" "tldr slice backend/scripts/apply_classification_theme_workbook.py apply_rows_to_database 130"

# P03: required positionals omitted
probe "03-missing-arg" "tldr slice"

# P04: bad file path
probe "04-badpath" "tldr slice /no/such/file.py foo 1"

# P05: rejected format
probe "05-format-reject-sarif" "tldr slice backend/db.py get_db_connection 49 -f sarif"

# P06: alternate accepted format
probe "06-format-text" "tldr slice backend/db.py get_db_connection 49 -f text"

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: forward direction (what does this line affect?)
probe "07-forward" "tldr slice backend/db.py get_db_connection 49 -d forward"

# P08: --variable filter (narrow trace to one variable)
probe "08-variable-filter" "tldr slice backend/db.py get_db_connection 49 --variable conn"

# P09: line OUTSIDE the function bounds -- should trigger OOR explanation
probe "09-oor-line" "tldr slice backend/db.py get_db_connection 9999"

# P10: function name not present in file
probe "10-fn-not-in-file" "tldr slice backend/db.py zzz_no_such_function 49"

# P11: line = 0 (boundary)
probe "11-line-zero" "tldr slice backend/db.py get_db_connection 0"

# P12: line that's a comment / blank inside the function (e.g., right above the function decl)
probe "12-line-at-decl" "tldr slice backend/db.py get_db_connection 48"

# P13: format-compact
probe "13-format-compact" "tldr slice backend/db.py get_db_connection 49 -f compact"

# P14: cold daemon
tldr daemon stop > /dev/null 2>&1 || true
probe "14-cold-daemon" "tldr slice backend/db.py get_db_connection 49"

# P15: warm daemon (start + warm explicitly per protocol §4.3)
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1
tldr warm "$TARGET_REPO" > /dev/null 2>&1
probe "15-warm-daemon" "tldr slice backend/db.py get_db_connection 49"

# P16: full composition chain — extract first, then slice
# extract -> jq filter to find a function's line -> slice on that line.
probe "16-composition" "tldr extract backend/db.py | jq -r '.functions[] | select(.name==\"is_sqlite_lock_error\") | .line' | xargs -I {} tldr slice backend/db.py is_sqlite_lock_error {}"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
