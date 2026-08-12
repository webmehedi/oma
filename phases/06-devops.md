# Phase playbook: 06-devops

Read by the orchestrator. Not read by agents.

## Preconditions

- Gate `05-qa` is `approved`.
- No blocking `open_questions` for `user`.

## Why security runs first

Security review comes before the deploy configs, not after, for two reasons:
findings are cheapest to fix while nothing is deployed, and several findings
(headers, secret handling, non-root containers) are *inputs* to what DevOps
writes. Reviewing after the runbook exists means writing the runbook twice.

The design doc places Security in phases 2 and 5; in practice it lands here,
where there is a running application to probe and a green build to keep green.

## The dispatch preamble (prepend to every agent prompt in this phase)

```
You run in the project root (the directory containing .oma/). All `.oma/...`
paths in your role file are relative to it, and ${CLAUDE_PLUGIN_ROOT} is the
installed OMA plugin directory.
```

## Stage A — security review

Dispatch **oma-security**, foreground:

```
Round: {state.security.review_iteration + 1} of 2.
Review template: ${CLAUDE_PLUGIN_ROOT}/templates/security-review.md
Write your review to .oma/06-devops/security-review.md.
You may write .oma/04-build/tasks.json directly — you run alone this stage.
{round ≥ 2: "Harden tasks T-x..T-y were filed last round — verify each finding
 is actually closed, and check nothing regressed around the fixes."}
Probe localhost only. Next handoff seq: {seq}.
```

**Verification — do not trust the summary:**

- `.oma/06-devops/security-review.md` exists, has severity-labelled findings
  *and* a non-empty "checked and clean" list.
- Grep `.oma/log/commands.jsonl` for the audit command (`npm audit` or the
  stack's equivalent). No log entry means it wasn't run — re-dispatch.
- The cross-user authorization probe actually happened: there should be logged
  requests against localhost in the command log. This is the single check most
  worth enforcing; it's the finding class that matters and the easiest to skip.
- Every `critical`/`high` finding has a matching task in `tasks.json` with
  evidence and a command-shaped acceptance.

Update `state.security`: `last_review`, severity counts, `open_findings`,
`audit`, `review_iteration`.

## Stage B — harden (only if critical/high findings exist)

Bounded at **2 rounds**, same logic as the QA loop and for the same reason.

1. Group open `harden` tasks by owner. Dispatch **oma-backend** and/or
   **oma-frontend** in the same message if both have work, `stage: harden`,
   **≤2 tasks each**, with the review path and the specific finding ids.
   Findings owned by `oma-devops` (headers, secret handling, CI) are not
   dispatched here — they carry into Stage C as inputs.
2. Reconcile handoffs into tasks.json.
3. Return to Stage A for the verification round.
4. If round 2 ends with `critical` or `high` still open → set phase `blocked`.
   Report each remaining finding with its evidence, what was attempted, and the
   options: fix manually, accept explicitly at the gate (which records them as
   `wontfix` with the gate notes as the reason), or re-run.

**Never** let a critical finding pass silently into the gate summary. If the
user approves over it, that's their decision, made in writing.

## Stage C — DevOps

Dispatch **oma-devops**, foreground:

```
Runbook template: ${CLAUDE_PLUGIN_ROOT}/templates/deploy-runbook.md
Security findings routed to you: {SEC-### list with severities, or "none"}.
Target platform: {state.stack.overrides.platform, or "recommend one and say why"}.
Run every CI step locally before you hand off; report real exit codes.
Next handoff seq: {seq}.
```

**Verification — run these yourself:**

1. The CI workflow parses as YAML, and every `npm run <script>` it references
   exists in `package.json`. A workflow calling a script that doesn't exist is
   the most common defect in this phase.
2. Run the CI command sequence locally yourself. Not the agent's transcript —
   your own run, your own exit codes.
3. Env completeness: `grep -rho 'process\.env\.[A-Z_]*' src app 2>/dev/null | sort -u`
   and confirm every variable appears in `.oma/06-devops/env.template`. Any gap
   is a first-deploy crash; re-dispatch scoped to it.
4. No secrets committed: scan the working tree and the new files for anything
   key-shaped. `.env*` must be git-ignored and absent from the index.
5. `.dockerignore` excludes `node_modules`, `.git`, `.env*`, `.oma/`.
6. The runbook contains all six required sections (prerequisites, first deploy,
   migrations, verification, rollback, troubleshooting) and its commands are
   concrete — no `<your-app>` left unexplained.
7. If Docker is present, `docker build` succeeded. If absent, the handoff says
   so in `assumptions` rather than claiming a build that never happened.

Reconcile the handoff; promote questions; bump `handoff_seq`.

## Gate presentation

Set `awaiting_gate`. Show:

1. **Security posture first** — counts by severity, every `critical`/`high`
   listed with its status (fixed / still open), and the "checked and clean"
   summary so the user sees the coverage, not only the failures.
2. Any findings the user is being asked to accept, named individually.
3. What ships: CI workflow, container, env template, runbook — with **your own**
   local CI exit codes, not the agent's claims.
4. The deploy story in three lines: platform, how migrations run, how to roll back.
5. Anything unverified (Docker absent, rollback untested) stated plainly.
6. A reminder that OMA does not deploy: the runbook is the user's to run, and
   the plugin's hook blocks deploy commands on purpose.
7. `/oma:gate approve` / `/oma:gate reject "why"`.
