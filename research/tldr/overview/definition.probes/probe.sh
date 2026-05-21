#!/usr/bin/env bash
# Regenerates all probe captures for `tldr definition`.
#
# Usage:   bash research/tldr/overview/definition.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Capture convention (Journal 04, §5):
#   <id>-<slug>.cmd   exact bash invocation
#   <id>-<slug>.out   stdout, truncated per protocol if > 500 lines
#   <id>-<slug>.err   stderr, with trailing "exit=<N>" line appended

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

echo "Probing tldr definition against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, position-based, smallest meaningful input.
# Cursor on the parameter `symbol` (line 40 col 12 in fetch_historical_data).
probe "01-happy-pos" "tldr definition backend/providers/yahoo.py 40 12"

# P02: happy-scale, name-based with --symbol + --file + cross-file resolution.
probe "02-happy-name" "tldr definition --symbol HistoricalDataProvider --file backend/providers/yahoo.py --project ."

# P03: missing required arg — file argument is required for position mode.
# Calling with no args triggers clap's required-argument logic; both modes
# need at least one positional or --symbol, so passing nothing exercises the
# common missing-input branch.
probe "03-missing-arg" "tldr definition"

# P04: non-existent path (position mode).
probe "04-badpath" "tldr definition /no/such/path.py 1 1"

# P05: format that should be rejected (sarif — only valid for vuln, clones).
probe "05-format-reject-sarif" "tldr definition backend/providers/yahoo.py 40 12 -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes — flags, modes, edge cases.
# -----------------------------------------------------------------------------

# P06: format text — human-readable text rendering.
probe "06-format-text" "tldr definition backend/providers/yahoo.py 40 12 -f text"

# P07: format compact — token-efficient compact rendering.
probe "07-format-compact" "tldr definition backend/providers/yahoo.py 40 12 -f compact"

# P08: --symbol mode without --file — should hit the explicit
# "--file is required with --symbol" validator.
probe "08-symbol-no-file" "tldr definition --symbol HistoricalDataProvider"

# P09: format dot — also command-specific; rejected for definition.
probe "09-format-reject-dot" "tldr definition backend/providers/yahoo.py 40 12 -f dot"

# P10: name-based with --symbol but symbol genuinely not found anywhere.
# Exercises the exit-20 SymbolNotFound path (med-low-schema-cleanup-v1 N9).
probe "10-symbol-not-found" "tldr definition --symbol NoSuchSymbol --file backend/providers/yahoo.py --project ."

# P11: position-based, cursor on a Python builtin (`print`) — exercises the
# PYTHON_BUILTINS list and the `is_builtin: true` payload (no location).
probe "11-builtin-print" "tldr definition backend/db.py 1 1 -l python --symbol print --file backend/db.py"

# P12: --workspace=false suppresses auto-detection of project root.
# Without explicit --project, this forces strict in-file resolution.
probe "12-workspace-false" "tldr definition --symbol HistoricalDataProvider --file backend/providers/yahoo.py --workspace=false"

# P13: unsupported language hint — exercises the `unsupported_language`
# validator in detect_language().
probe "13-bad-lang" "tldr definition backend/providers/yahoo.py 40 12 -l brainfuck"

# P14: position-based on a non-source file (markdown). Auto-detect fails,
# exercising the autodetect-unsupported branch.
probe "14-non-source-md" "tldr definition README.md 1 1"

# P15: position-based, cursor on whitespace / unresolved symbol.
# Exercises the "unresolved at FILE:LINE:COL — symbol 'X' not found in scope"
# sentinel from definition-name-resolution-v1.
probe "15-pos-unresolved" "tldr definition backend/providers/yahoo.py 1 0"

# P16: column out of range (column > line length). Confirms behavior when
# tree-sitter cannot anchor a node at the given point.
probe "16-col-out-of-range" "tldr definition backend/providers/yahoo.py 40 9999"

# P17: line out of range (line > file line count). Exercises bounds handling
# in find_symbol_at_position.
probe "17-line-out-of-range" "tldr definition backend/providers/yahoo.py 999999 0"

# P18: --output to file — writes JSON to a file rather than stdout.
OUTPUT_TMP="$(mktemp)"
probe "18-output-file" "tldr definition backend/providers/yahoo.py 40 12 -O $OUTPUT_TMP && cat $OUTPUT_TMP"
rm -f "$OUTPUT_TMP"

# P19: Python cross-file follows import edges only. `Provider` IS imported
# in yahoo.py (`from backend.providers.base import Provider`), so it
# resolves; contrast with P02 which queried `HistoricalDataProvider` —
# defined in base.py but NOT imported by yahoo.py.
probe "19-imported-symbol" "tldr definition --symbol Provider --file backend/providers/yahoo.py --project ."

# P20: Position-based on a method-call usage site. Confirms the three-pass
# resolver (definition-name-resolution-v1) jumps from a usage to the
# declaration. Calling `self.fetch_historical_data` would normally need
# class-method resolution; pick a simpler case: a use of an imported
# module name (`pd`).
probe "20-usage-site" "tldr definition backend/providers/yahoo.py 12 0"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
