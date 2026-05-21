#!/usr/bin/env bash
# Regenerates all probe captures for `tldr churn`.
#
# Usage:   bash research/tldr/audit/churn.probes/probe.sh
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

echo "Probing tldr churn against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — current dir (Stock-Monitor, a git repo).
probe "01-happy" "tldr churn"

# P02: happy-scale — explicit path with broader history.
probe "02-happy-scale" "tldr churn . --days 1000 --top 50"

# P03: missing required arg — PATH defaults to '.', no required positional.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr churn /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr churn -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr churn -f text"

# P07: format compact.
probe "07-format-compact" "tldr churn -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr churn -f dot"

# P09: --days 30 — short history.
probe "09-days-short" "tldr churn --days 30"

# P10: --days 99999 — long history (likely repo lifetime).
probe "10-days-long" "tldr churn --days 99999"

# P11: --top 1 — single most-churned file.
probe "11-top-one" "tldr churn --top 1"

# P12: --authors — include author stats.
probe "12-authors" "tldr churn --authors"

# P13: --exclude with pattern.
probe "13-exclude" "tldr churn --exclude '*.md' --exclude 'venv/**'"

# P14: non-git directory (existing dir, no .git).
NONGIT_DIR="$(mktemp -d)"
echo "not a git repo" > "$NONGIT_DIR/file.txt"
probe "14-non-git" "tldr churn $NONGIT_DIR"
rm -rf "$NONGIT_DIR"

# P15: empty directory.
EMPTY_DIR="$(mktemp -d)"
probe "15-empty-dir" "tldr churn $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P16: bad --lang (just to confirm clap rejects it even though churn ignores lang).
probe "16-bad-lang" "tldr churn -l brainfuck"

# P17: -q quiet.
probe "17-quiet" "tldr churn -q --days 30"

# P18: --hotspots (hidden deprecated flag).
probe "18-hotspots-flag" "tldr churn --hotspots"

# P19: directory pointing to a file.
probe "19-file-arg" "tldr churn backend/providers/yahoo.py"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
