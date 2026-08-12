# QA report — run {{n}}

- **Date:** {{utc timestamp}}
- **Iteration:** {{state.qa.loop_iteration}}
- **Commit state:** {{git rev-parse --short HEAD, or "no git"}}

> Every result row cites the actual command run. Claims without a corresponding
> entry in `.oma/log/commands.jsonl` are fabrications — the log is the authority.

## Pipeline

| Check | Command | Exit | Verdict |
|---|---|---|---|
| install | `{{cmd}}` | {{code}} | pass / fail |
| typecheck | `{{cmd}}` | {{code}} | pass / fail |
| lint | `{{cmd}}` | {{code}} | pass / warn / fail |
| build | `{{cmd}}` | {{code}} | pass / fail |
| unit | `{{cmd}}` | {{code}} | pass / fail — {{n passed}}/{{n total}} |
| e2e | `{{cmd}}` | {{code}} | pass / fail — {{n passed}}/{{n total}} |

## Failures

<!-- One block per distinct failure. Terse, factual, reproducible. -->

### F-{{n}}: {{one-line symptom}}
- **Where:** {{file:line / test name / endpoint}}
- **Repro:** `{{exact command}}`
- **Output:**
  ```
  {{the actual relevant lines, trimmed}}
  ```
- **Probable owner:** oma-{{frontend|backend}} — {{one clause why}}
- **Filed as:** T-{{id}}

## Contract conformance spot-check

<!-- 3-5 endpoints probed against api-contract.yaml: status codes, envelope
     shape, error codes. And 2-3 screens against their mockups: states present,
     tokens used, motion behaves. -->

## Requirements coverage

| REQ | Acceptance criteria | Verified by | Status |
|---|---|---|---|
| REQ-{{id}} | {{criterion}} | {{test/command/manual-load}} | ✔ / ✘ / untested |

## Verdict

{{green: "All checks pass — recommending gate." / red: "N failures filed as
tasks T-x..T-y; owners: ... Loop iteration M of 3."}}
