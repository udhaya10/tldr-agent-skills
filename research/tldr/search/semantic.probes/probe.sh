#!/usr/bin/env bash
# Regenerates all probe captures for `tldr semantic`.
# Usage: bash research/tldr/search/semantic.probes/probe.sh
#
# Note: first invocation against a given path is SLOW (builds the embedding
# index for every Function chunk). Subsequent probes against the same path
# hit the on-disk embedding cache and run quickly. Probes 01-16 use
# `backend/providers/` (4 files) for fast iteration; P02 uses the full
# `backend/` (~56 files) for realistic-scale evidence.

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

echo "Probing tldr semantic against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Note: `semantic` does NOT use the daemon route. It has its own on-disk
# embedding cache (CacheConfig::default), independent of the daemon. The
# `--no-cache` flag disables this embedding cache, not the daemon cache.

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, smallest meaningful input (4-file directory)
probe "01-happy" 'tldr semantic "database connection" backend/providers'

# P02: happy path, realistic scale (~56 Python files)
probe "02-happy-scale" 'tldr semantic "database connection" backend'

# P03: required positional omitted (<QUERY> is required)
probe "03-missing-arg" "tldr semantic"

# P04: bad path
probe "04-badpath" 'tldr semantic "x" /no/such/path/definitely/missing'

# P05: rejected format
probe "05-format-reject-sarif" 'tldr semantic "database" backend/providers -f sarif'

# P06: alternate accepted format
probe "06-format-text" 'tldr semantic "database" backend/providers -f text'

# -----------------------------------------------------------------------------
# Conditional probes (Journal 04 §4.3)
# -----------------------------------------------------------------------------

# P07: --top cap (3 results)
probe "07-top-3" 'tldr semantic "database" backend/providers -n 3'

# P08: high similarity threshold (likely fewer results)
probe "08-threshold-high" 'tldr semantic "database" backend/providers -t 0.8'

# P09: low similarity threshold (likely more results)
probe "09-threshold-low" 'tldr semantic "database" backend/providers -t 0.1'

# P10: smaller embedding model (arctic-xs)
probe "10-model-xs" 'tldr semantic "database" backend/providers -m arctic-xs'

# P11: invalid model name -- should anyhow!() with list of valid options
probe "11-model-invalid" 'tldr semantic "database" backend/providers -m bogus-model'

# P12: --langs with valid extension
probe "12-langs-py" 'tldr semantic "database" backend/providers --langs py'

# P13: --langs with LANGUAGE NAME instead of extension (silently dropped per docs)
probe "13-langs-name" 'tldr semantic "database" backend/providers --langs python'

# P14: --langs with unknown extension (silently dropped)
probe "14-langs-unknown" 'tldr semantic "database" backend/providers --langs xyz'

# P15: --no-cache (rebuild from scratch)
probe "15-no-cache" 'tldr semantic "database" backend/providers --no-cache'

# P16: format-compact
probe "16-format-compact" 'tldr semantic "database" backend/providers -f compact'

# P17: conceptual query (vocabulary gap — BM25 would fail, semantic should match)
probe "17-conceptual" 'tldr semantic "lookup external trading symbol for an asset" backend/providers'

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
