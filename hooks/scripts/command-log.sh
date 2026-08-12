#!/usr/bin/env bash
# OMA — PostToolUse logger on Bash.
# Appends every shell command and its outcome to .oma/log/commands.jsonl.
# This is the anti-fabrication trail: QA reports must cite records from this
# log, so "tests pass" without a corresponding successful run is catchable.
# Fails open: any internal error exits 0.

command -v python3 >/dev/null 2>&1 || exit 0
TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

python3 - "$TMP" <<'PY' 2>/dev/null || exit 0
import datetime, json, os, sys

try:
    d = json.load(open(sys.argv[1]))
except Exception:
    raise SystemExit(0)

cwd = d.get("cwd") or os.getcwd()
log_dir = os.path.join(cwd, ".oma", "log")
if not os.path.isdir(log_dir):
    raise SystemExit(0)  # not an OMA project (or workspace not created yet)

resp = d.get("tool_response") or {}
if not isinstance(resp, dict):
    resp = {}

# Exit-code field name varies across harness versions; probe defensively.
exit_code = resp.get("exit_code", resp.get("exitCode"))
if exit_code is None:
    exit_code = 1 if resp.get("is_error") else 0

rec = {
    "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
    "agent": d.get("agent_type") or "main",
    "command": ((d.get("tool_input") or {}).get("command") or "")[:500],
    "exit_code": exit_code,
    "interrupted": bool(resp.get("interrupted", False)),
}

with open(os.path.join(log_dir, "commands.jsonl"), "a") as f:
    f.write(json.dumps(rec) + "\n")
PY
exit 0
