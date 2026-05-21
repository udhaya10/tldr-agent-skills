#!/usr/bin/env bash
# Regenerates all probe captures for `tldr search`.
# Usage: bash research/tldr/search/search.probes/probe.sh

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

echo "Probing tldr search against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Note: `search` does NOT use the daemon route (verified at search.rs — no
# `try_daemon_route` call). Cold/warm daemon probes are intentionally omitted.

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, small target
probe "01-happy" 'tldr search "database" backend'

# P02: happy path, realistic scale (full repo)
probe "02-happy-scale" 'tldr search "database" .'

# P03: required positional omitted (<QUERY> is required)
probe "03-missing-arg" "tldr search"

# P04: bad path
probe "04-badpath" 'tldr search "database" /no/such/path/definitely/missing'

# P05: rejected format
probe "05-format-reject-sarif" 'tldr search "database" backend -f sarif'

# P06: alternate accepted format
probe "06-format-text" 'tldr search "database" backend -f text'

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: --top-k cap (3 results)
probe "07-top-k-3" 'tldr search "database" backend -k 3'

# P08: --no-callgraph (faster, no caller/callee enrichment)
probe "08-no-callgraph" 'tldr search "database" backend --no-callgraph'

# P09: --regex mode (regex pattern query)
probe "09-regex" 'tldr search "ensure_.*_table" backend --regex'

# P10: --hybrid mode (BM25 + regex filter)
probe "10-hybrid" 'tldr search "database connection" backend --hybrid ".*sqlite.*"'

# P11: --regex and --hybrid together (should conflict per clap)
probe "11-conflict-regex-hybrid" 'tldr search "x" backend --regex --hybrid "y"'

# P12: all-stopwords query — should trigger literal-fallback per search.rs comment
probe "12-all-stopwords" 'tldr search "def" backend'

# P13: zero-result query (nonsense string)
probe "13-zero-results" 'tldr search "zzzqqqxxxnotapresent" backend'

# P14: format-compact
probe "14-format-compact" 'tldr search "database" backend -f compact'

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
