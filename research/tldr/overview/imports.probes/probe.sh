#!/usr/bin/env bash
# Regenerates all probe captures for `tldr imports`.
#
# Usage:   bash research/tldr/overview/imports.probes/probe.sh
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

echo "Probing tldr imports against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Ensure daemon is OFF for cold probes.
tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — small file with a few imports (base.py: ~5 imports).
probe "01-happy" "tldr imports backend/providers/base.py"

# P02: happy-scale — yahoo.py has ~7 imports including from-aliases.
probe "02-happy-scale" "tldr imports backend/providers/yahoo.py"

# P03: missing required arg.
probe "03-missing-arg" "tldr imports"

# P04: non-existent path.
probe "04-badpath" "tldr imports /no/such/file.py"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr imports backend/providers/base.py -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text — uses format_imports_text + bold filename header.
probe "06-format-text" "tldr imports backend/providers/base.py -f text"

# P07: format compact — single-line JSON envelope.
probe "07-format-compact" "tldr imports backend/providers/base.py -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr imports backend/providers/base.py -f dot"

# P09: explicit --lang python — should match auto-detect output.
probe "09-lang-python" "tldr imports backend/providers/base.py -l python"

# P10: bad --lang (clap-level rejection).
probe "10-bad-lang" "tldr imports backend/providers/base.py -l brainfuck"

# P11: --legacy-array — bare array shape (pre-BUG-18).
probe "11-legacy-array" "tldr imports backend/providers/base.py --legacy-array"

# P12: --lang typescript on a .py file — mis-extension override.
probe "12-lang-mismatch" "tldr imports backend/providers/base.py -l typescript"

# P13: directory as FILE — engine should fail.
probe "13-directory-arg" "tldr imports backend"

# P14: non-source file (.md) — language detect should fail.
probe "14-non-source-md" "tldr imports README.md"

# P15: -q suppresses the "Parsing imports from ..." progress message.
probe "15-quiet" "tldr imports backend/providers/yahoo.py -q"

# -----------------------------------------------------------------------------
# Daemon route probes (try_daemon_route is called at imports.rs:62).
# Note: project root passed to try_daemon_route is file.parent() — the
# daemon may not have been started for the file's parent dir.
# -----------------------------------------------------------------------------

# P16: cold-daemon — daemon stopped, direct-compute path.
tldr daemon stop > /dev/null 2>&1 || true
probe "16-cold-daemon" "tldr imports backend/providers/yahoo.py"

# P17: warm-daemon — start daemon at project root, warm, then probe.
tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1 || true
tldr warm "$TARGET_REPO" > /dev/null 2>&1 || true
probe "17-warm-daemon" "tldr imports backend/providers/yahoo.py"

# P18: warm-daemon + --legacy-array — does daemon path honor the
# array-vs-envelope toggle?
probe "18-warm-daemon-legacy-array" "tldr imports backend/providers/yahoo.py --legacy-array"

# P19: warm-daemon + --lang typescript on .py — does daemon forward
# `language` key (params_with_file_lang DOES include language, per
# daemon_router.rs:179).
probe "19-warm-daemon-lang-mismatch" "tldr imports backend/providers/base.py -l typescript"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
