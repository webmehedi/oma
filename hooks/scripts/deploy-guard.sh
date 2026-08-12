#!/usr/bin/env bash
# OMA — PreToolUse guard on Bash.
# OMA writes deploy configs and runbooks; it never deploys, publishes, or posts.
# Production-affecting commands are DENIED outright. `git push` is ASKED, because
# pushing source is a reasonable thing for the user to want and an unreasonable
# thing for an agent to decide alone.
# Only active inside an OMA project (.oma/state.json present).
# Fails open: any internal error exits 0 (allow) so a hook bug never blocks work.

command -v python3 >/dev/null 2>&1 || exit 0
TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT
cat > "$TMP"

python3 - "$TMP" <<'PY' 2>/dev/null || exit 0
import json, os, re, sys

try:
    data = json.load(open(sys.argv[1]))
except Exception:
    raise SystemExit(0)

cmd = (data.get("tool_input") or {}).get("command") or ""
cwd = data.get("cwd") or os.getcwd()
if not cmd or not os.path.exists(os.path.join(cwd, ".oma", "state.json")):
    raise SystemExit(0)

# Deployment and publication. Each pattern must match a command that actually
# ships something to a remote environment — never a local build or a dry run.
DENY = [
    (r"\bvercel\b(?!.*\b(dev|env|link|logs|pull)\b).*\b(deploy|--prod)\b|\bvercel\b\s*$", "Vercel deploy"),
    (r"\b(fly|flyctl)\b.*\bdeploy\b",                      "Fly.io deploy"),
    (r"\brailway\b.*\b(up|deploy)\b",                      "Railway deploy"),
    (r"\brender\b.*\bdeploy\b",                            "Render deploy"),
    (r"\bnetlify\b.*\bdeploy\b",                           "Netlify deploy"),
    (r"\bwrangler\b.*\b(deploy|publish)\b",                "Cloudflare deploy"),
    (r"\b(sst|serverless|sls)\b.*\bdeploy\b",              "Serverless deploy"),
    (r"\beb\b\s+deploy\b",                                 "Elastic Beanstalk deploy"),
    (r"\bheroku\b.*\b(create|releases:|ps:scale)\b",       "Heroku release"),
    (r"\bgcloud\b.*\b(app\s+deploy|run\s+deploy)\b",       "Google Cloud deploy"),
    (r"\baws\b.*\b(cloudformation\s+deploy|lambda\s+update-function-code|s3\s+sync)\b", "AWS deploy"),
    (r"\bkubectl\b\s+(apply|rollout|delete)\b",            "Kubernetes apply"),
    (r"\bhelm\b\s+(install|upgrade)\b",                    "Helm release"),
    (r"\bterraform\b\s+apply\b",                           "Terraform apply"),
    (r"\bansible-playbook\b",                              "Ansible run"),
    (r"\bdocker\b.*\bpush\b",                              "Docker registry push"),
    (r"\bnpm\b\s+publish\b|\b(pnpm|yarn)\b\s+publish\b",   "npm publish"),
    (r"\b(twine\s+upload|cargo\s+publish|gem\s+push)\b",   "package publish"),
    (r"\bgh\b\s+release\s+create\b",                       "GitHub release"),
    (r"\bnpm\b\s+run\s+deploy\b",                          "a deploy script"),
]

for pattern, label in DENY:
    if re.search(pattern, cmd):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    f"OMA never deploys or publishes — this looks like {label}. "
                    "Deployment uses the user's credentials, costs the user money, "
                    "and is the user's decision. Write the exact command into "
                    ".oma/06-devops/deploy-runbook.md and tell the user to run it "
                    "in their own terminal. If you are verifying a config, use a "
                    "local build or a documented dry-run flag."
                ),
            }
        }))
        raise SystemExit(0)

# Publishing the user's work: legitimate for the user, never an agent's call alone.
if re.search(r"\bgit\b[^|;&]*\bpush\b|\bgh\b\s+repo\s+create\b", cmd):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": (
                "OMA agents commit per phase but never push or create remote "
                "repositories — that publishes the user's work. Confirm only if "
                "the user explicitly asked for this."
            ),
        }
    }))
    raise SystemExit(0)

raise SystemExit(0)
PY
exit 0
