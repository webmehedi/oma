#!/usr/bin/env bash
# OMA — PreToolUse guard on Write|Edit.
# In brownfield AUDIT mode, OMA assesses and never changes source. This denies
# any write outside .oma/ so an audit cannot silently "fix while it's in there".
# Inactive in every other mode (greenfield, extend, refactor) — those write code.
# Fails open: any internal error exits 0 (allow) so a hook bug never blocks work.

command -v python3 >/dev/null 2>&1 || exit 0
TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

python3 - "$TMP" <<'PY' 2>/dev/null || exit 0
import json, os, sys

try:
    data = json.load(open(sys.argv[1]))
except Exception:
    raise SystemExit(0)

path = (data.get("tool_input") or {}).get("file_path") or ""
cwd = data.get("cwd") or os.getcwd()
state_path = os.path.join(cwd, ".oma", "state.json")
if not path or not os.path.exists(state_path):
    raise SystemExit(0)

try:
    state = json.load(open(state_path))
except Exception:
    raise SystemExit(0)

# Only active in brownfield audit mode.
if state.get("mode") != "brownfield":
    raise SystemExit(0)
if ((state.get("brownfield") or {}).get("scope")) != "audit":
    raise SystemExit(0)

target = os.path.realpath(path if os.path.isabs(path) else os.path.join(cwd, path))
oma_dir = os.path.realpath(os.path.join(cwd, ".oma"))

# Writes inside .oma/ are the audit's own findings and backlog — allowed.
if target == oma_dir or target.startswith(oma_dir + os.sep):
    raise SystemExit(0)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": (
            "This project is in brownfield AUDIT mode, which changes no source "
            "code — it produces findings and a prioritized backlog only. Write "
            "your assessment under .oma/ (a task in .oma/04-build/tasks.json, a "
            "note in the relevant .oma/ artifact) instead of editing the file. "
            "If the user wants changes made, they re-init with scope 'extend' or "
            "'refactor'."
        ),
    }
}))
raise SystemExit(0)
PY
exit 0
