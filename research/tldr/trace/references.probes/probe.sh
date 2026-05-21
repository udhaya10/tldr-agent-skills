#!/usr/bin/env bash
# Regenerates all probe captures for `tldr references`.
#
# Usage:   bash research/tldr/trace/references.probes/probe.sh
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

echo "Probing tldr references against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — find a real function with multiple call sites.
probe "01-happy" "tldr references _to_finite_float backend -l python"

# P02: happy-scale — find a more widely-used symbol.
probe "02-happy-scale" "tldr references Provider backend -l python"

# P03: missing required arg — SYMBOL omitted.
probe "03-missing-arg" "tldr references"

# P04: bad path.
probe "04-badpath" "tldr references foo /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr references _to_finite_float backend -l python -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr references _to_finite_float backend -l python -f text"

# P07: format compact.
probe "07-format-compact" "tldr references _to_finite_float backend -l python -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr references _to_finite_float backend -l python -f dot"

# P09: --limit 2 — truncation.
probe "09-limit-small" "tldr references _to_finite_float backend -l python --limit 2"

# P10: --limit 0 — does 0 mean unlimited or disable?
probe "10-limit-zero" "tldr references _to_finite_float backend -l python --limit 0"

# P11: --include-definition — include def location.
probe "11-include-def" "tldr references _to_finite_float backend -l python --include-definition"

# P12: --kinds call only.
probe "12-kinds-call" "tldr references _to_finite_float backend -l python --kinds call"

# P13: --kinds import.
probe "13-kinds-import" "tldr references pandas backend -l python --kinds import --limit 5"

# P14: --kinds with bogus value.
probe "14-kinds-bogus" "tldr references _to_finite_float backend -l python --kinds invalid_kind"

# P15: --scope file.
probe "15-scope-file" "tldr references _to_finite_float backend/providers/yahoo.py -l python -s file"

# P16: --scope local.
probe "16-scope-local" "tldr references symbol backend/providers/yahoo.py -l python -s local"

# P17: --scope bogus.
probe "17-scope-bogus" "tldr references _to_finite_float backend -l python -s solar_system"

# P18: --context-lines 3 — declared but per --help "not implemented yet".
probe "18-context-lines" "tldr references _to_finite_float backend -l python -C 3"

# P19: --min-confidence 0.99 — high confidence filter.
probe "19-min-confidence-high" "tldr references _to_finite_float backend -l python --min-confidence 0.99"

# P20: --min-confidence out-of-range.
probe "20-min-confidence-oor" "tldr references _to_finite_float backend -l python --min-confidence 2.0"

# P21: symbol not found — no results path with helpful hint.
probe "21-symbol-not-found" "tldr references no_such_symbol_anywhere backend -l python"

# P22: -o text legacy override (hidden flag).
probe "22-output-text-legacy" "tldr references _to_finite_float backend -l python -o text"

# P23: bad --lang.
probe "23-bad-lang" "tldr references _to_finite_float backend -l brainfuck"

# P24: -q quiet — should suppress the "Finding references..." progress msg.
probe "24-quiet" "tldr references _to_finite_float backend -l python -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
