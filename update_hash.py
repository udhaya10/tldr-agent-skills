#!/usr/bin/env python3
"""
Recompute and embed the hash in an agent-rules file after editing its body.
Run this after any change to the body content between the markers.

Usage: python update_hash.py [path/to/agent-rules.md]
       Defaults to agent-rules.md in the current directory.
"""
import hashlib
import re
import sys
from pathlib import Path

BEGIN_RE = re.compile(r"<!-- BEGIN TLDR-AGENT-SKILLS(?:[^>]*)-->")
END_MARKER = "<!-- END TLDR-AGENT-SKILLS -->"


def compute_hash(body: str) -> str:
    digest = hashlib.sha256(body.encode()).digest()
    return digest[:4].hex()


def update(filepath: Path) -> None:
    content = filepath.read_text()

    begin_match = BEGIN_RE.search(content)
    if not begin_match:
        sys.exit(f"ERROR: no BEGIN TLDR-AGENT-SKILLS marker found in {filepath}")

    end_idx = content.find(END_MARKER)
    if end_idx == -1:
        sys.exit(f"ERROR: no END TLDR-AGENT-SKILLS marker found in {filepath}")

    if end_idx < begin_match.end():
        sys.exit(f"ERROR: END marker appears before BEGIN marker in {filepath}")

    # Body = text after the newline that follows BEGIN, up to (not including) END
    body_start = content.index("\n", begin_match.start()) + 1
    body = content[body_start:end_idx].rstrip("\n")

    new_hash = compute_hash(body)

    old_match = re.search(r"hash:([a-f0-9]+)", begin_match.group())
    old_hash = old_match.group(1) if old_match else "none"

    new_begin = f"<!-- BEGIN TLDR-AGENT-SKILLS hash:{new_hash} -->"
    new_content = (
        content[: begin_match.start()]
        + new_begin + "\n"
        + body + "\n"
        + END_MARKER + "\n"
        + content[end_idx + len(END_MARKER) :].lstrip("\n")
    )

    filepath.write_text(new_content)
    print(f"✅  {filepath}")
    print(f"    hash: {old_hash} → {new_hash}")


if __name__ == "__main__":
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "agent-rules.md")
    if not target.exists():
        sys.exit(f"ERROR: {target} not found")
    update(target)
