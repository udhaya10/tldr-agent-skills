#!/usr/bin/env bash
# Regenerates all probe captures for `tldr explain`.
#
# Usage:   bash research/tldr/overview/explain.probes/probe.sh
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

echo "Probing tldr explain against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, smallest meaningful input — module-level helper.
probe "01-happy" "tldr explain backend/providers/yahoo.py _to_finite_float"

# P02: happy-scale — instance method on YahooProvider; depth=2 default
# exercises caller/callee discovery across the project.
probe "02-happy-scale" "tldr explain backend/providers/yahoo.py fetch_historical_data"

# P03: missing required arg — supply file but not function.
probe "03-missing-arg" "tldr explain backend/providers/yahoo.py"

# P04: non-existent path.
probe "04-badpath" "tldr explain /no/such/file.py some_fn"

# P05: format rejection — sarif is only for vuln / clones.
probe "05-format-reject-sarif" "tldr explain backend/providers/yahoo.py _to_finite_float -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes — flags, depths, format variants.
# -----------------------------------------------------------------------------

# P06: format text — human-readable rendering.
probe "06-format-text" "tldr explain backend/providers/yahoo.py _to_finite_float -f text"

# P07: format compact — minified JSON.
probe "07-format-compact" "tldr explain backend/providers/yahoo.py _to_finite_float -f compact"

# P08: dot format reject (dot is for calls/impact/hubs/inheritance/clones/deps,
# NOT explain).
probe "08-format-reject-dot" "tldr explain backend/providers/yahoo.py _to_finite_float -f dot"

# P09: --depth 0 — bound caller/callee traversal to nothing.
probe "09-depth-zero" "tldr explain backend/providers/yahoo.py fetch_historical_data --depth 0"

# P10: --depth 5 — expand caller/callee depth.
probe "10-depth-five" "tldr explain backend/providers/yahoo.py fetch_historical_data --depth 5"

# P11: function name does not exist — exit-20 SymbolNotFound.
probe "11-function-not-found" "tldr explain backend/providers/yahoo.py no_such_function"

# P12: qualified Class.method form — find_function_node handles dotted names.
probe "12-qualified-name" "tldr explain backend/providers/yahoo.py YahooProvider.fetch_historical_data"

# P13: explicit --lang python overrides auto-detect.
probe "13-lang-flag" "tldr explain backend/providers/yahoo.py _to_finite_float -l python"

# P14: invalid --lang (clap-level rejection).
probe "14-bad-lang" "tldr explain backend/providers/yahoo.py _to_finite_float -l brainfuck"

# P15: --output writes to file; stdout still gets a copy (per source).
OUTPUT_TMP="$(mktemp)"
probe "15-output-file" "tldr explain backend/providers/yahoo.py _to_finite_float -o $OUTPUT_TMP && echo '--FILE--' && cat $OUTPUT_TMP"
rm -f "$OUTPUT_TMP"

# P16: non-source file (markdown). Unsupported language → exit 1 with
# parse-error wrapper.
probe "16-non-source-md" "tldr explain README.md anything"

# P17: directory as FILE argument — fs validation should fail.
probe "17-directory-arg" "tldr explain backend anything"

# P18: nonexistent qualified method with valid class — confirms fallback
# to last-component bare lookup (find_function_node Class.method branch).
probe "18-qualified-miss" "tldr explain backend/providers/yahoo.py YahooProvider.no_such_method"

# P19: -q quiet flag suppresses the "Analyzing function ..." progress msg.
probe "19-quiet" "tldr explain backend/providers/yahoo.py _to_finite_float -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
