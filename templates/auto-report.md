# Unattended run {n} — {project name}

Started {timestamp} · {finished {timestamp} | halted at {phase}}
Policy: scope {cut|include} · questions {assume|halt} · contract changes
{halt|allow} · QA red {halt|accept} · security {halt on critical|halt on high}

## Verdict

{One paragraph. Either: reached 08-ship, here is what exists and what it does.
Or: halted at <phase> because <reason> — everything through <last approved gate>
is committed and tagged, nothing is lost, and here is the one thing needed to
continue.}

## Look at these three things first

Ranked by how expensive they are to fix later. Each of these is something the
run could not check for itself.

| # | What | Why it needs you | How to look |
|---|---|---|---|
| 1 | {e.g. the requirement list} | {nobody checked these are the right requirements} | `{command or file path}` |
| 2 | {e.g. the mockups} | {they render; whether they look right is taste} | `python3 -m http.server 4173 -d .oma/03-design/mockups` |
| 3 | {e.g. open security findings} | {accepted under policy, not fixed} | `.oma/06-devops/security-review.md` |

## Assumptions made on your behalf

Every decision taken without you, and how to reverse each one.

| Phase | Assumed | Because | Reverse with |
|---|---|---|---|
| {01-discovery} | {…} | {…} | `/oma:phase 01-discovery "…"` |
| {02-architecture} | {…} | {…} | `/oma:change "…"` |

## Gates auto-approved

| Phase | Checks | Verdict | Commit |
|---|---|---|---|
| {01-discovery} | {8/8} | {every REQ has acceptance criteria; 6 out of scope} | `{sha}` `oma/gate-01-discovery` |

{Any gate the user approved themselves before the run started is listed here as
**approved by you**, not by policy.}

## Known issues

Nothing here is hidden and nothing here is fixed.

| Severity | Issue | Where | Status |
|---|---|---|---|
| {high} | {…} | {file:line or REQ-###} | {wontfix — accepted under policy at the 05-qa gate} |

## What the run produced

| Phase | Artifacts | Gate |
|---|---|---|
| 01-discovery | {n} requirements, {n} out of scope | {auto-approved} |
| … | | |

Pipeline at ship: install {pass} · typecheck {pass} · lint {pass} ·
build {pass} · test {n passed / n failed} — verified from a clean clone.

## What to run next

```bash
{npm install && npm run dev}
```

1. `{command}` — {why}
2. `{command}` — {why}

OMA deployed nothing. The runbook is at `.oma/06-devops/deploy-runbook.md`;
running it is your credentials and your call.
