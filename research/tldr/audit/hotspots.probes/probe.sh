#!/usr/bin/env bash
# Regenerates all probe captures for `tldr hotspots`.
#
# Usage:   bash research/tldr/audit/hotspots.probes/probe.sh
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

echo "Probing tldr hotspots against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — current dir.
probe "01-happy" "tldr hotspots"

# P02: happy-scale — full backend with --top 50.
probe "02-happy-scale" "tldr hotspots backend --top 50"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr hotspots /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr hotspots -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr hotspots -f text"

# P07: format compact.
probe "07-format-compact" "tldr hotspots -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr hotspots -f dot"

# P09: --days 30 (short).
probe "09-days-short" "tldr hotspots --days 30"

# P10: --days 99999 (saturated).
probe "10-days-long" "tldr hotspots --days 99999"

# P11: --top 1.
probe "11-top-one" "tldr hotspots --top 1"

# P12: --by-function.
probe "12-by-function" "tldr hotspots --by-function --top 5"

# P13: --show-trend.
probe "13-show-trend" "tldr hotspots --show-trend"

# P14: --min-commits 1.
probe "14-min-commits-low" "tldr hotspots --min-commits 1"

# P15: --min-commits 999 (probably empty).
probe "15-min-commits-high" "tldr hotspots --min-commits 999"

# P16: --exclude.
probe "16-exclude" "tldr hotspots --exclude '*.md' --exclude 'venv/**'"

# P17: --threshold 0.5.
probe "17-threshold-mid" "tldr hotspots --threshold 0.5"

# P18: --threshold 0.99 (likely empty).
probe "18-threshold-high" "tldr hotspots --threshold 0.99"

# P19: --since 2026-01-01.
probe "19-since" "tldr hotspots --since 2026-01-01"

# P20: --since invalid date.
probe "20-since-bad" "tldr hotspots --since not-a-date"

# P21: --recency-halflife 0 (no decay).
probe "21-no-decay" "tldr hotspots --recency-halflife 0"

# P22: --include-bots.
probe "22-include-bots" "tldr hotspots --include-bots"

# P23: bad --lang.
probe "23-bad-lang" "tldr hotspots -l brainfuck"

# P24: non-git dir.
NONGIT_DIR="$(mktemp -d)"
echo "test" > "$NONGIT_DIR/file.txt"
probe "24-non-git" "tldr hotspots $NONGIT_DIR"
rm -rf "$NONGIT_DIR"

# P25: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "25-empty-dir" "tldr hotspots $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P26: -q quiet.
probe "26-quiet" "tldr hotspots -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
