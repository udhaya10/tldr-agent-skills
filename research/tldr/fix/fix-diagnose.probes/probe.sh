#!/usr/bin/env bash
# Regenerates all probe captures for `tldr fix diagnose`.
#
# Usage:   bash research/tldr/fix/fix-diagnose.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: CLI subcommand is `tldr fix diagnose`, NOT `tldr fix-diagnose`.

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
FIXTURES="$PROJECT_ROOT/research/fixtures/fix-diagnose"

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

echo "Probing tldr fix diagnose against fixtures in $FIXTURES ..."
cd "$FIXTURES" || { echo "Fixture dir not found: $FIXTURES" >&2; exit 1; }

ERR_TEXT='NameError: name '"'"'valeu'"'"' is not defined. Did you mean: '"'"'value'"'"'?'

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — diagnose with --error inline.
probe "01-happy" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\""

# P02: happy-scale — diagnose with --error-file (full traceback).
probe "02-happy-scale" "tldr fix diagnose -s $FIXTURES/buggy.py --error-file $FIXTURES/error.txt"

# P03: missing required arg (no --source).
probe "03-missing-arg" "tldr fix diagnose -e \"$ERR_TEXT\""

# P04: bad path (--source).
probe "04-badpath" "tldr fix diagnose -s /no/such/file.py -e \"$ERR_TEXT\""

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f text"

# P07: format compact.
probe "07-format-compact" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f dot"

# P09: --stdin pipe.
probe "09-stdin" "cat $FIXTURES/error.txt | tldr fix diagnose -s $FIXTURES/buggy.py --stdin"

# P10: NO error input.
probe "10-no-error-input" "tldr fix diagnose -s $FIXTURES/buggy.py < /dev/null"

# P11: --error AND --error-file conflict.
probe "11-conflicts" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" --error-file $FIXTURES/error.txt"

# P12: --error-file bad path.
probe "12-error-file-bad" "tldr fix diagnose -s $FIXTURES/buggy.py --error-file /no/such/error.txt"

# P13: --api-surface (no fixture; should print stderr note but still work).
probe "13-api-surface" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" --api-surface /no/such/api.json"

# P14: bad --lang.
probe "14-bad-lang" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -l brainfuck"

# P15: -l python explicit.
probe "15-lang-python" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -l python"

# P16: -l typescript on Python error.
probe "16-lang-mismatch" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -l typescript"

# P17: unparseable error text.
probe "17-unparseable" "tldr fix diagnose -s $FIXTURES/buggy.py -e 'some random garbage text'"

# P18: error that includes file:line metadata.
probe "18-error-with-location" "tldr fix diagnose -s $FIXTURES/buggy.py --error-file $FIXTURES/error.txt -f text"

# P19: -q quiet.
probe "19-quiet" "tldr fix diagnose -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
