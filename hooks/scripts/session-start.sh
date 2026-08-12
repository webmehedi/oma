#!/usr/bin/env bash
# OMA — SessionStart hook.
# If this project has an OMA workspace, inject a five-line status summary so a
# fresh session knows where the project stands without reading anything else.
# Reads the project directory from the hook payload's `cwd` rather than assuming
# the process working directory — a relative path here silently does nothing
# whenever the hook is invoked from anywhere else.
# Fails open: any internal error exits 0 with no output.

command -v python3 >/dev/null 2>&1 || exit 0
TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

python3 - "$TMP" <<'PY' 2>/dev/null || exit 0
import json, os, sys

cwd = os.getcwd()
try:
    d = json.load(open(sys.argv[1]))
    if isinstance(d, dict) and d.get("cwd"):
        cwd = d["cwd"]
except Exception:
    pass

state_path = os.path.join(cwd, ".oma", "state.json")
if not os.path.exists(state_path):
    raise SystemExit(0)

try:
    s = json.load(open(state_path))
except Exception:
    raise SystemExit(0)

proj = s.get("project", {})
phase = s.get("phase", {})
gates = s.get("gates", [])
frozen = [k for k, v in (s.get("contracts") or {}).items() if v.get("frozen")]
blocking = [q for q in s.get("open_questions", []) if q.get("blocking")]
approved = sum(1 for g in gates if g.get("status") == "approved")

mode = ""
if s.get("mode") == "brownfield":
    scope = (s.get("brownfield") or {}).get("scope", "?")
    mode = f" · brownfield ({scope})"

lines = [
    "[OMA] This project is managed by the OMA plugin (One Man Army).",
    f"[OMA] Project: {proj.get('name', '?')} — {proj.get('one_liner', '')}".rstrip(),
    f"[OMA] Phase: {phase.get('current', '?')} ({phase.get('status', '?')}) · gates approved: {approved}{mode}",
    f"[OMA] Frozen contracts: {', '.join(frozen) if frozen else 'none'} · blocking questions for the user: {len(blocking)}",
    "[OMA] Run /oma:status for detail. Never edit .oma/state.json by hand — use the /oma:* skills.",
]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n".join(lines),
    }
}))
PY
exit 0
