#!/usr/bin/env bash
# Regenerates all probe captures for `tldr api-check`.
#
# Usage:   bash research/tldr/audit/api-check.probes/probe.sh
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

echo "Probing tldr api-check against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr api-check backend/providers"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr api-check backend"

# P03: missing required arg.
probe "03-missing-arg" "tldr api-check"

# P04: bad path.
probe "04-badpath" "tldr api-check /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr api-check backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr api-check backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr api-check backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr api-check backend/providers -f dot"

# P09: --category security only.
probe "09-category-security" "tldr api-check backend --category security"

# P10: --category bogus (clap rejection).
probe "10-category-bogus" "tldr api-check backend/providers --category wat"

# P11: --severity high.
probe "11-severity-high" "tldr api-check backend --severity high"

# P12: --severity bogus.
probe "12-severity-bogus" "tldr api-check backend/providers --severity over9000"

# P13: --category multiple (comma-separated).
probe "13-category-multi" "tldr api-check backend --category 'crypto,security,resources'"

# P14: file as PATH (not dir).
probe "14-file-arg" "tldr api-check backend/providers/yahoo.py"

# P15: --lang python (global flag).
probe "15-lang-python" "tldr api-check backend -l python"

# P16: --lang typescript on python-only subdir — should yield 0 findings.
probe "16-lang-typescript" "tldr api-check backend/providers -l typescript"

# P17: bad --lang.
probe "17-bad-lang" "tldr api-check backend/providers -l brainfuck"

# P18: -O output to file.
OUTPUT_TMP="$(mktemp)"
probe "18-output-file" "tldr api-check backend/providers -O $OUTPUT_TMP && echo '--FILE--' && cat $OUTPUT_TMP"
rm -f "$OUTPUT_TMP"

# P19: -q quiet.
probe "19-quiet" "tldr api-check backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
