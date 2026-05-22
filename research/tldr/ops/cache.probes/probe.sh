#!/usr/bin/env bash
# Regenerates all probe captures for `tldr cache`.
#
# Usage:   bash research/tldr/ops/cache.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: `tldr cache` is OMITTED from agent-facing skills (per 05_OMITTED_
# COMMANDS_RATIONALE.md §2) — clearing the cache while an agent is
# working causes 10x slowdown on subsequent commands. Probed for research
# completeness, NOT for agent guidance.

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

echo "Probing tldr cache against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — cache stats with current dir.
probe "01-happy" "tldr cache stats"

# P02: happy-scale — explicit --project.
probe "02-happy-scale" "tldr cache stats --project ."

# P03: missing subcommand.
probe "03-missing-arg" "tldr cache"

# P04: bad --project path.
probe "04-badpath" "tldr cache stats --project /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr cache stats -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr cache stats -f text"

# P07: format compact.
probe "07-format-compact" "tldr cache stats -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr cache stats -f dot"

# P09: cache stats with -p shorthand.
probe "09-stats-p-short" "tldr cache stats -p ."

# P10: cache clear (default project=.) — DESTRUCTIVE; run in /tmp scope to avoid harming Stock-Monitor cache.
TMP_PROJECT="$(mktemp -d)"
echo "print('hello')" > "$TMP_PROJECT/x.py"
probe "10-clear-tmp" "tldr cache clear --project $TMP_PROJECT"

# P11: clear --project bad path.
probe "11-clear-badpath" "tldr cache clear --project /no/such/dir"

# P12: cache help subcommand.
probe "12-help-subcommand" "tldr cache help"

# P13: bogus subcommand.
probe "13-subcommand-bogus" "tldr cache wat"

# P14: bad --lang.
probe "14-bad-lang" "tldr cache stats -l brainfuck"

# P15: -l python explicit (verify lang flag honored).
probe "15-lang-python" "tldr cache stats -l python"

# P16: -q quiet.
probe "16-quiet" "tldr cache stats -q"

# P17: stats inside a fresh tmp dir (no cache present).
TMP_NOCACHE="$(mktemp -d)"
probe "17-stats-no-cache" "tldr cache stats --project $TMP_NOCACHE"
rmdir "$TMP_NOCACHE"

rm -rf "$TMP_PROJECT"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
