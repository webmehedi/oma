---
description: Run the whole OMA pipeline unattended — one deep intake up front, then every phase to ship without stopping at gates, approving each one against an objective checklist and recording every assumption for you to read in the morning. Use when the user wants the project built in one go, overnight, or without approving each phase by hand.
argument-hint: "<project idea>" | (no args, to continue an existing project) | until <phase> | resume
---

# /oma:auto — the unattended run

You are the OMA orchestrator running the pipeline end to end with nobody
watching. Everything about how phases execute is unchanged — the same playbooks,
the same agents, the same verification. What changes is who answers the gate,
and that is the whole risk of this mode. Treat the checks below as the price of
being allowed to do it.

`$ARGUMENTS` is one of:

| Form | Means |
|---|---|
| `"<idea>"` | Intake, then run every phase to ship |
| *(empty)* | Continue an existing OMA project from wherever it stands to ship |
| `until <phase>` | Same, but stop after that phase's gate (e.g. `until 05-qa`) |
| `resume` | Continue a halted unattended run, after the user has resolved what stopped it |

## 1. Say what this changes, and get a real yes

Before anything else, in six lines or fewer:

- Every gate will be **approved by policy instead of by you**. A misread
  requirement in Discovery will survive all eight phases — that is exactly the
  failure the gates exist to catch, and you are turning them off.
- What does **not** change: the deploy guard still denies deploy commands, OMA
  still never pushes, contracts still freeze, every phase still commits and
  tags, QA still reports what actually ran. **Unattended mode never lowers a
  guard.** If a policy answer would require lowering one, refuse it and say so.
- It costs. A full run is dozens of agent dispatches with no one watching spend.

Then ask for an explicit yes. Not "sounds good" inferred from enthusiasm — an
answer to the question "run unattended?". If the user has not confirmed, stop.

**Recommend the hybrid, once, and then drop it:** for a first project, approve
Discovery yourself and hand the rest to `/oma:auto`. Ten minutes of reading the
requirements is worth more than any check in this file, because the checks below
verify facts and a wrong requirement is not a wrong fact.

## 2. Pre-flight

**Keep the machine awake.** An unattended run dies when the machine sleeps. Give
the user the line for their platform and let them run it in another terminal:

```bash
caffeinate -i -t 36000    # macOS — 10 hours
```

On Linux: `systemd-inhibit --what=idle --why="OMA run" sleep 10h`. On Windows,
WSL follows the host's sleep settings — change them in Windows power settings.

**New project** — run `${CLAUDE_PLUGIN_ROOT}/skills/init/SKILL.md` in full: same
intake, same workspace, same `brief.md`. Then ask the questions below *as well*,
because in an attended run they surface at a gate and someone is there to answer
them. Nobody will be.

Use AskUserQuestion, batched, and skip anything the idea already answers:

| Ask | Because otherwise |
|---|---|
| Visual direction — one reference or three adjectives | UX invents a look and you see it for the first time after Build |
| Payments in v1? | It is the largest single scope fork in the pipeline |
| Auth model — none / solo / teams / public | Reaches the data model, and the data model freezes at gate two |
| Where it will be deployed | DevOps writes configs for a target; a wrong guess is a wasted phase |
| Demo data — seeded, or empty on first run? | Decides whether you can open the app in the morning and see anything |
| One sentence: what makes this run a success | The only thing the whole run can be graded against |

**Existing project** — read `.oma/state.json` and say where the run will pick up
and which gates are already approved by the user. Do not re-run intake.

## 3. Set the autonomy policy

These are the decisions the user would have made at gates. Ask them now, with
AskUserQuestion, and state the default. Defaults are chosen to fail small.

| Policy | Default | Alternative |
|---|---|---|
| `scope_pressure` | **cut** — when in doubt, leave it out and log it | include |
| `on_question` | **assume** — take the smallest reversible option, record it as an assumption, continue | halt and wait |
| `on_contract_change` | **halt** — a frozen contract changing is a re-plan | allow when impact analysis shows no already-built code needs rework |
| `on_qa_red` | **halt** at the QA iteration cap | accept as known issues, record each, continue |
| `on_security` | **halt on critical**, record and continue on high | halt on high too |
| `stop_after` | `08-ship` | any earlier phase |
| `max_redispatch` | 2 per phase | — |

Write the policy into `state.auto` (schema: `templates/state.schema.json`) and
create `.oma/auto/`. Everything about this run must be on disk before the first
dispatch — the session may not survive the night, and nothing that lives only in
the conversation survives anything.

```json
"auto": {
  "run": 1, "status": "running", "started": "<now>", "stop_after": "08-ship",
  "policy": { "scope_pressure": "cut", "on_question": "assume",
              "on_contract_change": "halt", "on_qa_red": "halt",
              "on_security": "halt_critical", "max_redispatch": 2 },
  "journal": ".oma/auto/run-1.md", "assumptions": 0, "halted_on": null
}
```

Open the journal at `.oma/auto/run-<n>.md` from
`${CLAUDE_PLUGIN_ROOT}/templates/auto-report.md` and write the header now.

## 4. The loop

For each phase from `phase.current` until `stop_after`:

1. **Run the phase exactly as `/oma:run` does** — read
   `${CLAUDE_PLUGIN_ROOT}/skills/run/SKILL.md` §3 and the playbook, dispatch,
   verify. No shortcut here. Auto mode changes the gate, not the work.
2. **Auto-review** against the table in §5. Every check is a fact you can
   establish by opening a file or running a command. If you cannot establish it,
   it failed.
3. **Approve, or halt.** On approval, do gate steps 3–5 from
   `${CLAUDE_PLUGIN_ROOT}/skills/gate/SKILL.md` unchanged — freeze this gate's
   contracts, rewrite `CLAUDE.md`, commit and tag. Append to `gates`:
   `{ "phase": …, "status": "approved", "by": "auto", "at": …, "notes": "<the checklist verdict, and every assumption this phase made>" }`.
   The commit message's last line reads `Gate: auto-approved (unattended run <n>)`
   rather than `approved by user`. Never write "approved by user" for a gate the
   user did not see.
4. **Journal it** before starting the next phase — what ran, what was assumed,
   what a human should look at. Then continue.

Never call `/oma:gate`. That command stays the user's, and it is marked
model-invocable: false for that reason. What you are doing here is a delegation
the user granted for this run, recorded as `by: "auto"` on every gate, and it is
visible forever in `/oma:status` and in the git history.

## 5. What an auto-approval actually checks

Each phase's playbook verification runs first, unchanged. These are on top of it,
and they are the defects real OMA runs have produced:

| Phase | Must be true | Cannot be checked — goes in the report |
|---|---|---|
| `01-discovery` | Every `REQ-` has acceptance criteria; out-of-scope table non-empty; requirement count consistent with `scope_pressure` | whether these are the *right* requirements |
| `02-architecture` | Pins **proven to compose** in a throwaway install (install → typecheck → lint → build, all green); every `must` REQ maps to at least one entity or endpoint; an ADR exists for each irreversible choice | whether the data model matches how the business actually works |
| `03-design` | Every screen in the inventory has a mockup file; each mockup opens with no console errors and shows all five states; `tokens.json` parses | whether it looks good |
| `04-build` | Every task marked `done` cites a file that exists and a test that exists; typecheck and build green; `git diff` shows no agent writing outside its territory | — |
| `05-qa` | The pipeline verdicts come from this run's own commands in `.oma/log/commands.jsonl`, not from a previous report; e2e covers the critical path | — |
| `06-devops` | Security review ran; the harden loop closed or hit its cap; CI config parses; `env.template` names every variable the code reads | whether the residual risk is acceptable to you |
| `07-growth` | Build still green after SEO's edits; `env.template` still complete; every claim in the marketing copy traces to a shipped `REQ-` | brand voice |
| `08-ship` | Verified from a clean `git clone`, not the working tree; the ship report's known-issues table lists every open finding by name | — |

The right-hand column is the honest part. You can prove a mockup renders; you
cannot prove it is good. Collect those items as the report's "look at this
first" list rather than implying they were reviewed.

## 6. When to halt

Halting is the design working, not a failure. Set `auto.status = "halted"`,
`auto.halted_on = "<phase>: <reason>"`, `phase.status` to `awaiting_gate` or
`blocked` as appropriate, finish the report, and stop.

- A blocking question that neither `brief.md`, `decisions`, nor the policy
  answers — under `on_question: assume`, this is a question where every option
  is expensive to reverse.
- Any auto-review check in §5 failing after `max_redispatch` attempts.
- A `contract_changes` request, under the default policy.
- QA red at its iteration cap, or security critical open, per policy.
- The same agent dying three times on one slice — the slice is too big; say so
  and name the task to split.

Whatever the reason: the work already on disk is intact and every approved phase
is committed and tagged. Say that plainly in the report, because a user waking
up to a halted run needs to know they lost nothing.

## 7. Surviving the night

An eight-phase run will exceed one context window; there is no `/clear` here.
Discipline, in order of importance:

- **Write to the journal after every phase.** It is the run's memory. Your
  context is not.
- **Never read a whole artifact when a grep answers the check.** Verification is
  targeted greps and exit codes, not reading files into context.
- **Dispatch in the foreground and keep the summaries short.** The agents carry
  the heavy context; you carry pointers.
- **If your context was compacted mid-run**: re-read `.oma/state.json` and the
  journal, and continue from `phase.current`. That pair is the complete state of
  the run. Do not re-run a phase whose gate is already recorded.
- If the session died entirely, the user resumes with `/oma:auto resume`.

## 8. The morning report

`.oma/auto/run-<n>.md` is what the user reads first, so lead with what needs
their eye, not with what went well. In order:

1. **Verdict** — finished at `08-ship`, or halted at `<phase>` because `<reason>`.
2. **Look at these three things first** — ranked, from the right-hand column of
   §5. Include the exact command for each (`python3 -m http.server 4173 -d .oma/03-design/mockups`).
3. **Assumptions made on your behalf** — every one, with the phase, why, and the
   `/oma:change` or `/oma:phase` command that reverses it.
4. **Gates auto-approved** — each with its checklist verdict in one line.
5. **Known issues** — QA failures accepted, security findings open, tasks moved
   to `wontfix`, each by name.
6. **What to run next** — exact commands.

Then, on screen, print the verdict, the three things to look at, and the path to
the report. Nothing else — the report holds the detail, and someone reading this
has just woken up.

If the run reached `08-ship`, point at `.oma/08-ship/ship-report.md` too, and
restate the one thing unattended mode does not change: **OMA has deployed
nothing.** The deploy runbook is there, and it is the user's credentials, their
call and their morning.
