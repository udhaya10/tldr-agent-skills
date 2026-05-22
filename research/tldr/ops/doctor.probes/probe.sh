#!/usr/bin/env bash
# Regenerates all probe captures for `tldr doctor`.
#
# Usage:   bash research/tldr/ops/doctor.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: `tldr doctor` is OMITTED from agent-facing skills (per 05_OMITTED_
# COMMANDS_RATIONALE.md §2) — it's a human-operator command for checking
# local environment. Probed for research completeness.
#
# CAUTION: --install runs actual installation commands. We probe with a
# bogus language to verify error handling without modifying the system.

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

echo "Probing tldr doctor ..."
cd "$TARGET_REPO" || cd "$HOME"

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — check mode default (text output).
probe "01-happy" "tldr doctor"

# P02: happy-scale — JSON format (verbose output).
probe "02-happy-scale" "tldr doctor -f json -q"

# P03: PATH defaults to none (no required positional) — N/A.
echo "No required positional arg — N/A row in matrix" > "${CMD_DIR}/03-missing-arg.cmd"
echo "" > "${CMD_DIR}/03-missing-arg.out"
echo "exit=0 (N/A)" > "${CMD_DIR}/03-missing-arg.err"

# P04: bad install language.
probe "04-badpath" "tldr doctor --install brainfuck"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr doctor -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text (default).
probe "06-format-text" "tldr doctor -f text"

# P07: format compact.
probe "07-format-compact" "tldr doctor -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr doctor -f dot"

# P09: --install python (DANGEROUS — actually runs install! Capture but probe runs in subprocess).
# Skip actual install; just probe for the install command echo.
echo "tldr doctor --install python  # SKIPPED — would actually run install" > "${CMD_DIR}/09-install-python.cmd"
echo "skipped — actual install not run" > "${CMD_DIR}/09-install-python.out"
echo "exit=0 (skipped)" > "${CMD_DIR}/09-install-python.err"

# P10: --install bogus.
probe "10-install-bogus" "tldr doctor --install wat"

# P11: -l python explicit (should be IGNORED — doctor doesn't filter by lang).
probe "11-lang-python" "tldr doctor -l python"

# P12: -l typescript explicit.
probe "12-lang-typescript" "tldr doctor -l typescript"

# P13: bad --lang.
probe "13-bad-lang" "tldr doctor -l brainfuck"

# P14: -q quiet.
probe "14-quiet" "tldr doctor -q"

# P15: --install python --install (multiple).
probe "15-install-multiple" "tldr doctor --install python --install rust"

# P16: --install with empty string.
probe "16-install-empty" "tldr doctor --install ''"

# P17: Run from non-git, non-source dir (doctor shouldn't care about cwd).
TMP_DIR="$(mktemp -d)"
probe "17-from-tmp" "cd $TMP_DIR && tldr doctor -f json -q"
rmdir "$TMP_DIR"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
