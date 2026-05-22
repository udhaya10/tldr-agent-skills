#!/usr/bin/env bash
# Regenerates all probe captures for `tldr taint`.
#
# Usage:   bash research/tldr/audit/taint.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# FIXTURE-INPUT command per Journal 04 §13: needs SQL/web sink code.
# Fixtures live at research/fixtures/taint/.

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
FIXTURES="$PROJECT_ROOT/research/fixtures/taint"
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

echo "Probing tldr taint against fixtures in $FIXTURES ..."
cd "$FIXTURES" || { echo "Fixture dir not found: $FIXTURES" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — known SQL injection function.
probe "01-happy" "tldr taint $FIXTURES/sinks.py vulnerable_sql"

# P02: happy-scale — larger function with shell sink.
probe "02-happy-scale" "tldr taint $FIXTURES/sinks.py vulnerable_shell"

# P03: missing required arg (no FUNCTION).
probe "03-missing-arg" "tldr taint $FIXTURES/sinks.py"

# P04: bad path.
probe "04-badpath" "tldr taint /no/such/file.py vulnerable_sql"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr taint $FIXTURES/sinks.py vulnerable_sql -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr taint $FIXTURES/sinks.py vulnerable_sql -f text"

# P07: format compact.
probe "07-format-compact" "tldr taint $FIXTURES/sinks.py vulnerable_sql -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr taint $FIXTURES/sinks.py vulnerable_sql -f dot"

# P09: --verbose.
probe "09-verbose" "tldr taint $FIXTURES/sinks.py vulnerable_sql --verbose"

# P10: function not found.
probe "10-function-not-found" "tldr taint $FIXTURES/sinks.py no_such_function"

# P11: -l python explicit.
probe "11-lang-python" "tldr taint $FIXTURES/sinks.py vulnerable_sql -l python"

# P12: -l typescript on Python (mismatch).
probe "12-lang-mismatch" "tldr taint $FIXTURES/sinks.py vulnerable_sql -l typescript"

# P13: bad --lang.
probe "13-bad-lang" "tldr taint $FIXTURES/sinks.py vulnerable_sql -l brainfuck"

# P14: safe function (no taint expected).
probe "14-safe-function" "tldr taint $FIXTURES/sinks.py safe_function"

# P15: parameterized SQL — should NOT report taint.
probe "15-safe-sql" "tldr taint $FIXTURES/sinks.py safe_sql"

# P16: eval sink.
probe "16-eval-sink" "tldr taint $FIXTURES/sinks.py vulnerable_eval"

# P17: path-traversal sink.
probe "17-path-sink" "tldr taint $FIXTURES/sinks.py vulnerable_path"

# P18: -q quiet.
probe "18-quiet" "tldr taint $FIXTURES/sinks.py vulnerable_sql -q"

# P19: non-source markdown.
probe "19-non-source-md" "tldr taint $FIXTURES/sinks.py vulnerable_sql"
echo "(see P19 actually targets sinks.py; we need a separate test for .md)" > /dev/null
probe "19-non-source-md" "tldr taint $PROJECT_ROOT/README.md anything"

# P20: directory as FILE.
probe "20-directory-arg" "tldr taint $FIXTURES vulnerable_sql"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
