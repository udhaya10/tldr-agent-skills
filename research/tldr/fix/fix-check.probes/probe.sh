#!/usr/bin/env bash
# Regenerates all probe captures for `tldr fix check`.
#
# Usage:   bash research/tldr/fix/fix-check.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: CLI subcommand is `tldr fix check`, NOT `tldr fix-check`.

set -uo pipefail

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

PROJECT_ROOT="/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills"
FIXTURES="$PROJECT_ROOT/research/fixtures/fix-check"

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

echo "Probing tldr fix check against fixtures in $FIXTURES ..."
cd "$FIXTURES" || { echo "Fixture dir not found: $FIXTURES" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — failing test (will try to auto-fix in a loop).
probe "01-happy" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'python -c \"import buggy; buggy.compute(5)\"'"

# P02: happy-scale — successful test (no failures to fix; should exit 0 immediately).
probe "02-happy-scale" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true'"

# P03: missing required arg (no --test-cmd).
probe "03-missing-arg" "tldr fix check --file $FIXTURES/buggy.py"

# P04: bad --file path.
probe "04-badpath" "tldr fix check --file /no/such/file.py --test-cmd 'true'"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' --format sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' --format text"

# P07: format compact.
probe "07-format-compact" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' --format compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' --format dot"

# P09: --max-attempts 1.
probe "09-max-attempts-low" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'false' --max-attempts 1"

# P10: --max-attempts 0 (edge).
probe "10-max-attempts-zero" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'false' --max-attempts 0"

# P11: --max-attempts default (5).
probe "11-max-attempts-default" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'false'"

# P12: bad --test-cmd (command not found).
probe "12-test-cmd-bogus" "tldr fix check --file $FIXTURES/buggy.py --test-cmd '/no/such/command'"

# P13: test-cmd that times out (sleep but should be fine for a quick probe).
probe "13-test-cmd-fail" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'exit 1'"

# P14: bad --lang.
probe "14-bad-lang" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' -l brainfuck"

# P15: -l python explicit.
probe "15-lang-python" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' -l python"

# P16: -l typescript (mismatch).
probe "16-lang-mismatch" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'false' -l typescript --max-attempts 1"

# P17: short -f flag (-f could be --file or --format; check what wins).
probe "17-short-f-ambiguity" "tldr fix check -f $FIXTURES/buggy.py --test-cmd 'true' -f compact"

# P18: -t short for --test-cmd.
probe "18-short-t-test-cmd" "tldr fix check --file $FIXTURES/buggy.py -t 'true'"

# P19: --quiet flag.
probe "19-quiet" "tldr fix check --file $FIXTURES/buggy.py --test-cmd 'true' -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
