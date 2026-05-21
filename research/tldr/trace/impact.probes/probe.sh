#!/usr/bin/env bash
# Regenerates all probe captures for `tldr impact`.
# Usage: bash research/tldr/trace/impact.probes/probe.sh
#
# `impact` is one of the commands where the daemon route matters most.
# Probes P15/P16 explicitly cycle the daemon and run `tldr warm` so the
# warm-cache observation is real, not a non-finding.

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

echo "Probing tldr impact against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path on a well-known, heavily-called function (small scope)
probe "01-happy" "tldr impact get_db_connection backend"

# P02: happy scale -- same function, full repo as project root
probe "02-happy-scale" "tldr impact get_db_connection ."

# P03: required positional <FUNCTION> omitted
probe "03-missing-arg" "tldr impact"

# P04: bad path (project root doesn't exist)
probe "04-badpath" "tldr impact get_db_connection /no/such/path/definitely/missing"

# P05: rejected format -- `sarif` not in DOT_SUPPORTED nor SARIF_SUPPORTED for impact
probe "05-format-reject-sarif" "tldr impact get_db_connection backend -f sarif"

# P06: alternate accepted format
probe "06-format-text" "tldr impact get_db_connection backend -f text"

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: -f dot -- impact IS in DOT_SUPPORTED per output.rs validator
probe "07-format-dot" "tldr impact get_db_connection backend -f dot"

# P08: shallow depth
probe "08-depth-1" "tldr impact get_db_connection backend -d 1"

# P09: deep depth
probe "09-depth-10" "tldr impact get_db_connection backend -d 10"

# P10: --file filter (restrict to a single file)
probe "10-file-filter" "tldr impact get_db_connection backend --file backend/api.py"

# P11: --type-aware flag (source notes: registered but not fully implemented)
probe "11-type-aware" "tldr impact get_db_connection backend --type-aware"

# P12: function that does not exist anywhere
probe "12-function-not-found" "tldr impact zzz_nonexistent_function backend"

# P13: file passed as PATH (should reject per require_directory)
probe "13-file-as-path" "tldr impact get_db_connection backend/db.py"

# P14: format-compact
probe "14-format-compact" "tldr impact get_db_connection backend -f compact"

# P15: cold daemon
tldr daemon stop > /dev/null 2>&1 || true
probe "15-cold-daemon" "tldr impact get_db_connection backend"

# P16: warm daemon (start + warm explicitly per protocol §4.3)
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1
tldr warm "$TARGET_REPO" > /dev/null 2>&1
probe "16-warm-daemon" "tldr impact get_db_connection backend"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
