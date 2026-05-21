#!/usr/bin/env bash
# Regenerates all probe captures for `tldr loc`.
#
# Usage:   bash research/tldr/audit/loc.probes/probe.sh
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

echo "Probing tldr loc against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — single file.
probe "01-happy" "tldr loc backend/providers/yahoo.py"

# P02: happy-scale — full backend.
probe "02-happy-scale" "tldr loc backend"

# P03: PATH defaults to '.' — N/A.
echo "PATH defaults to '.' — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad path.
probe "04-badpath" "tldr loc /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr loc backend/providers -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr loc backend/providers -f text"

# P07: format compact.
probe "07-format-compact" "tldr loc backend/providers -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr loc backend/providers -f dot"

# P09: --by-file.
probe "09-by-file" "tldr loc backend/providers --by-file"

# P10: --by-dir.
probe "10-by-dir" "tldr loc backend --by-dir"

# P11: --by-file AND --by-dir.
probe "11-by-file-and-dir" "tldr loc backend --by-file --by-dir"

# P12: -l python explicit.
probe "12-lang-python" "tldr loc backend -l python"

# P13: -l typescript (different language).
probe "13-lang-typescript" "tldr loc . -l typescript"

# P14: bad --lang.
probe "14-bad-lang" "tldr loc backend -l brainfuck"

# P15: --exclude.
probe "15-exclude" "tldr loc backend/providers --exclude '__init__.py' --by-file"

# P16: --include-hidden.
probe "16-include-hidden" "tldr loc backend/providers --include-hidden"

# P17: --no-gitignore.
probe "17-no-gitignore" "tldr loc . --no-gitignore --max-files 5"

# P18: --max-files 1.
probe "18-max-files-low" "tldr loc backend --max-files 1"

# P19: --max-files 0 (unlimited).
probe "19-max-files-zero" "tldr loc backend/providers --max-files 0"

# P20: empty dir.
EMPTY_DIR="$(mktemp -d)"
probe "20-empty-dir" "tldr loc $EMPTY_DIR"
rmdir "$EMPTY_DIR"

# P21: non-source markdown file.
probe "21-non-source-md" "tldr loc README.md"

# P22: -q quiet.
probe "22-quiet" "tldr loc backend/providers -q"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
