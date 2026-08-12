<!-- Written by the orchestrator at 08-ship. Lives at .oma/08-ship/ship-report.md
     Every number here is read from state, tasks, reports or a command run at
     ship time. Nothing is estimated. This is the document that makes the
     project inheritable. -->

# Ship report — <project>

<one_liner>

Shipped <UTC date> · commit `<short sha>` · <n> phases · <n> agent dispatches

## Verdict

<One paragraph a stranger could read to know what this is, what state it's in,
and what it does not do. Include what was cut and why. If phases were skipped,
say which, here, first.>

## Requirements

| REQ | Priority | Status | Verified by |
|---|---|---|---|
| REQ-001 | must | shipped | `<test name>` / `<screen>` |
| REQ-00n | should | partial | <what's missing> |
| REQ-0nn | could | dropped | <gate note or task that dropped it> |

**<n> of <n> `must` requirements shipped.** Dropped and partial rows above are
the honest scope of what exists.

## Verification at ship time

Run on the tree as shipped, not copied from an earlier report:

| Check | Command | Exit | Result |
|---|---|---|---|
| install | `<cmd>` | 0 | |
| typecheck | `<cmd>` | 0 | |
| lint | `<cmd>` | 0 | |
| build | `<cmd>` | 0 | |
| unit tests | `<cmd>` | 0 | <n> passing |
| e2e | `<cmd>` | 0 | <n> passing |

**Untested, honestly:** <the `untested` rows from the QA coverage table,
repeated here rather than buried in a report nobody opens.>

## Known issues

Every accepted failure, with the reason recorded when it was accepted.

| id | What | Why it's still here | Accepted at |
|---|---|---|---|
| T-0nn | <issue> | <gate note> | <gate> |
| SEC-00n | <finding, severity> | <accepted reason> | <gate> |

## Security posture

Reviewed <date>: <n> critical, <n> high, <n> medium, <n> low.
<n> fixed, <n> accepted (above). Dependency audit: <result>.
Not covered by the review: <scope limits>.

## Contracts

| Contract | Version | Path |
|---|---|---|
| stack | 1.0 | `.oma/02-architecture/stack.md` |
| data_model | | |
| api | | |
| tokens | | |
| motion | | |

These are what the code was built against. Changing one after ship goes through
`/oma:change` if you want the impact analysis.

## Decisions

| id | Decision | Why | ADR |
|---|---|---|---|
| D-001 | | | ADR-001 |

## Open questions

<Still-unanswered questions, including non-blocking ones. These are the things
the project knows it doesn't know.>

## Deploy checklist

OMA has not deployed anything and will not. Full detail in
`.oma/06-devops/deploy-runbook.md`.

- [ ] Environment variables set from `.oma/06-devops/env.template`
- [ ] Database provisioned, `DATABASE_URL` set
- [ ] Migrations run as a release step
- [ ] Health endpoint returns 200
- [ ] Rollback command known and to hand
- [ ] `[[TODO]]`s in the growth copy filled before the landing page goes live

## Growth assets

| File | What it is | Outstanding |
|---|---|---|
| `.oma/07-growth/positioning.md` | | |
| `.oma/07-growth/landing-copy.md` | | <n> `[[TODO]]`s |
| `.oma/07-growth/launch-plan.md` | | |
| `.oma/07-growth/social-calendar.md` | <n> drafted posts | <assets to produce> |

## What to do next

1. <highest-value action, usually: deploy per the runbook>
2. <fill the copy TODOs — the landing page is not usable until then>
3. <the deferred requirements worth doing first, named>
4. <the medium security findings>

## How to pick this up later

Everything is on disk. `.oma/` holds the reasoning, not just the output:
requirements in `01-discovery/`, decisions in `02-architecture/adr/`, the design
system and mockups in `03-design/`, verification evidence in `05-qa/reports/`,
and the full inter-agent history in `log/handoffs.jsonl`.

`/oma:status` reconstructs the whole picture in a fresh session.
