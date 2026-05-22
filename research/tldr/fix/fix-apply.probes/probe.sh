#!/usr/bin/env bash
# Regenerates all probe captures for `tldr fix apply`.
#
# Usage:   bash research/tldr/fix/fix-apply.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: The CLI subcommand is `tldr fix apply` (space-separated),
# NOT `tldr fix-apply` (the dossier name uses hyphen for filesystem).

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
FIXTURES="$PROJECT_ROOT/research/fixtures/fix-apply"

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

echo "Probing tldr fix apply against fixtures in $FIXTURES ..."
cd "$FIXTURES" || { echo "Fixture dir not found: $FIXTURES" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — apply fix with --error inline.
ERR_TEXT='NameError: name '"'"'valeu'"'"' is not defined. Did you mean: '"'"'value'"'"'?'
probe "01-happy" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\""

# P02: happy-scale — use --error-file (canonical pipeline).
probe "02-happy-scale" "tldr fix apply -s $FIXTURES/buggy.py --error-file $FIXTURES/error.txt"

# P03: missing required arg (no --source).
probe "03-missing-arg" "tldr fix apply -e \"$ERR_TEXT\""

# P04: bad path (--source).
probe "04-badpath" "tldr fix apply -s /no/such/file.py -e \"$ERR_TEXT\""

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f text"

# P07: format compact.
probe "07-format-compact" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -f dot"

# P09: -d / --diff (show unified diff).
probe "09-diff" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -d"

# P10: -o / --output to file.
OUT_FILE="$(mktemp -t patched.py.XXXXXX)"
probe "10-output-file" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -o $OUT_FILE"
echo "=== output file content ===" >> "${CMD_DIR}/10-output-file.out"
cat "$OUT_FILE" >> "${CMD_DIR}/10-output-file.out" 2>/dev/null || true
rm -f "$OUT_FILE"

# P11: -i / --in-place (must NOT alter the fixture; we copy first).
TMP_SOURCE="$(mktemp -t buggy.py.XXXXXX)"
cp "$FIXTURES/buggy.py" "$TMP_SOURCE"
probe "11-in-place" "tldr fix apply -s $TMP_SOURCE -e \"$ERR_TEXT\" -i"
echo "=== in-place file content after fix ===" >> "${CMD_DIR}/11-in-place.out"
cat "$TMP_SOURCE" >> "${CMD_DIR}/11-in-place.out" 2>/dev/null || true
rm -f "$TMP_SOURCE"

# P12: --stdin (pipe error from stdin).
probe "12-stdin" "cat $FIXTURES/error.txt | tldr fix apply -s $FIXTURES/buggy.py --stdin"

# P13: NO error provided (no --error, no --error-file, no --stdin).
probe "13-no-error-input" "tldr fix apply -s $FIXTURES/buggy.py < /dev/null"

# P14: --error AND --error-file (conflicts_with).
probe "14-conflicts" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" --error-file $FIXTURES/error.txt"

# P15: --error-file bad path.
probe "15-error-file-bad" "tldr fix apply -s $FIXTURES/buggy.py --error-file /no/such/error.txt"

# P16: --api-surface (no fixture; should silently degrade or error).
probe "16-api-surface-bad" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" --api-surface /no/such/api.json"

# P17: bad --lang.
probe "17-bad-lang" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -l brainfuck"

# P18: -l python explicit.
probe "18-lang-python" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -l python"

# P19: -l typescript (mismatch).
probe "19-lang-mismatch" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -l typescript"

# P20: error that doesn't match the source.
probe "20-unrelated-error" "tldr fix apply -s $FIXTURES/buggy.py -e \"NameError: foo not defined\""

# P21: -q quiet.
probe "21-quiet" "tldr fix apply -s $FIXTURES/buggy.py -e \"$ERR_TEXT\" -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
