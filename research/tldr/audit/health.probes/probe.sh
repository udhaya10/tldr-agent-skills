#!/usr/bin/env bash
# Regenerates all probe captures for `tldr health`.
# Usage: bash research/tldr/audit/health.probes/probe.sh
#
# `health` is an aggregator that spawns 6 sub-analyzers (complexity, cohesion,
# dead_code, martin, coupling, similarity). It does NOT use the daemon route.
# To keep probes fast, most use `backend/providers` (4 files). P02 uses the
# full `backend/` for realistic-scale evidence.

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

echo "Probing tldr health against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Note: `health` does NOT use the daemon route — health.rs has no
# `try_daemon_route` call. Cold/warm daemon probes are intentionally omitted.

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, small input + quick + summary (fastest combo)
probe "01-happy" "tldr health backend/providers --quick --summary"

# P02: happy scale — full backend (medium-size, ~56 files)
probe "02-happy-scale" "tldr health backend --quick --summary"

# P03: required input omitted -- N/A for `health` (path defaults to '.')

# P04: bad path
probe "04-badpath" "tldr health /no/such/path/definitely/missing"

# P05: rejected format
probe "05-format-reject-sarif" "tldr health backend/providers --quick -f sarif"

# P06: alternate accepted format
probe "06-format-text" "tldr health backend/providers --quick -f text"

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: --detail complexity (valid sub-analyzer)
probe "07-detail-complexity" "tldr health backend/providers --quick --detail complexity"

# P08: --detail invalid -- should reject via custom value_parser
probe "08-detail-invalid" "tldr health backend/providers --quick --detail bogus"

# P09: --quick + --detail=coupling conflict (T23 mitigation)
probe "09-quick-coupling-conflict" "tldr health backend/providers --quick --detail coupling"

# P10: --quick + --detail=similarity conflict (T23 mitigation)
probe "10-quick-similarity-conflict" "tldr health backend/providers --quick --detail similarity"

# P11: --preset strict
probe "11-preset-strict" "tldr health backend/providers --quick --summary --preset strict"

# P12: --preset relaxed
probe "12-preset-relaxed" "tldr health backend/providers --quick --summary --preset relaxed"

# P13: empty directory — should short-circuit per schema-cleanup-v2 (P2.BUG-10)
mkdir -p /tmp/tldr-health-empty
probe "13-empty-dir" "tldr health /tmp/tldr-health-empty"
rmdir /tmp/tldr-health-empty 2>/dev/null || true

# P14: --max-items cap (for coupling/similarity arrays in full mode)
probe "14-max-items-5" "tldr health backend/providers --max-items 5 --summary"

# P15: full mode (no --quick) — exercises coupling + similarity
probe "15-full-mode" "tldr health backend/providers --summary"

# P16: format-compact
probe "16-format-compact" "tldr health backend/providers --quick --summary -f compact"

# P17: single file as path (--help says "file or directory")
probe "17-single-file" "tldr health backend/db.py --quick --summary"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
