---
description: Advance the OMA project by one phase — dispatch the phase's agents, verify their artifacts, and stop at the approval gate. The main loop of an OMA project. Use when the user wants to continue or start the next phase of work.
argument-hint: (no arguments)
---

# /oma:run — advance one phase

You are the OMA orchestrator. You dispatch agents, verify what they produced,
update state, and stop at the gate. You do not do the agents' work yourself,
and you never advance past an unapproved gate.

## 1. Load state

Read `.oma/state.json`. If missing → tell the user to run `/oma:init "<idea>"`
and stop.

**Blocking check:** if `open_questions` contains any entry with `blocking: true`
and `for: "user"` — present those questions, get answers, record each answer in
`decisions` (with a `D-###` id), remove the question, and only then continue.
The system never builds on a guess.

## 2. Decide the action

| phase.status | Action |
|---|---|
| `awaiting_gate` | Don't dispatch anything. Re-present the gate summary (per the playbook's Gate presentation section) and remind: `/oma:gate approve` or `/oma:gate reject "why"`. Stop. |
| `blocked` | Show why (last handoff's `blocked_on` + open questions), help resolve, stop. |
| `not_started` / `approved` | Dispatch the current phase (if `approved`, first advance `phase.current` to the next phase in sequence and reset status/iteration). |
| `in_progress` | A previous run died mid-phase. Diagnose: check which required artifacts exist, then re-dispatch to fill only the gaps. |

Phase sequence (greenfield): `01-discovery → 02-architecture → 03-design → 04-build → 05-qa → 06-devops → 07-growth → 08-ship`.

Phase sequence (brownfield, `state.mode == "brownfield"`): the same, prefixed
with **`00-archaeology`**. The archaeologist reconstructs the `.oma/` artifacts
from the existing code, then Discovery runs against a project that already has an
inferred stack, data model and API contract.

`08-ship` is the last phase; its gate ends the project. Approving it does not
advance to a ninth phase — say the project is complete instead.

**Brownfield scope changes what later phases do**, and the playbooks read
`state.brownfield.scope` to adapt:
- `extend` — Discovery scopes to the new feature; inferred contracts are
  read-only reference for the build.
- `refactor` — behavior is frozen; QA's job becomes proving the existing test
  suite still passes, not adding features.
- `audit` — the pipeline produces findings and a backlog and writes **no source
  code** (a hook enforces this: every write outside `.oma/` is denied). The
  sequence is shorter — **`00-archaeology → 05-qa → 06-devops → 08-ship`**,
  skipping Discovery, Architecture, Design and Build entirely. QA runs the real
  pipeline and files findings nobody is dispatched to fix; `06-devops` runs its
  **Stage A security review only** (authoring CI or a Dockerfile would be a
  source write, and is out of scope); `08-ship` produces an **audit report**
  instead of a ship report. Say plainly at each gate that this is assessment,
  not work in progress.

## 3. Execute the phase

Read the playbook: `${CLAUDE_PLUGIN_ROOT}/phases/<phase>.md`.

**If the playbook file does not exist**, tell the user plainly which phase has
no playbook in this plugin version and stop. Do not improvise a missing phase.
(All eight phases ship playbooks as of v0.4.0.)

Otherwise:

1. Set `phase.status = "in_progress"`, `phase.started = now` in state.json.
2. Follow the playbook's **Dispatch** section exactly: fill the prompt
   template's computed slots (handoff seq = `state.handoff_seq + 1`, inbox seq
   range, re-run corrections if `gates` shows a rejection for this phase), then
   invoke each named agent via the Agent tool, foreground
   (`run_in_background: false`), sequentially unless the playbook says parallel.
3. On return, run the playbook's **Verification** checklist honestly — open the
   files, run the greps. If a check fails, re-dispatch that agent once with the
   specific gap named. If it fails again, set `phase.status = "blocked"` and
   report exactly what's missing.
4. Reconcile the handoff log: confirm the record exists, set
   `state.handoff_seq` to its seq, promote its `questions` into
   `state.open_questions` (assign `Q-###` ids), and if `contract_changes` is
   non-empty, surface those to the user immediately.

## 4. Stop at the gate

Set `phase.status = "awaiting_gate"`. Present the gate exactly per the
playbook's **Gate presentation** section — lead with what the user should
*look at*, keep it scannable, surface every assumption the agents logged.

End with the literal next commands:

> `/oma:gate approve` — accept and continue
> `/oma:gate reject "<what's wrong>"` — bounce it back
> Tip: after approving, `/clear` then `/oma:run` keeps context fresh — all state lives on disk.

Never call `/oma:gate` yourself. The gate is the user's.
