#!/usr/bin/env bash
# Regenerates all probe captures for `tldr bugbot`.
#
# Usage:   bash research/tldr/fix/bugbot.probes/probe.sh
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

echo "Probing tldr bugbot against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — bugbot check with default path.
probe "01-happy" "tldr bugbot check"

# P02: happy-scale — explicit path arg with no-tools (fast).
probe "02-happy-scale" "tldr bugbot check . --no-tools"

# P03: missing subcommand.
probe "03-missing-arg" "tldr bugbot"

# P04: bad path.
probe "04-badpath" "tldr bugbot check /no/such/dir --no-tools"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr bugbot check . --no-tools -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr bugbot check . --no-tools -f text"

# P07: format compact.
probe "07-format-compact" "tldr bugbot check . --no-tools -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr bugbot check . --no-tools -f dot"

# P09: --base-ref to specific commit.
probe "09-base-ref" "tldr bugbot check . --no-tools --base-ref HEAD~1"

# P10: --base-ref invalid.
probe "10-base-ref-bogus" "tldr bugbot check . --no-tools --base-ref not-a-ref"

# P11: --staged (might have nothing staged).
probe "11-staged" "tldr bugbot check . --no-tools --staged"

# P12: --max-findings 1.
probe "12-max-findings-low" "tldr bugbot check . --no-tools --max-findings 1"

# P13: --max-findings 0 (unlimited).
probe "13-max-findings-zero" "tldr bugbot check . --no-tools --max-findings 0"

# P14: --no-fail (don't exit non-zero on findings).
probe "14-no-fail" "tldr bugbot check . --no-tools --no-fail"

# P15: --tool-timeout 1.
probe "15-tool-timeout-short" "tldr bugbot check . --tool-timeout 1"

# P16: bad --lang.
probe "16-bad-lang" "tldr bugbot check . --no-tools -l brainfuck"

# P17: -l python.
probe "17-lang-python" "tldr bugbot check . --no-tools -l python"

# P18: -l typescript (mismatch on Python project).
probe "18-lang-mismatch" "tldr bugbot check . --no-tools -l typescript"

# P19: -q quiet.
probe "19-quiet" "tldr bugbot check . --no-tools -q"

# P20: non-git dir.
NONGIT_DIR="$(mktemp -d)"
echo "print('hi')" > "$NONGIT_DIR/x.py"
probe "20-non-git" "tldr bugbot check $NONGIT_DIR --no-tools"
rm -rf "$NONGIT_DIR"

# P21: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "21-empty-dir" "tldr bugbot check $EMPTY_DIR --no-tools"
rmdir "$EMPTY_DIR"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
