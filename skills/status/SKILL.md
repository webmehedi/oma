---
description: Show where the OMA project stands — phase, gates, contracts, blocking questions, and the exact next command. Read-only. Use when the user asks where the project is, what's next, or resumes after time away.
argument-hint: (no arguments)
---

# /oma:status — the dashboard

Read-only. You change nothing — not state.json, not artifacts, nothing.

Read `.oma/state.json`. If missing: this project isn't OMA-managed; explain
`/oma:init "<idea>"` in two lines and stop.

Also read (cheap, skip gracefully if absent):
- the last 3 records of `.oma/log/handoffs.jsonl` — recent activity
- the artifact directory of the current phase — what exists on disk

Present, compactly:

```
# <project name> — <one_liner>

Phase   <current> (<status>, iteration <n>)
Mode    <omit entirely for greenfield | "brownfield · <scope>" + the baseline verdict>
Stack   <profile><+overrides if any>

Gates   01-discovery    ✔ approved <date>   <notes if any>
        02-architecture ✔ approved <date>
        03-design       ◌ awaiting your review
        04-build …      · not reached

Contracts   <"none frozen yet" | list: name vN ❄ frozen>

Recent      <last 1-3 handoffs: "from → summary" one line each>
```

Then, only if present:
- **Brownfield baseline** — if `state.brownfield.baseline` shows any `fail`, say
  so here and say it was failing *before OMA touched anything*. A user returning
  after a week must not mistake a pre-existing failure for something OMA broke.
- **Inferred contracts** — any contract whose artifact still carries
  `inferred: true`: list them as "reconstructed, not yet confirmed by you".
- **Security** — once `state.security.last_review` exists: severity counts and
  `open_findings`. A non-zero critical/high count is the most important line on
  this dashboard; put it above the assumptions.
- **Blocking questions for you** — each with its Q-id, verbatim. These halt
  the pipeline until answered.
- **Assumptions pending review** — from handoffs since the last approved gate.
- **Contract change requests** — any handoff `contract_changes` not yet resolved.

End with the single exact next action, chosen honestly from the state:

- blocking questions exist → "Answer the questions above, then `/oma:run`."
- `awaiting_gate` → "Review the artifacts above, then `/oma:gate approve` or `/oma:gate reject \"why\"`." (For the design gate, include the mockup serve command: `python3 -m http.server 4173 -d .oma/03-design/mockups`.)
- `blocked` → what's blocked and the most direct way to unblock.
- `08-ship` approved → the project is complete: point at
  `.oma/08-ship/ship-report.md` and the first item in its "what to do next".
- otherwise → "`/oma:run` to <start|continue> <phase>."
