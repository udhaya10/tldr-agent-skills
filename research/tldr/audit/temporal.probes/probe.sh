#!/usr/bin/env bash
# Regenerates all probe captures for `tldr temporal`.
#
# Usage:   bash research/tldr/audit/temporal.probes/probe.sh
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

echo "Probing tldr temporal against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr temporal backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr temporal backend"

# P03: missing required arg.
probe "03-missing-arg" "tldr temporal"

# P04: bad path.
probe "04-badpath" "tldr temporal /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr temporal backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr temporal backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr temporal backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr temporal backend/providers -f dot"

# P09: --min-support 1.
probe "09-min-support-low" "tldr temporal backend/providers --min-support 1"

# P10: --min-support 999 (filter all).
probe "10-min-support-high" "tldr temporal backend/providers --min-support 999"

# P11: --min-confidence 0.0.
probe "11-min-conf-zero" "tldr temporal backend/providers --min-confidence 0.0"

# P12: --min-confidence 1.0.
probe "12-min-conf-perfect" "tldr temporal backend/providers --min-confidence 1.0"

# P13: --query specific method.
probe "13-query-method" "tldr temporal backend/providers --query fetch_historical_data"

# P14: --source-lang python.
probe "14-source-lang-python" "tldr temporal backend/providers --source-lang python"

# P15: --source-lang auto.
probe "15-source-lang-auto" "tldr temporal backend/providers --source-lang auto"

# P16: --source-lang bogus.
probe "16-source-lang-bogus" "tldr temporal backend/providers --source-lang wat"

# P17: --max-files 1.
probe "17-max-files-low" "tldr temporal backend --max-files 1"

# P18: --include-trigrams.
probe "18-include-trigrams" "tldr temporal backend --include-trigrams"

# P19: --include-examples 0.
probe "19-include-examples-zero" "tldr temporal backend/providers --include-examples 0"

# P20: --timeout 1 (short).
probe "20-timeout-short" "tldr temporal backend/providers --timeout 1"

# P21: --project-root.
probe "21-project-root" "tldr temporal backend/providers --project-root backend"

# P22: bad --lang (global).
probe "22-bad-lang" "tldr temporal backend/providers -l brainfuck"

# P23: -l python.
probe "23-lang-python" "tldr temporal backend/providers -l python"

# P24: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "24-empty-dir" "tldr temporal $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P25: non-source markdown.
probe "25-non-source-md" "tldr temporal README.md"

# P26: -q quiet.
probe "26-quiet" "tldr temporal backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
