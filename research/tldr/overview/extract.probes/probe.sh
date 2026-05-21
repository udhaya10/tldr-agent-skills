#!/usr/bin/env bash
# Regenerates all probe captures for `tldr extract`.
# Usage: bash research/tldr/overview/extract.probes/probe.sh

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

echo "Probing tldr extract against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, small file
probe "01-happy" "tldr extract backend/db.py"

# P02: happy path, realistic-scale file
probe "02-happy-scale" "tldr extract backend/api.py"

# P03: required positional omitted (extract requires <FILE>)
probe "03-missing-arg" "tldr extract"

# P04: bad path
probe "04-badpath" "tldr extract /no/such/file/definitely/missing.py"

# P05: rejected format
probe "05-format-reject-sarif" "tldr extract backend/db.py -f sarif"

# P06: alternate accepted format
probe "06-format-text" "tldr extract backend/db.py -f text"

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: explicit --lang flag (matches detection)
probe "07-lang-python" "tldr extract backend/db.py -l python"

# P08: explicit --lang mismatch (Rust against Python)
probe "08-lang-mismatch" "tldr extract backend/db.py -l rust"

# P09: format-compact
probe "09-format-compact" "tldr extract backend/db.py -f compact"

# P10: non-source file (markdown) — language auto-detection on non-code
probe "10-non-source-md" "tldr extract README.md"

# P11: directory passed instead of file
probe "11-directory-arg" "tldr extract backend"

# P12: cold-vs-warm daemon
tldr daemon stop > /dev/null 2>&1 || true
probe "12-cold-daemon" "tldr extract backend/db.py"
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1
tldr warm "$TARGET_REPO" > /dev/null 2>&1
probe "13-warm-daemon" "tldr extract backend/db.py"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
