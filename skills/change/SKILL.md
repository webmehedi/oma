---
description: Request a change to a frozen OMA contract (API, data model, design tokens, motion spec) — produces an impact analysis, gets the user's explicit decision, applies the change through the owning agent, bumps the contract version, and files rework tasks. Use when a frozen contract needs changing, or when an agent's handoff carries an unresolved contract_changes request.
argument-hint: "<what needs to change and why>" | review
---

# /oma:change — the only door through a frozen contract

You are the OMA orchestrator processing a contract change. Frozen contracts
are what let agents build in parallel without drifting; changing one is
legitimate but never casual. This skill exists so the change is explicit,
impact-priced, and user-approved — the alternative is silent drift, the worst
failure mode in the system.

Read `.oma/state.json`. No frozen contracts → nothing to change formally;
point at `/oma:phase` for pre-freeze revisions, stop.

## 1. Collect the request(s)

- `$ARGUMENTS` is a description → that's the request.
- `$ARGUMENTS` is `review` (or empty) → scan `.oma/log/handoffs.jsonl` for
  `contract_changes` entries not yet resolved in `state.decisions`; present
  them; let the user pick which to process. None pending → say so, stop.

Identify which contract(s) each request touches: `stack`, `data_model`, `api`,
`tokens`, `motion`.

**`stack` changes deserve extra care.** A version or library change invalidates
the Architect's compatibility proof. Any approved `stack` change requires the
proof to be re-run (throwaway install → install/typecheck/lint/build green)
before re-freezing — put that in the owning agent's prompt at step 4.2.

## 2. Impact analysis (before asking for a decision)

Read the affected contract file(s) and produce, concretely:

- **The diff in prose**: what changes, in the contract's own vocabulary
  (endpoints/schemas for api, entities/fields for data_model, token names for
  tokens/motion).
- **Blast radius**: grep the repo for consumers — which `src/` files reference
  the affected endpoints/schemas/tokens; which tasks in
  `.oma/04-build/tasks.json` (done AND todo) touched them; which screens'
  mockups display the affected data.
- **Rework estimate**: which agents need re-dispatching, on roughly how many
  tasks.
- **The cost of NOT changing**: what stays broken or awkward — the user is
  choosing between two prices, show both.

## 3. The decision

Present the analysis compactly, then AskUserQuestion: approve / reject / defer
(defer = record as an open question, non-blocking, revisit at the next gate).
Rejection and deferral both get recorded in `state.decisions` with a `D-###`
id so the same request doesn't resurface as new.

## 4. On approval — apply, re-freeze, rework

1. Set the affected contract's `frozen: false` in state.json.
2. Dispatch the owning agent, foreground, with a change-scoped prompt (this is
   a surgical edit, not a phase re-run): **oma-architect** for `stack`/`api`/`data_model`,
   **oma-ux-designer** for `tokens`/`motion` (tokens changes usually mean the
   mockups' tokens.css regenerates too — say so in the prompt). Standard
   preamble, handoff seq, and: change exactly this, touch nothing else, record
   an ADR if the change is architectural. For `stack`: re-run the compatibility
   proof and update the proof section — a pin set that isn't re-proven isn't a
   fix, it's the same defect with different numbers.
3. Verify the edit landed and is coherent (contract still parses; changed
   names are consistent within the file). For `stack`, verify the proof
   commands appear in `.oma/log/commands.jsonl` with exit code 0.
4. Re-hash (`shasum -a 256`), set `frozen: true`, bump the minor version
   (1.0 → 1.1). Record the decision in `state.decisions` citing the new version.
5. File rework tasks in `.oma/04-build/tasks.json` for every consumer found in
   step 2: stage `fix`, opened_by `oma-architect`/`oma-ux-designer`, evidence
   pointing at this change (D-### id), acceptance naming the new contract
   version. If the build phase hasn't started yet, skip — the backlog doesn't
   exist and Stage A will pick up the new contract naturally.
6. Rewrite the contracts line in `CLAUDE.md`.
7. Commit if in a git repo: `oma(change): <summary> — <contract> v<new version>`.

## 5. Report

Contract, old → new version, decision id, rework tasks filed (ids), and the
next command (`/oma:run` if mid-build — the fix tasks dispatch on the next run).
