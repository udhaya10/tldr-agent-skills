#!/usr/bin/env bash
# Regenerates all probe captures for `tldr structure`.
# Usage: bash research/tldr/overview/structure.probes/probe.sh

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

echo "Probing tldr structure against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path on a single file
probe "01-happy" "tldr structure backend/db.py"

# P02: happy path on a directory (realistic scale)
probe "02-happy-scale" "tldr structure backend"

# P03: required input omitted -- N/A for `structure` (path defaults to '.')

# P04: non-existent path
probe "04-badpath" "tldr structure /no/such/path/definitely/missing"

# P05: rejected format
probe "05-format-reject-sarif" "tldr structure backend/db.py -f sarif"

# P06: alternate accepted format
probe "06-format-text" "tldr structure backend/db.py -f text"

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: --max-results cap (5 files)
probe "07-max-results-5" "tldr structure backend -m 5"

# P08: explicit --lang flag (matches detection)
probe "08-lang-python" "tldr structure backend/db.py -l python"

# P09: explicit --lang flag (mismatched — Rust against Python file)
probe "09-lang-mismatch" "tldr structure backend/db.py -l rust"

# P10: format-compact
probe "10-format-compact" "tldr structure backend/db.py -f compact"

# P11: empty directory (no source files match)
mkdir -p /tmp/tldr-structure-empty
probe "11-empty-dir" "tldr structure /tmp/tldr-structure-empty"
rmdir /tmp/tldr-structure-empty 2>/dev/null || true

# P12: cold-vs-warm daemon comparison (with explicit warm step per protocol)
tldr daemon stop > /dev/null 2>&1 || true
probe "12-cold-daemon" "tldr structure backend/db.py"
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1
tldr warm "$TARGET_REPO" > /dev/null 2>&1
probe "13-warm-daemon" "tldr structure backend/db.py"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
