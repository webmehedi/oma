#!/usr/bin/env bash
# OMA — PreToolUse guard on Write|Edit.
# Denies writes to any contract file marked frozen in .oma/state.json.
# Frozen contracts change only through /oma:change or by re-running the owning
# phase via /oma:phase, both of which unfreeze deliberately and re-hash after.
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

target = os.path.realpath(path if os.path.isabs(path) else os.path.join(cwd, path))

for name, c in (state.get("contracts") or {}).items():
    if not isinstance(c, dict) or not c.get("frozen"):
        continue
    cpath = os.path.realpath(os.path.join(cwd, c.get("path", "")))
    if target == cpath:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    f"{c.get('path')} is the FROZEN '{name}' contract "
                    f"(v{c.get('version', '?')}). Do not edit it. If a change is "
                    "genuinely needed, record it in the 'contract_changes' field of "
                    "your handoff record and stop — the user decides via /oma:change "
                    "or by re-running the owning phase with /oma:phase."
                ),
            }
        }))
        raise SystemExit(0)

raise SystemExit(0)
PY
exit 0
