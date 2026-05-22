#!/usr/bin/env bash
# Regenerates all probe captures for `tldr daemon` (multi-subcommand).
#
# Usage:   bash research/tldr/ops/daemon.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Note: `tldr daemon` has 6 subcommands (start, stop, status, list, query,
# notify). This dossier covers the whole family per OMITTED_RATIONALE §3.

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

echo "Probing tldr daemon against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# Make sure daemon is stopped at start.
tldr daemon stop > /dev/null 2>&1 || true

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy — status (no daemon running yet).
probe "01-happy" "tldr daemon status"

# P02: happy-scale — start, then status, then stop.
probe "02-happy-scale" "tldr daemon start && tldr daemon status && tldr daemon stop"

# P03: missing subcommand.
probe "03-missing-arg" "tldr daemon"

# P04: bad --project path on status.
probe "04-badpath" "tldr daemon status --project /no/such/dir"

# P05: format reject sarif.
probe "05-format-reject-sarif" "tldr daemon status -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes
# -----------------------------------------------------------------------------

# P06: format text.
probe "06-format-text" "tldr daemon status -f text"

# P07: format compact.
probe "07-format-compact" "tldr daemon status -f compact"

# P08: format reject dot.
probe "08-format-reject-dot" "tldr daemon status -f dot"

# P09: daemon start.
probe "09-start" "tldr daemon start --project ."

# P10: daemon start when already running.
probe "10-start-already-running" "tldr daemon start --project ."

# P11: daemon list.
probe "11-list" "tldr daemon list"

# P12: daemon status (with daemon running).
probe "12-status-running" "tldr daemon status"

# P13: daemon query ping.
probe "13-query-ping" "tldr daemon query ping"

# P14: daemon query bogus command.
probe "14-query-bogus" "tldr daemon query wat"

# P15: daemon query with --json.
probe "15-query-with-json" "tldr daemon query status --json '{}'"

# P16: daemon query bad JSON.
probe "16-query-bad-json" "tldr daemon query status --json '{ malformed'"

# P17: daemon notify (file).
probe "17-notify" "tldr daemon notify backend/providers/yahoo.py"

# P18: daemon notify bad path.
probe "18-notify-badpath" "tldr daemon notify /no/such/file.py"

# P19: daemon stop.
probe "19-stop" "tldr daemon stop --project ."

# P20: daemon stop when not running.
probe "20-stop-not-running" "tldr daemon stop --project ."

# P21: daemon stop --all.
probe "21-stop-all" "tldr daemon stop --all"

# P22: daemon status when no daemon.
probe "22-status-no-daemon" "tldr daemon status"

# P23: daemon list when none running.
probe "23-list-empty" "tldr daemon list"

# P24: bad subcommand.
probe "24-bad-subcommand" "tldr daemon wat"

# P25: bad --lang.
probe "25-bad-lang" "tldr daemon status -l brainfuck"

# P26: -q quiet.
probe "26-quiet" "tldr daemon status -q"

# P27: start --foreground (would BLOCK — use timeout + kill).
probe "27-start-foreground" "timeout 1 tldr daemon start --foreground 2>&1 | head -5; true"

cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
