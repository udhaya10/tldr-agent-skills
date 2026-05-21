#!/usr/bin/env bash
# Regenerates all probe captures for `tldr <command>`.
#
# Usage:   bash research/tldr/<group>/<command>.probes/probe.sh
# Idempotent: overwrites existing .cmd/.out/.err triples in place.
#
# Capture convention (Journal 04, §5):
#   <id>-<slug>.cmd   exact bash invocation (one logical command per file)
#   <id>-<slug>.out   stdout, truncated per protocol if > 500 lines
#   <id>-<slug>.err   stderr, with trailing "exit=<N>" line appended

set -uo pipefail

# Pin to the directory this script lives in so probes write next to it.
CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CMD_DIR"

# Resolve repo paths used by probes. Adjust if running from elsewhere.
TARGET_REPO="${TARGET_REPO:-/Users/udhayakumar/Workspace/17-Roshan-Projects/Stock-Monitor}"

# Helper: runs a probe, captures stdout/stderr/exit, applies truncation rule.
# Usage: probe <id-slug> <bash command...>
#
# The bash command runs with the current working directory ($PWD) so probes
# resolve relative paths against the target repo. Output files are written
# with absolute paths anchored to $CMD_DIR so they always land in .probes/
# regardless of where the probe was invoked from.
probe() {
    local slug="$1"
    shift
    local cmd="$*"

    echo "$cmd" > "${CMD_DIR}/${slug}.cmd"

    # Capture stdout and stderr to temp files first so we can apply truncation.
    local out_tmp err_tmp
    out_tmp="$(mktemp)"
    err_tmp="$(mktemp)"
    bash -c "$cmd" > "$out_tmp" 2> "$err_tmp"
    local rc=$?

    # Truncation: > 500 lines → first 400 + marker + last 50.
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

    # Stderr verbatim + exit code.
    {
        cat "$err_tmp"
        echo "exit=${rc}"
    } > "${CMD_DIR}/${slug}.err"

    rm -f "$out_tmp" "$err_tmp"
    printf "  %-30s exit=%d  stdout=%d lines\n" "$slug" "$rc" "$lines"
}

echo "Probing tldr <command> against $TARGET_REPO ..."
cd "$TARGET_REPO" || { echo "Target repo not found: $TARGET_REPO" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Mandatory probes (Journal 04 §4.2)
# -----------------------------------------------------------------------------

# P01: happy path, smallest meaningful input
probe "01-happy" "tldr <command> <minimal-args>"

# P02: happy path, realistic scale
probe "02-happy-scale" "tldr <command> <realistic-args>"

# P03: required positional omitted
probe "03-missing-arg" "tldr <command>"

# P04: non-existent path
probe "04-badpath" "tldr <command> /no/such/path"

# P05: format that should be rejected (sarif/dot for most commands)
probe "05-format-reject" "tldr <command> <args> -f sarif"

# -----------------------------------------------------------------------------
# Conditional probes — add per Journal 04 §4.3
# -----------------------------------------------------------------------------

# Example: probe "06-text" "tldr <command> <args> -f text"
#
# Cold-vs-warm daemon probes — the daemon cache must be POPULATED, not just
# running. A daemon at `files: 0` will fall through to the compute path on
# every call and the "warm" probe will be indistinguishable from cold.
# Always run `tldr warm` before the warm probe:
#
#   tldr daemon stop > /dev/null 2>&1 || true
#   probe "07-cold-daemon" "tldr <command> <args>"
#   tldr daemon start --project "$TARGET_REPO" > /dev/null 2>&1
#   tldr warm "$TARGET_REPO" > /dev/null 2>&1
#   probe "08-warm-daemon" "tldr <command> <args>"
#
# Composition probes — capture the prerequisite + the chain in one .cmd:
# Example: probe "09-composition" "tldr extract <file> | jq ... && tldr <command> ..."

# Return to the probes directory so trailing message is correct.
cd "$CMD_DIR"
echo "Done. Captures written to $CMD_DIR"
