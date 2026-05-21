#!/usr/bin/env bash
# Regenerates all probe captures for `tldr context`.
#
# Usage:   bash research/tldr/search/context.probes/probe.sh
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

echo "Probing tldr context against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small entry; tests default depth=3 from project root.
probe "01-happy" "tldr context _to_finite_float backend -l python"

# P02: happy-scale — instance method entry across the full backend.
probe "02-happy-scale" "tldr context fetch_historical_data backend -l python"

# P03: missing required arg.
probe "03-missing-arg" "tldr context"

# P04: bad path.
probe "04-badpath" "tldr context some_fn /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr context _to_finite_float backend -l python -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text — emits LLM-string format via context.to_llm_string().
probe "06-format-text" "tldr context _to_finite_float backend -l python -f text"

# P07: format compact — single-line JSON.
probe "07-format-compact" "tldr context _to_finite_float backend -l python -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr context _to_finite_float backend -l python -f dot"

# P09: --depth 1 — exercises shallow traversal.
probe "09-depth-one" "tldr context fetch_historical_data backend -l python -d 1"

# P10: --depth 10 — exercises deep traversal.
probe "10-depth-ten" "tldr context fetch_historical_data backend -l python -d 10"

# P11: --include-docstrings — should include docstring text in output.
probe "11-with-docstrings" "tldr context _to_finite_float backend -l python --include-docstrings"

# P12: --file disambiguator — forces direct-compute (per imports.rs:124).
probe "12-file-filter" "tldr context fetch_historical_data backend -l python --file backend/providers/yahoo.py"

# P13: <file>:<func> shorthand — auto-derives project root and --file.
probe "13-shorthand" "tldr context backend/providers/yahoo.py:fetch_historical_data"

# P14: entry not found — what does the engine return?
probe "14-entry-not-found" "tldr context no_such_entry backend -l python"

# P15: bad --lang (clap rejection).
probe "15-bad-lang" "tldr context _to_finite_float backend -l brainfuck"

# P16: deprecated -p/--project alias (positional takes precedence when not "."):
# pass positional "." and --project backend → --project wins per
# effective_project().
probe "16-project-alias" "tldr context _to_finite_float -p backend -l python"

# P17: -q suppresses progress.
probe "17-quiet" "tldr context _to_finite_float backend -l python -q"

# -----------------------------------------------------------------------------
# Daemon route probes
# -----------------------------------------------------------------------------

# P18: cold-daemon — daemon stopped, direct-compute path.
tldr daemon stop > /dev/null 2>&1 || true
probe "18-cold-daemon" "tldr context fetch_historical_data backend -l python"

# P19: warm-daemon.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "19-warm-daemon" "tldr context fetch_historical_data backend -l python"

# P20: warm-daemon + --file (should force direct-compute per the
# `if effective_file.is_none()` gate at context.rs:124).
probe "20-warm-daemon-file-filter" "tldr context fetch_historical_data backend -l python --file backend/providers/yahoo.py"

# P21: default-path mixed-language failure mode similar to importers.
# With path=".", language=Python may be wrongly auto-detected to TS by
# Language::from_directory(".") on Stock-Monitor (has webui/ TS dir).
probe "21-default-path" "tldr context _to_finite_float"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
