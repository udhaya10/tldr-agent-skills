#!/usr/bin/env bash
# Regenerates all probe captures for `tldr diagnostics`.
#
# Usage:   bash research/tldr/fix/diagnostics.probes/probe.sh
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

echo "Probing tldr diagnostics against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single Python file (--timeout 10 to keep fast).
probe "01-happy" "tldr diagnostics backend/providers/yahoo.py --timeout 10"

# P02: happy-scale — small subdir.
probe "02-happy-scale" "tldr diagnostics backend/providers --timeout 10"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr diagnostics /no/such/dir --timeout 10"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr diagnostics backend/providers/yahoo.py --timeout 10 -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr diagnostics backend/providers/yahoo.py --timeout 10 -f text"

# P07: format compact.
probe "07-format-compact" "tldr diagnostics backend/providers/yahoo.py --timeout 10 -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr diagnostics backend/providers/yahoo.py --timeout 10 -f dot"

# P09: --tools specific (ruff is fast).
probe "09-tools-ruff" "tldr diagnostics backend/providers/yahoo.py --tools ruff --timeout 10"

# P10: --tools bogus (unknown tool).
probe "10-tools-bogus" "tldr diagnostics backend/providers/yahoo.py --tools wat --timeout 10"

# P11: --no-typecheck.
probe "11-no-typecheck" "tldr diagnostics backend/providers/yahoo.py --no-typecheck --timeout 10"

# P12: --no-lint.
probe "12-no-lint" "tldr diagnostics backend/providers/yahoo.py --no-lint --timeout 10"

# P13: --severity error (most strict filter).
probe "13-severity-error" "tldr diagnostics backend/providers/yahoo.py -s error --tools ruff --timeout 10"

# P14: --severity bogus.
probe "14-severity-bogus" "tldr diagnostics backend/providers/yahoo.py -s wat"

# P15: --ignore specific codes.
probe "15-ignore-codes" "tldr diagnostics backend/providers/yahoo.py --tools ruff --ignore E501,F401 --timeout 10"

# P16: --output sarif.
probe "16-output-sarif" "tldr diagnostics backend/providers/yahoo.py --tools ruff --output sarif --timeout 10"

# P17: --output github-actions.
probe "17-output-github-actions" "tldr diagnostics backend/providers/yahoo.py --tools ruff --output github-actions --timeout 10"

# P18: --output bogus.
probe "18-output-bogus" "tldr diagnostics backend/providers/yahoo.py --output wat"

# P19: --project flag.
probe "19-project-flag" "tldr diagnostics backend/providers/yahoo.py --project --tools ruff --timeout 10"

# P20: --strict.
probe "20-strict" "tldr diagnostics backend/providers/yahoo.py --tools ruff --strict --timeout 10"

# P21: --timeout 1 (very short).
probe "21-timeout-tiny" "tldr diagnostics backend/providers/yahoo.py --timeout 1"

# P22: bad --lang.
probe "22-bad-lang" "tldr diagnostics backend/providers/yahoo.py --tools ruff -l brainfuck"

# P23: -l python explicit.
probe "23-lang-python" "tldr diagnostics backend/providers/yahoo.py --tools ruff -l python --timeout 10"

# P24: empty dir (no tools to run).
EMPTY_DIR="$(mktemp -d)"
probe "24-empty-dir" "tldr diagnostics $EMPTY_DIR --timeout 5"
rmdir "$EMPTY_DIR"

# P25: non-source markdown.
probe "25-non-source-md" "tldr diagnostics README.md --timeout 5"

# P26: -q quiet.
probe "26-quiet" "tldr diagnostics backend/providers/yahoo.py --tools ruff -q --timeout 10"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
