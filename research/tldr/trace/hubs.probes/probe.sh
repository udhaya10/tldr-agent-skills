#!/usr/bin/env bash
# Regenerates all probe captures for `tldr hubs`.
#
# Usage:   bash research/tldr/trace/hubs.probes/probe.sh
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

echo "Probing tldr hubs against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr hubs backend/providers -l python"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr hubs backend -l python"

# P03: missing required arg — PATH defaults to '.'.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr hubs /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr hubs backend/providers -l python -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr hubs backend/providers -l python -f text"

# P07: format compact.
probe "07-format-compact" "tldr hubs backend/providers -l python -f compact"

# P08: format dot — hubs IS in DOT_SUPPORTED.
probe "08-format-dot" "tldr hubs backend/providers -l python -f dot"

# P09: --top 1 — single top hub.
probe "09-top-one" "tldr hubs backend -l python --top 1"

# P10: --top 100 — large top-N.
probe "10-top-hundred" "tldr hubs backend -l python --top 100"

# P11: --algorithm indegree only.
probe "11-algo-indegree" "tldr hubs backend -l python --algorithm indegree"

# P12: --algorithm pagerank.
probe "12-algo-pagerank" "tldr hubs backend -l python --algorithm pagerank"

# P13: --algorithm betweenness (slowest).
probe "13-algo-betweenness" "tldr hubs backend -l python --algorithm betweenness"

# P14: invalid --algorithm (clap rejection).
probe "14-algo-bogus" "tldr hubs backend -l python --algorithm wat"

# P15: --threshold 0.5 — score threshold.
probe "15-threshold-mid" "tldr hubs backend -l python --threshold 0.5"

# P16: --threshold 0.99 — very high threshold (likely empty).
probe "16-threshold-high" "tldr hubs backend -l python --threshold 0.99"

# P17: --threshold out of range (1.5).
probe "17-threshold-oor" "tldr hubs backend -l python --threshold 1.5"

# P18: --threshold negative.
probe "18-threshold-negative" "tldr hubs backend -l python --threshold -0.1"

# P19: bad --lang.
probe "19-bad-lang" "tldr hubs backend -l brainfuck"

# P20: PATH as a FILE (not directory) — should hit require_directory check.
probe "20-file-arg" "tldr hubs backend/providers/base.py"

# P21: empty directory.
EMPTY_DIR="$(mktemp -d)"
probe "21-empty-dir" "tldr hubs $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P22: -q quiet.
probe "22-quiet" "tldr hubs backend/providers -l python -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
