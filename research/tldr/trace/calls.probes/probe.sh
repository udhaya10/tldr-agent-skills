#!/usr/bin/env bash
# Regenerates all probe captures for `tldr calls`.
#
# Usage:   bash research/tldr/trace/calls.probes/probe.sh
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

echo "Probing tldr calls against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small focused subdir (backend/providers ~4 files).
probe "01-happy" "tldr calls backend/providers -l python"

# P02: happy-scale — full backend (~56 Python files).
probe "02-happy-scale" "tldr calls backend -l python"

# P03: missing required arg — PATH defaults to `.`, no required positional.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr calls /no/such/dir"

# P05: format reject sarif (calls SUPPORTS dot, NOT sarif).
probe "05-format-reject-sarif" "tldr calls backend/providers -l python -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr calls backend/providers -l python -f text"

# P07: format compact.
probe "07-format-compact" "tldr calls backend/providers -l python -f compact"

# P08: format dot — calls IS in DOT_SUPPORTED.
probe "08-format-dot" "tldr calls backend/providers -l python -f dot"

# P09: --max-items 5 — truncation should fire on backend (>5 edges).
probe "09-max-items-small" "tldr calls backend -l python --max-items 5"

# P10: --max-items 99999 — no truncation.
probe "10-max-items-large" "tldr calls backend -l python --max-items 99999"

# P11: --respect-ignore=false — include gitignored files. Stock-Monitor's
# .gitignore excludes __pycache__, venv, etc.
probe "11-no-respect-ignore" "tldr calls backend/providers -l python --respect-ignore=false"

# P12: bad --lang (clap rejection).
probe "12-bad-lang" "tldr calls backend -l brainfuck"

# P13: empty directory — language detection should yield None, then
# language: null in JSON (per P2.BUG-10 fix).
EMPTY_DIR="$(mktemp -d)"
probe "13-empty-dir" "tldr calls $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P14: --lang python override on mixed-language root.
probe "14-mixed-root-python" "tldr calls . -l python --max-items 50"

# P15: -q suppress progress.
probe "15-quiet" "tldr calls backend/providers -l python -q"

# -----------------------------------------------------------------------------
# Daemon route probes
# -----------------------------------------------------------------------------

# P16: cold daemon — daemon stopped.
tldr daemon stop > /dev/null 2>&1 || true
probe "16-cold-daemon" "tldr calls backend -l python"

# P17: warm daemon.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "17-warm-daemon" "tldr calls backend -l python"

# P18: warm daemon + dot output (exercises the daemon-DOT branch at
# calls.rs:145-171, gated by surface-gaps-v1 BUG-19).
probe "18-warm-daemon-dot" "tldr calls backend -l python -f dot"

# P19: warm daemon + text output.
probe "19-warm-daemon-text" "tldr calls backend -l python -f text"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
