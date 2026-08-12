---
description: Re-run a specific OMA phase with corrections — revises existing artifacts, invalidates downstream gates that depended on them, and handles unfreezing/refreezing contracts. Use when the user wants to redo or fix a completed phase (e.g. "redo the design with a darker feel").
argument-hint: <discovery|architecture|design> "<corrections>"
---

# /oma:phase — targeted re-run

You are the OMA orchestrator re-running one phase deliberately. `$ARGUMENTS`
names the phase and (ideally) the corrections.

Read `.oma/state.json`. If missing → `/oma:init` first, stop.

## 1. Resolve the target

Map the argument to a phase id (`discovery` → `01-discovery`, etc.). If it
names a phase with no playbook in `${CLAUDE_PLUGIN_ROOT}/phases/` (04+), say
this version implements through Design, stop. If no corrections were given,
ask one question: "What should come out differently this time?" — a re-run
without direction reproduces the same output.

## 2. Impact warning (before touching anything)

Determine the blast radius — every phase *after* the target whose gate is
currently `approved`:

- Re-running **discovery** invalidates architecture and design.
- Re-running **architecture** invalidates design.
- Re-running **design** invalidates nothing upstream, but if contracts are
  frozen it will unfreeze `tokens` and `motion` (and `api`/`data_model` only
  if the corrections demand contract changes — say which).

State the blast radius in two lines and get an explicit yes via
AskUserQuestion before proceeding. This is the one destructive-ish command in
the spec pipeline.

## 3. Prepare state

1. For each downstream phase with an `approved` gate: append
   `{ "phase": ..., "status": "invalidated", "at": now, "notes": "upstream re-run of <target>" }`
   to `gates`. (History is append-only — never edit old gate entries.)
2. If any affected contract is `frozen: true`: set `frozen: false` and note
   the prior version — on the next design-gate approval, the version bumps
   (1.0 → 1.1) instead of resetting.
3. Set `phase.current = <target>`, `phase.status = "in_progress"`,
   increment `phase.iteration`.

## 4. Dispatch

Follow `${CLAUDE_PLUGIN_ROOT}/phases/<target>.md` exactly as `/oma:run` would,
with one addition: the dispatch prompt's re-run slot carries the user's
corrections verbatim, and the agent is reminded that existing artifacts are
the base to revise, with IDs (REQ/ADR/token names) permanent.

Verification and gate presentation per the playbook. Stop at
`awaiting_gate` as always.

## 5. After this gate

Remind the user: downstream phases whose gates were invalidated will re-run
on subsequent `/oma:run` calls — but their agents receive the *previous*
artifacts plus a diff-focused instruction, so unchanged work is preserved,
not regenerated from scratch.
