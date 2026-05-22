#!/usr/bin/env bash
# Regenerates all probe captures for `tldr vuln`.
#
# Usage:   bash research/tldr/audit/vuln.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# SLOW COMMAND per Journal 04 §5: full-mode vuln on full backend
# can take >30s. Happy probes scope to backend/providers/ (4 files).

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

echo "Probing tldr vuln against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
TAINT_FIXTURE="$PROJECT_ROOT/research/fixtures/taint/sinks.py"

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small subdir.
probe "01-happy" "tldr vuln backend/providers"

# P02: happy-scale — taint fixture which has known SQL/shell sinks.
probe "02-happy-scale" "tldr vuln $TAINT_FIXTURE"

# P03: missing required arg.
probe "03-missing-arg" "tldr vuln"

# P04: bad path.
probe "04-badpath" "tldr vuln /no/such/dir"

# P05: format dot (vuln supports sarif, NOT dot).
probe "05-format-reject-dot" "tldr vuln backend/providers -f dot"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr vuln backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr vuln backend/providers -f compact"

# P08: format SARIF (SUPPORTED).
probe "08-format-sarif" "tldr vuln $TAINT_FIXTURE -f sarif"

# P09: --severity critical.
probe "09-severity-critical" "tldr vuln backend/providers --severity critical"

# P10: --severity info.
probe "10-severity-info" "tldr vuln backend/providers --severity info"

# P11: --severity bogus.
probe "11-severity-bogus" "tldr vuln backend/providers --severity wat"

# P12: --vuln-type sql_injection.
probe "12-vuln-type-sql" "tldr vuln $TAINT_FIXTURE --vuln-type sql_injection"

# P13: --vuln-type bogus.
probe "13-vuln-type-bogus" "tldr vuln backend/providers --vuln-type wat"

# P14: --vuln-type multiple.
probe "14-vuln-type-multi" "tldr vuln $TAINT_FIXTURE --vuln-type sql_injection --vuln-type command_injection"

# P15: --include-informational.
probe "15-include-informational" "tldr vuln backend/providers --include-informational"

# P16: --include-smells.
probe "16-include-smells" "tldr vuln backend/providers --include-smells"

# P17: --include-tests.
probe "17-include-tests" "tldr vuln backend --include-tests"

# P18: -O output to file.
OUT_FILE="$(mktemp -t vuln-out.XXXXXX)"
probe "18-output-file" "tldr vuln backend/providers -O $OUT_FILE"
echo "=== output file content (first 20 lines) ===" >> "${CMD_DIR}/18-output-file.out"
head -20 "$OUT_FILE" >> "${CMD_DIR}/18-output-file.out" 2>/dev/null || true
rm -f "$OUT_FILE"

# P19: --no-default-ignore.
probe "19-no-default-ignore" "tldr vuln backend/providers --no-default-ignore"

# P20: bad --lang.
probe "20-bad-lang" "tldr vuln backend/providers -l brainfuck"

# P21: -l python explicit.
probe "21-lang-python" "tldr vuln backend/providers -l python"

# P22: -l typescript on python.
probe "22-lang-mismatch" "tldr vuln backend/providers -l typescript"

# P23: lang autodetect outside native set (TypeScript-only).
probe "23-autodetect-non-native" "tldr vuln webui/src"

# P24: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "24-empty-dir" "tldr vuln $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P25: non-source markdown.
probe "25-non-source-md" "tldr vuln README.md"

# P26: -q quiet.
probe "26-quiet" "tldr vuln backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
