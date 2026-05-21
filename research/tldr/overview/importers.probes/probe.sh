#!/usr/bin/env bash
# Regenerates all probe captures for `tldr importers`.
#
# Usage:   bash research/tldr/overview/importers.probes/probe.sh
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

echo "Probing tldr importers against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Ensure daemon is OFF for the first batch — measure cold path.
tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — minimal input. Single intra-project module on the
# default PATH (.) → tests the implicit current-directory default.
probe "01-happy" "tldr importers backend.providers.base"

# P02: happy-scale — popular third-party module across the full backend.
probe "02-happy-scale" "tldr importers pandas backend"

# P03: missing required arg — MODULE is required, PATH defaults to '.'
# so omitting both omits MODULE.
probe "03-missing-arg" "tldr importers"

# P04: non-existent PATH.
probe "04-badpath" "tldr importers pandas /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr importers pandas backend -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text — uses format_importers_text + bold header.
probe "06-format-text" "tldr importers pandas backend -f text"

# P07: format compact — single-line JSON.
probe "07-format-compact" "tldr importers pandas backend -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr importers pandas backend -f dot"

# P09: --limit 1 — exercises apply_limit truncation while keeping
# `total` at the unfiltered count.
probe "09-limit-1" "tldr importers pandas backend --limit 1"

# P10: --limit 0 — "unlimited" per --help; should bypass truncation.
probe "10-limit-zero" "tldr importers pandas backend --limit 0"

# P11: --lang typescript on a python-only directory — exercises
# explicit language override (should yield 0 importers since *.ts
# files don't import `pandas`).
probe "11-lang-override" "tldr importers pandas backend -l typescript"

# P12: bad --lang (clap-level rejection).
probe "12-bad-lang" "tldr importers pandas backend -l brainfuck"

# P13: module that nothing imports — empty-result shape.
probe "13-empty-result" "tldr importers absolutely_no_such_module backend"

# P14: module name with a dotted submodule form.
probe "14-dotted-module" "tldr importers backend.providers.base"

# P15: -q flag suppresses the "Finding files that import ..." progress.
probe "15-quiet" "tldr importers pandas backend -q"

# -----------------------------------------------------------------------------
# Daemon route probes (try_daemon_route is called at importers.rs:49).
# -----------------------------------------------------------------------------

# P16: cold-daemon — daemon stopped, direct-compute fallback path.
tldr daemon stop > /dev/null 2>&1 || true
probe "16-cold-daemon" "tldr importers pandas backend"

# P17: warm-daemon — start daemon, warm the cache, then re-probe.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "17-warm-daemon" "tldr importers pandas backend"

# P18: daemon route — does `--lang typescript` get forwarded?
# (params_with_module does NOT include lang. We expect daemon path to
# IGNORE --lang.)
probe "18-warm-daemon-lang-override" "tldr importers pandas backend -l typescript"

# P19: COLD-path language auto-detect failure mode.
# `tldr importers backend.providers.base` with default PATH=`.` returns
# 0 importers because Language::from_directory(".") picks a non-Python
# language for the mixed-language project root. Same query with
# explicit `-l python` works. Daemon path is unaffected (it indexes
# project-wide regardless of CLI lang flag).
tldr daemon stop > /dev/null 2>&1 || true
probe "19-default-path-bug" "tldr importers backend.providers.base"
probe "20-default-path-lang-python" "tldr importers backend.providers.base -l python"
probe "21-default-path-warm-daemon" "tldr daemon start --project '$TARGET_REPO' >/dev/null 2>&1 && tldr warm '$TARGET_REPO' >/dev/null 2>&1 && tldr importers backend.providers.base"

# Restore quiet state — leave daemon running (don't disrupt user env).
cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
