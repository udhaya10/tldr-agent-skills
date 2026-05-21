#!/usr/bin/env bash
# Regenerates all probe captures for `tldr similar`.
#
# Usage:   bash research/tldr/search/similar.probes/probe.sh
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

echo "Probing tldr similar against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Scope to backend/providers/ (4 files) to keep embedding pass fast.
# Full Stock-Monitor backend has 56 Python files; semantic indexing is
# the heaviest operation.
#
# IMPORTANT: -p MUST be an absolute path. With a relative -p, the
# semantic index stores chunk paths in a form that does NOT match
# the canonicalized source file path, and every probe fails with
# "no indexed chunks found for source file: <abs path>" exit 1.
# Smart-path logic at similar.rs:79-87 only kicks in when -p is the
# literal "." default — relative non-default values bypass it.
SCOPE="$TARGET_REPO/backend/providers"

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — find files similar to base.py within scope.
probe "01-happy" "tldr similar backend/providers/base.py -p $SCOPE"

# P02: happy-scale — find files similar to yahoo.py within scope.
probe "02-happy-scale" "tldr similar backend/providers/yahoo.py -p $SCOPE"

# P03: missing required FILE arg.
probe "03-missing-arg" "tldr similar"

# P04: bad path on FILE.
probe "04-badpath" "tldr similar /no/such/file.py -p $SCOPE"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr similar backend/providers/base.py -p $SCOPE -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr similar backend/providers/base.py -p $SCOPE -f text"

# P07: format compact.
probe "07-format-compact" "tldr similar backend/providers/base.py -p $SCOPE -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr similar backend/providers/base.py -p $SCOPE -f dot"

# P09: -t 0.0 — minimum threshold should return EVERY chunk pair above 0.
probe "09-threshold-zero" "tldr similar backend/providers/base.py -p $SCOPE -t 0.0"

# P10: -t 0.99 — very high threshold; expect few/no results.
probe "10-threshold-high" "tldr similar backend/providers/base.py -p $SCOPE -t 0.99"

# P11: -n 1 — top-1 only.
probe "11-top-one" "tldr similar backend/providers/base.py -p $SCOPE -n 1"

# P12: -n 50 — large top-N.
probe "12-top-fifty" "tldr similar backend/providers/base.py -p $SCOPE -n 50"

# P13: --by-chunk on whole-file target — legacy per-chunk view (default
# is aggregated-by-file).
probe "13-by-chunk" "tldr similar backend/providers/base.py -p $SCOPE --by-chunk"

# P14: --function specific — switches to per-chunk path automatically
# (similar.rs:136 default-aggregation gate). Use a real function name;
# class names yield "Chunk not found" because chunk granularity is
# Function only (see Source Code Reality / build_opts.granularity).
probe "14-function" "tldr similar backend/providers/yahoo.py -F fetch_historical_data -p $SCOPE"

# P15: --function on a missing/class name — exit-54 ChunkNotFound.
probe "15-function-missing" "tldr similar backend/providers/base.py -F HistoricalDataProvider -p $SCOPE"

# P16: --include-self — does it actually do anything? (Per similar.rs:43-45
# the flag is declared but never used downstream. Compare to P01.)
probe "16-include-self" "tldr similar backend/providers/base.py -p $SCOPE --include-self"

# P17: bad --model.
probe "17-bad-model" "tldr similar backend/providers/base.py -p $SCOPE -m fake-model"

# P18: --model arctic-xs — smaller faster model.
probe "18-model-xs" "tldr similar backend/providers/base.py -p $SCOPE -m arctic-xs"

# P19: --no-cache — bypass on-disk embedding cache.
probe "19-no-cache" "tldr similar backend/providers/base.py -p $SCOPE --no-cache"

# P20: -q quiet.
probe "20-quiet" "tldr similar backend/providers/base.py -p $SCOPE -q"

# P21: file not in indexed scope — what error shape?
# Pick a file outside the -p scope.
probe "21-file-outside-scope" "tldr similar backend/db.py -p $SCOPE"

# P22: **relative -p path bug.** With a relative -p, the index stores
# chunk paths in a form that does NOT match the canonicalized source
# path. Every aggregation lookup returns "no indexed chunks found"
# (exit 1). Same query with absolute -p (P01) works. Smart-path
# logic at similar.rs:79-87 only fires when -p is the literal "."
# default; explicit relative paths bypass it.
probe "22-relative-path-bug" "tldr similar backend/providers/base.py -p backend/providers"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
