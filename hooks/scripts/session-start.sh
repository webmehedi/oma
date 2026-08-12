#!/usr/bin/env bash
# OMA — SessionStart hook.
# If this project has an OMA workspace, inject a five-line status summary so a
# fresh session knows where the project stands without reading anything else.
# Fails open: any internal error exits 0 with no output.

[ -f ".oma/state.json" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - <<'PY' 2>/dev/null || exit 0
import json

try:
    s = json.load(open(".oma/state.json"))
except Exception:
    raise SystemExit(0)

proj = s.get("project", {})
phase = s.get("phase", {})
gates = s.get("gates", [])
frozen = [k for k, v in (s.get("contracts") or {}).items() if v.get("frozen")]
blocking = [q for q in s.get("open_questions", []) if q.get("blocking")]

approved = sum(1 for g in gates if g.get("status") == "approved")
lines = [
    "[OMA] This project is managed by the OMA plugin (One Man Army).",
    f"[OMA] Project: {proj.get('name', '?')} — {proj.get('one_liner', '')}".rstrip(),
    f"[OMA] Phase: {phase.get('current', '?')} ({phase.get('status', '?')}) · gates approved: {approved}",
    f"[OMA] Frozen contracts: {', '.join(frozen) if frozen else 'none'} · blocking questions for the user: {len(blocking)}",
    "[OMA] Run /oma:status for detail. Never edit .oma/state.json by hand — use the /oma:* skills.",
]
print("\n".join(lines))
PY
exit 0
