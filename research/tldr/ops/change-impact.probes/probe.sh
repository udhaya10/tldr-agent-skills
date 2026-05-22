#!/usr/bin/env bash
# Regenerates all probe captures for `tldr change-impact`.
#
# Usage:   bash research/tldr/ops/change-impact.probes/probe.sh
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

echo "Probing tldr change-impact against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — default (HEAD diff).
probe "01-happy" "tldr change-impact"

# P02: happy-scale — explicit files via -F.
probe "02-happy-scale" "tldr change-impact -F backend/providers/yahoo.py,backend/providers/dhan.py"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr change-impact /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr change-impact -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr change-impact -f text"

# P07: format compact.
probe "07-format-compact" "tldr change-impact -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr change-impact -f dot"

# P09: --base origin/main (likely no such branch locally — should error gracefully).
probe "09-base-flag" "tldr change-impact --base origin/main"

# P10: --base HEAD~1.
probe "10-base-head-1" "tldr change-impact --base HEAD~1"

# P11: --staged.
probe "11-staged" "tldr change-impact --staged"

# P12: --uncommitted.
probe "12-uncommitted" "tldr change-impact --uncommitted"

# P13: --depth 1 (shallow).
probe "13-depth-low" "tldr change-impact -F backend/providers/yahoo.py --depth 1"

# P14: --depth 0 (edge).
probe "14-depth-zero" "tldr change-impact -F backend/providers/yahoo.py --depth 0"

# P15: --include-imports (default true, set explicitly).
probe "15-include-imports" "tldr change-impact -F backend/providers/yahoo.py --include-imports"

# P16: --test-patterns custom.
probe "16-test-patterns" "tldr change-impact -F backend/providers/yahoo.py --test-patterns '*_test.py,test_*.py'"

# P17: --runner pytest.
probe "17-runner-pytest" "tldr change-impact -F backend/providers/yahoo.py --runner pytest"

# P18: --runner jest.
probe "18-runner-jest" "tldr change-impact -F backend/providers/yahoo.py --runner jest"

# P19: --runner bogus.
probe "19-runner-bogus" "tldr change-impact --runner wat"

# P20: --runner cargo-test.
probe "20-runner-cargo" "tldr change-impact -F backend/providers/yahoo.py --runner cargo-test"

# P21: bad --lang.
probe "21-bad-lang" "tldr change-impact -l brainfuck"

# P22: -l python explicit.
probe "22-lang-python" "tldr change-impact -l python"

# P23: -l typescript on python.
probe "23-lang-mismatch" "tldr change-impact -l typescript"

# P24: file as PATH (should be rejected with require_directory error).
probe "24-file-as-path" "tldr change-impact backend/providers/yahoo.py"

# P25: empty dir.
EMPTY_DIR="$(mktemp -d)"
cd "$EMPTY_DIR" && git init -q . 2>/dev/null || true
cd "$TARGET_REPO"
probe "25-empty-dir" "tldr change-impact $EMPTY_DIR"
rm -rf "$EMPTY_DIR"

# P26: non-git dir.
NONGIT_DIR="$(mktemp -d)"
echo "print('hi')" > "$NONGIT_DIR/x.py"
probe "26-non-git" "tldr change-impact $NONGIT_DIR"
rm -rf "$NONGIT_DIR"

# P27: -q quiet.
probe "27-quiet" "tldr change-impact -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
