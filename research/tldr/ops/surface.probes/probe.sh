#!/usr/bin/env bash
# Regenerates all probe captures for `tldr surface`.
#
# Usage:   bash research/tldr/ops/surface.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: `tldr surface` is OMITTED from agent-facing skills (per 05_OMITTED_
# COMMANDS_RATIONALE.md §2) — outputs massive raw structural data; agents
# are better served by tldr api-check or tldr interface.

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

echo "Probing tldr surface against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — stdlib package "json" (Python).
probe "01-happy" "tldr surface json"

# P02: happy-scale — directory path.
probe "02-happy-scale" "tldr surface backend/providers"

# P03: missing required arg.
probe "03-missing-arg" "tldr surface"

# P04: bad target (unknown package).
probe "04-badpath" "tldr surface no_such_package_zzz_brainfuck"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr surface json -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr surface json -f text"

# P07: format compact.
probe "07-format-compact" "tldr surface json -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr surface json -f dot"

# P09: --lookup specific API.
probe "09-lookup" "tldr surface json --lookup json.loads"

# P10: --lookup not found.
probe "10-lookup-not-found" "tldr surface json --lookup json.no_such_function"

# P11: --include-private.
probe "11-include-private" "tldr surface json --include-private"

# P12: --limit 5.
probe "12-limit-low" "tldr surface json --limit 5"

# P13: --limit 0 (edge).
probe "13-limit-zero" "tldr surface json --limit 0"

# P14: --manifest-path (Rust-specific).
probe "14-manifest-path" "tldr surface json --manifest-path /no/such/Cargo.toml"

# P15: bad --lang.
probe "15-bad-lang" "tldr surface json -l brainfuck"

# P16: -l python explicit.
probe "16-lang-python" "tldr surface json -l python"

# P17: -l typescript on Python target.
probe "17-lang-mismatch" "tldr surface json -l typescript"

# P18: target as directory.
probe "18-target-as-directory" "tldr surface backend"

# P19: empty dir target.
EMPTY_DIR="$(mktemp -d)"
probe "19-empty-dir" "tldr surface $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P20: -q quiet.
probe "20-quiet" "tldr surface json -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
