#!/usr/bin/env bash
# Regenerates all probe captures for `tldr tree`.
# Usage: bash research/tldr/overview/tree.probes/probe.sh

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

echo "Probing tldr tree against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Ensure daemon is warm for happy probes (tree hits try_daemon_route).
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, smallest meaningful input (a subdirectory, filtered by ext)
probe "01-happy" "tldr tree backend --ext .py"

# P02: happy path, realistic scale (whole Stock-Monitor repo)
probe "02-happy-scale" "tldr tree . --ext .py"

# P03: required input omitted -- N/A for `tree` (path defaults to '.')
#      Per protocol §4.2, the dossier carries an N/A marker; no capture needed.

# P04: non-existent path
probe "04-badpath" "tldr tree /no/such/path/definitely/missing"

# P05: rejected format (tree does NOT support sarif/dot)
probe "05-format-reject-sarif" "tldr tree backend --ext .py -f sarif"

# P06: alternate accepted format (text)
probe "06-format-text" "tldr tree backend --ext .py -f text"

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: --include-hidden flag toggle (without it, .git/.venv are excluded)
probe "07-include-hidden" "tldr tree backend -H --ext .py"

# P08: multi-extension filter
probe "08-multi-ext" "tldr tree . --ext .py --ext .js"

# P09: no --ext filter (entire dir tree, may include large amounts of content)
probe "09-no-ext-filter" "tldr tree backend"

# P10: compact format
probe "10-format-compact" "tldr tree backend --ext .py -f compact"

# P11: cold-daemon comparison (stop daemon, run again, restart for cleanup)
tldr daemon stop > /dev/null 2>&1 || true
probe "11-cold-daemon" "tldr tree backend --ext .py"
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
