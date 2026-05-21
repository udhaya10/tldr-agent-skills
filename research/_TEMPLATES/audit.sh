#!/usr/bin/env bash
# Mechanically check a dossier against Journal 04 §11 structural checklist.
#
# Usage: bash research/_TEMPLATES/audit.sh research/tldr/<group>/<command>.md
#
# Checks the structural items (sections 1-7 of the compliance checklist).
# Semantic checks (e.g., "Agent Synthesis reflects every flag") still require
# a human/LLM reviewer.

set -uo pipefail

DOSSIER="${1:-}"
if [ -z "$DOSSIER" ] || [ ! -f "$DOSSIER" ]; then
    echo "Usage: $0 <path-to-dossier.md>" >&2
    exit 2
fi

PROBES_DIR="${DOSSIER%.md}.probes"
PASS=0
FAIL=0

check() {
    local label="$1"
    local condition="$2"
    if eval "$condition"; then
        echo "  [PASS] $label"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $label"
        FAIL=$((FAIL + 1))
    fi
}

echo "Auditing: $DOSSIER"
echo

check "Title follows '# Command: \`tldr <cmd>\`'" \
    "head -n 1 '$DOSSIER' | grep -qE '^# Command: \`tldr '"

check "Environment Pin section present" \
    "grep -qE '^## Environment Pin' '$DOSSIER'"

check "Ground Truth section present" \
    "grep -qE '^## Ground Truth' '$DOSSIER'"

check "Output Shape section present" \
    "grep -qE '^## Output Shape' '$DOSSIER'"

check "Probe Matrix section present" \
    "grep -qE '^## Probe Matrix' '$DOSSIER'"

check "Source Code Reality section present" \
    "grep -qE '^## Source Code Reality' '$DOSSIER'"

check "Architectural Deep Dive section present" \
    "grep -qE '^## Architectural Deep Dive' '$DOSSIER'"

check "Intent & Routing section present" \
    "grep -qE '^## Intent' '$DOSSIER'"

check "Agent Synthesis section present" \
    "grep -qE '^## Agent Synthesis' '$DOSSIER'"

check ".probes/ directory exists" \
    "[ -d '$PROBES_DIR' ]"

check ".probes/probe.sh exists" \
    "[ -f '$PROBES_DIR/probe.sh' ]"

# Helper: probe ID NN has a complete triple OR the dossier marks it N/A with a reason.
probe_present_or_na() {
    local id="$1"
    # All three artifact files present for any slug starting with NN-.
    local have_cmd have_out have_err
    have_cmd=$(ls "$PROBES_DIR/${id}-"*.cmd 2>/dev/null | head -n 1)
    have_out=$(ls "$PROBES_DIR/${id}-"*.out 2>/dev/null | head -n 1)
    have_err=$(ls "$PROBES_DIR/${id}-"*.err 2>/dev/null | head -n 1)
    if [ -n "$have_cmd" ] && [ -n "$have_out" ] && [ -n "$have_err" ]; then
        return 0
    fi
    # Or dossier explicitly marks this ID as N/A with a reason.
    if grep -qE "\| P${id} \|.*N/A:" "$DOSSIER"; then
        return 0
    fi
    return 1
}

check "P01 (happy) capture triple present" \
    "probe_present_or_na 01"

check "P02 (happy-scale) capture triple present" \
    "probe_present_or_na 02"

check "P03 (missing-input) capture or N/A marker" \
    "probe_present_or_na 03"

check "P04 (badpath) capture present" \
    "probe_present_or_na 04"

check "P05 (format validation) capture present" \
    "probe_present_or_na 05"

check "No placeholder text" \
    "! grep -q 'Tool evaluated and integrated successfully via batch script profiling' '$DOSSIER'"

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
