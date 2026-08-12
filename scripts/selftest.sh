#!/usr/bin/env bash
# OMA — hook self-test.
#
# Every hook in this plugin fails open by design: any internal error exits 0 and
# allows the action, so a hook bug can never block your work. The cost of that
# choice is that a broken hook is SILENT. This script is how you find out.
#
# It feeds each hook the JSON payload the harness would send and asserts the
# decision. It does not need Claude Code running, a project, or a network.
#
#   bash scripts/selftest.sh
#
# Exit 0 = every hook behaves. Exit 1 = at least one case failed; the failing
# case prints its expected and actual decision.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="$ROOT/hooks/scripts"
PASS=0; FAIL=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

command -v python3 >/dev/null 2>&1 || { echo "python3 not found — hooks are inert on this machine"; exit 1; }

ok()   { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n      expected: %s\n      actual:   %s\n' "$1" "$2" "$3"; }

# decision <raw-hook-output> -> allow | deny | ask | warn
decision() {
  python3 -c '
import json,sys
raw=sys.stdin.read().strip()
if not raw: print("allow"); raise SystemExit
try: d=json.loads(raw)
except Exception: print("allow"); raise SystemExit
h=d.get("hookSpecificOutput") or {}
if h.get("permissionDecision"): print(h["permissionDecision"]); raise SystemExit
if h.get("additionalContext"): print("context"); raise SystemExit
if d.get("systemMessage"): print("warn"); raise SystemExit
print("allow")'
}

# --- fixtures -----------------------------------------------------------------
mk_project() {                      # $1 = dir, $2 = extra state json (merged)
  local d="$1"; local extra="${2:-}"; [ -n "$extra" ] || extra='{}'
  mkdir -p "$d/.oma/log"
  python3 - "$d" "$extra" <<'PY'
import json,os,sys
d,extra=sys.argv[1],json.loads(sys.argv[2])
s={"version":1,"project":{"name":"T","slug":"t","created":"2026-01-01","one_liner":"x"},
   "phase":{"current":"04-build","status":"in_progress"},"gates":[],
   "contracts":{"api":{"path":".oma/02-architecture/api-contract.yaml","frozen":True,
                       "sha256":"deadbeef","version":"1.0"},
                "tokens":{"path":".oma/03-design/tokens.json","frozen":False,
                          "sha256":None,"version":"0"}},
   "open_questions":[],"handoff_seq":0}
s.update(extra)
os.makedirs(os.path.join(d,".oma","02-architecture"),exist_ok=True)
open(os.path.join(d,".oma","02-architecture","api-contract.yaml"),"w").write("openapi: 3.1.0\n")
json.dump(s,open(os.path.join(d,".oma","state.json"),"w"),indent=2)
PY
}
write_payload() { python3 -c '
import json,sys
print(json.dumps({"tool_name":sys.argv[1],"tool_input":json.loads(sys.argv[2]),"cwd":sys.argv[3]}))' "$@"; }

PROJ="$TMPROOT/proj";        mk_project "$PROJ"
AUDIT="$TMPROOT/audit";      mk_project "$AUDIT" '{"mode":"brownfield","brownfield":{"scope":"audit"}}'
EXTEND="$TMPROOT/extend";    mk_project "$EXTEND" '{"mode":"brownfield","brownfield":{"scope":"extend"}}'
BARE="$TMPROOT/bare";        mkdir -p "$BARE"

# --- contract-guard -----------------------------------------------------------
echo "contract-guard (PreToolUse: Write|Edit)"
t_cg() { # desc, path, cwd, expected
  local got; got=$(write_payload Write "{\"file_path\":\"$2\"}" "$3" | bash "$H/contract-guard.sh" | decision)
  [ "$got" = "$4" ] && ok "$1" || bad "$1" "$4" "$got"
}
t_cg "denies a write to the frozen api contract"  "$PROJ/.oma/02-architecture/api-contract.yaml" "$PROJ" deny
t_cg "allows the unfrozen tokens contract"        "$PROJ/.oma/03-design/tokens.json"             "$PROJ" allow
t_cg "allows ordinary source"                     "$PROJ/src/app/page.tsx"                        "$PROJ" allow
t_cg "inert outside an OMA project"               "$BARE/anything.yaml"                           "$BARE" allow
t_cg "denies via a relative path too"             ".oma/02-architecture/api-contract.yaml"        "$PROJ" deny

# --- deploy-guard -------------------------------------------------------------
echo "deploy-guard (PreToolUse: Bash)"
t_dg() { local got; got=$(write_payload Bash "{\"command\":\"$2\"}" "$3" | bash "$H/deploy-guard.sh" | decision)
  [ "$got" = "$4" ] && ok "$1" || bad "$1" "$4" "$got"; }
for c in "vercel deploy --prod" "fly deploy" "docker push ghcr.io/x/y" "npm publish" \
         "terraform apply" "kubectl apply -f k8s/" "npm run deploy" "gh release create v1"; do
  t_dg "denies: $c" "$c" "$PROJ" deny
done
t_dg "asks: git push"                 "git push origin main"    "$PROJ" ask
t_dg "asks: gh repo create"           "gh repo create x"        "$PROJ" ask
for c in "npm run build" "docker build -t app ." "terraform plan" "git commit -m x" "npm audit"; do
  t_dg "allows: $c" "$c" "$PROJ" allow
done
t_dg "inert outside an OMA project"   "vercel deploy --prod"    "$BARE" allow

# --- audit-guard --------------------------------------------------------------
if [ -f "$H/audit-guard.sh" ]; then
  echo "audit-guard (PreToolUse: Write|Edit, brownfield audit scope)"
  t_ag() { local got; got=$(write_payload Write "{\"file_path\":\"$2\"}" "$3" | bash "$H/audit-guard.sh" | decision)
    [ "$got" = "$4" ] && ok "$1" || bad "$1" "$4" "$got"; }
  t_ag "denies source writes in audit scope"      "$AUDIT/src/app/page.tsx"        "$AUDIT"  deny
  t_ag "denies config writes in audit scope"      "$AUDIT/package.json"           "$AUDIT"  deny
  t_ag "allows .oma/ writes in audit scope"       "$AUDIT/.oma/00-archaeology/map.md" "$AUDIT" allow
  t_ag "inert in extend scope"                    "$EXTEND/src/app/page.tsx"      "$EXTEND" allow
  t_ag "inert in greenfield"                      "$PROJ/src/app/page.tsx"        "$PROJ"   allow
fi

# --- command-log --------------------------------------------------------------
echo "command-log (PostToolUse: Bash)"
LOG="$PROJ/.oma/log/commands.jsonl"; : > "$LOG"
python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":"npm run test"},
 "tool_response":{"is_error":True},"cwd":sys.argv[1],"agent_type":"oma-qa"}))' "$PROJ" \
 | bash "$H/command-log.sh" >/dev/null
python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":"npm run build"},
 "tool_response":{"is_error":False},"cwd":sys.argv[1],"agent_type":"oma-backend"}))' "$PROJ" \
 | bash "$H/command-log.sh" >/dev/null
n=$(wc -l < "$LOG" | tr -d ' ')
[ "$n" = "2" ] && ok "appends one record per command" || bad "appends one record per command" "2 lines" "$n lines"
if python3 -c '
import json,sys
rs=[json.loads(l) for l in open(sys.argv[1])]
assert rs[0]["exit_code"]==1 and rs[1]["exit_code"]==0, rs
assert rs[0]["agent"]=="oma-qa", rs
assert rs[0]["command"]=="npm run test", rs' "$LOG" 2>/dev/null
then ok "records command, agent and exit code"; else bad "records command, agent and exit code" "exit 1 then 0" "see $LOG"; fi

# --- handoff-check ------------------------------------------------------------
echo "handoff-check (SubagentStop)"
HL="$PROJ/.oma/log/handoffs.jsonl"
t_hc() { local got; got=$(python3 -c '
import json,sys
print(json.dumps({"agent_type":sys.argv[1],"cwd":sys.argv[2]}))' "$2" "$PROJ" | bash "$H/handoff-check.sh" | decision)
  [ "$got" = "$3" ] && ok "$1" || bad "$1" "$3" "$got"; }
: > "$HL"
t_hc "warns when an oma agent left no handoff"     oma-backend warn
echo '{"seq":1,"from":"oma-backend","phase":"04-build","to":["oma-qa"],"summary":"x","produced":[],"consumed":[]}' > "$HL"
t_hc "silent when the last record is that agent's" oma-backend allow
t_hc "warns when the last record is someone else's" oma-frontend warn
t_hc "ignores non-oma agents"                       general-purpose allow

# --- session-start ------------------------------------------------------------
echo "session-start (SessionStart)"
got=$(python3 -c '
import json,sys; print(json.dumps({"cwd":sys.argv[1]}))' "$PROJ" | bash "$H/session-start.sh" | decision)
[ "$got" = "context" ] && ok "injects project context inside an OMA project" \
  || bad "injects project context inside an OMA project" context "$got"
got=$(python3 -c '
import json,sys; print(json.dumps({"cwd":sys.argv[1]}))' "$BARE" | bash "$H/session-start.sh" | decision)
[ "$got" = "allow" ] && ok "silent outside an OMA project" || bad "silent outside an OMA project" "no output" "$got"
if python3 -c '
import json,subprocess,sys
p=subprocess.run(["bash",sys.argv[1]],input=json.dumps({"cwd":sys.argv[2]}),
                 capture_output=True,text=True)
c=json.loads(p.stdout)["hookSpecificOutput"]["additionalContext"]
assert "04-build" in c and "api" in c, c' "$H/session-start.sh" "$PROJ" 2>/dev/null
then ok "summary names the phase and the frozen contracts"
else bad "summary names the phase and the frozen contracts" "phase + frozen list" "missing"; fi

# --- fail-open contract -------------------------------------------------------
echo "fail-open guarantee (a hook bug must never block work)"
for s in contract-guard deploy-guard command-log handoff-check session-start audit-guard; do
  [ -f "$H/$s.sh" ] || continue
  got=$(printf 'not json at all' | bash "$H/$s.sh" 2>/dev/null | decision); rc=$?
  [ "$got" = "allow" ] && ok "$s survives malformed input" || bad "$s survives malformed input" allow "$got"
done

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32m%d passed, 0 failed\033[0m\n' "$PASS"; exit 0
else
  printf '\033[31m%d passed, %d FAILED\033[0m\n' "$PASS" "$FAIL"; exit 1
fi
