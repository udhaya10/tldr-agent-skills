#!/usr/bin/env bash
# Regenerates all probe captures for `tldr debt`.
#
# Usage:   bash research/tldr/audit/debt.probes/probe.sh
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

echo "Probing tldr debt against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr debt backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr debt backend"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr debt /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr debt backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr debt backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr debt backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr debt backend/providers -f dot"

# P09: --category security.
probe "09-category-security" "tldr debt backend --category security"

# P10: --category bogus (clap value_parser).
probe "10-category-bogus" "tldr debt backend --category wat"

# P11: -k 1 (top-1 file).
probe "11-top-one" "tldr debt backend -k 1"

# P12: -k 0 (zero or all?)
probe "12-top-zero" "tldr debt backend -k 0"

# P13: --min-debt 60 (1hr+ of debt).
probe "13-min-debt-mid" "tldr debt backend --min-debt 60"

# P14: --min-debt 99999 (filter everything).
probe "14-min-debt-high" "tldr debt backend --min-debt 99999"

# P15: --hourly-rate 100.
probe "15-hourly-rate" "tldr debt backend --hourly-rate 100"

# P16: -l python explicit.
probe "16-lang-python" "tldr debt backend/providers -l python"

# P17: -l typescript on python.
probe "17-lang-mismatch" "tldr debt backend/providers -l typescript"

# P18: bad --lang.
probe "18-bad-lang" "tldr debt backend/providers -l brainfuck"

# P19: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "19-empty-dir" "tldr debt $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P20: -q quiet.
probe "20-quiet" "tldr debt backend/providers -q"

# P21: file as PATH.
probe "21-file-arg" "tldr debt backend/providers/yahoo.py"

# P22: --category maintainability (most common).
probe "22-category-maintainability" "tldr debt backend --category maintainability"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
