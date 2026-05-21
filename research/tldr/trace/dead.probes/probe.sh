#!/usr/bin/env bash
# Regenerates all probe captures for `tldr dead`.
#
# Usage:   bash research/tldr/trace/dead.probes/probe.sh
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

echo "Probing tldr dead against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir backend/providers.
probe "01-happy" "tldr dead backend/providers -l python"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr dead backend -l python"

# P03: missing required arg — PATH defaults to `.`, no required positional.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr dead /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr dead backend/providers -l python -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr dead backend/providers -l python -f text"

# P07: format compact.
probe "07-format-compact" "tldr dead backend/providers -l python -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr dead backend/providers -l python -f dot"

# P09: --max-items 1 — truncation.
probe "09-max-items-small" "tldr dead backend -l python --max-items 1"

# P10: --max-items 99999 — no truncation cap.
probe "10-max-items-large" "tldr dead backend -l python --max-items 99999"

# P11: --call-graph — switch to legacy call-graph analysis (vs default refcount).
probe "11-call-graph-mode" "tldr dead backend/providers -l python --call-graph"

# P12: --entry-points custom — comma-separated patterns.
probe "12-entry-points" "tldr dead backend/providers -l python --entry-points fetch_historical_data,fetch_quotes"

# P13: --no-default-ignore — walk vendored dirs.
probe "13-no-default-ignore" "tldr dead backend/providers -l python --no-default-ignore"

# P14: bad --lang.
probe "14-bad-lang" "tldr dead backend -l brainfuck"

# P15: empty directory.
EMPTY_DIR="$(mktemp -d)"
probe "15-empty-dir" "tldr dead $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P16: -q quiet.
probe "16-quiet" "tldr dead backend/providers -l python -q"

# -----------------------------------------------------------------------------
# Daemon route probes
# -----------------------------------------------------------------------------

# P17: cold daemon.
tldr daemon stop > /dev/null 2>&1 || true
probe "17-cold-daemon" "tldr dead backend -l python"

# P18: warm daemon.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "18-warm-daemon" "tldr dead backend -l python"

# P19: warm daemon + --call-graph (does daemon path honor --call-graph?
# params_for_dead does NOT include call_graph — daemon path uses its own
# choice. Compare against P11 cold result for divergence.)
probe "19-warm-daemon-call-graph" "tldr dead backend/providers -l python --call-graph"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
