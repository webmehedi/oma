#!/usr/bin/env bash
# OMA — SubagentStop check.
# When an oma-* agent finishes, verify its final act was appending a handoff
# record to .oma/log/handoffs.jsonl. If not, warn — work with no handoff is
# invisible to every downstream agent. Non-blocking. Fails open.

command -v python3 >/dev/null 2>&1 || exit 0
TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

python3 - "$TMP" <<'PY' 2>/dev/null || exit 0
import json, os, sys

try:
    d = json.load(open(sys.argv[1]))
except Exception:
    raise SystemExit(0)

agent = d.get("agent_type") or ""
if not agent.startswith("oma-"):
    raise SystemExit(0)

cwd = d.get("cwd") or os.getcwd()
path = os.path.join(cwd, ".oma", "log", "handoffs.jsonl")

last_from = None
try:
    with open(path) as f:
        lines = [l for l in f.read().splitlines() if l.strip()]
    if lines:
        last_from = json.loads(lines[-1]).get("from")
except Exception:
    pass

if last_from != agent:
    print(json.dumps({
        "systemMessage": (
            f"[OMA] {agent} finished WITHOUT appending a handoff record to "
            ".oma/log/handoffs.jsonl — its work is invisible to downstream agents. "
            "Reconstruct the handoff from its summary before dispatching anyone else."
        )
    }))
PY
exit 0
