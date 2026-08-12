# Phase playbook: 04-build

Read by the orchestrator. Not read by agents.

## Preconditions

- Gate `03-design` is `approved` and all five contracts show `frozen: true`.
- No blocking `open_questions` for `user`.

## The dispatch preamble (prepend to every agent prompt in this phase)

```
You run in the project root (the directory containing .oma/). All `.oma/...`
paths in your role file are relative to it, and ${CLAUDE_PLUGIN_ROOT} is the
installed OMA plugin directory.
```

## Slice sizing — the hard-won rule

**Never dispatch more than ~2 tasks to one agent in one call.** Build tasks are
far heavier than spec tasks: an agent that scaffolds a project, installs
dependencies, writes a database schema, generates a migration, and authors a
shared schema layer will exhaust its context or stall before it can hand off.
This is observed behavior, not caution — a three-task foundation slice died
twice, while the same work in scoped follow-ups completed comfortably.

Prefer more, smaller dispatches over fewer, larger ones. Wall-clock is slightly
worse; completion rate is dramatically better.

## When an agent dies mid-dispatch

Agents die (API errors, stalls). Their work on disk survives, so **never
restart a dead agent's whole slice.** Instead:

1. Inventory what landed: the files its tasks were supposed to produce.
2. Check whether it appended its handoff (usually it didn't — that's the last step).
3. Re-dispatch a NEW agent scoped to *only the gap*, with an explicit
   "already done, do not redo:" list naming the surviving files, and an
   explicit "missing — this is your entire scope:" list.
4. Have the replacement append the handoff its predecessor never wrote,
   with the original seq.

A resumed agent that keeps its own context is fine to try first, but if it
stalls a second time, switch to the scoped-replacement path above.

## Why this phase is staged

Frontend and Backend genuinely run in parallel — but only where parallelism is
safe. Scaffolding (package.json, configs, shared schemas) is single-writer
territory; two agents installing dependencies concurrently corrupt the
lockfile. So: backlog → foundation (sequential) → features (parallel) →
reconcile. The stage rules in the agents' definitions assume this playbook
enforces the sequence.

## Stage A — backlog (skip if tasks.json already exists with tasks)

Dispatch **oma-project-manager**, foreground:

```
You are creating the build backlog for Phase 04-build.

Inputs, in order: .oma/state.json · .oma/01-discovery/prd.md ·
.oma/02-architecture/api-contract.yaml, data-model.md, stack.md ·
.oma/03-design/screens/, components.md · your inbox in .oma/log/handoffs.jsonl.

Output: .oma/04-build/tasks.json conforming to
${CLAUDE_PLUGIN_ROOT}/templates/tasks.schema.json.

Decompose: every must/should REQ into tasks sized for one agent-session each
(a screen, a resource's endpoints, a service). Every task: owner (oma-frontend
for src/app|components work, oma-backend for server|prisma|shared), stage
("foundation" for scaffold/deps/prisma-schema/shared-schemas/env — all owned
by oma-backend; "feature" for the rest), depends_on where real, and an
acceptance that is a runnable command or a mockup-parity check. Frontend's
first feature task is always the tokens.json → theme translation.

Do not invent tasks with no REQ. Next handoff seq: {seq}.
```

Verify: tasks.json parses against the schema's required fields; every task
cites an existing REQ; both owners have work; foundation tasks are all
backend-owned. Reconcile handoff.

## Stage B — foundation (sequential, ONE TASK PER DISPATCH)

Foundation is where slices are most tempting to batch and most punishing to
batch. Dispatch **oma-backend** once per foundation task, foreground, in
`depends_on` order. Typical decomposition:

| Dispatch | Scope |
|---|---|
| B1 | Scaffold: project init, all pinned deps installed, configs (TS/lint/format/build) |
| B2 | Database: schema translated from data-model.md + initial migration + db client |
| B3 | Shared layer: Zod schemas mirroring the contract, env validation, error envelope helper |
| B4 | HTTP layer: route-handler wrapper producing the contract envelope + a health endpoint + minimal app shell (root layout, placeholder page) so the build has something to compile |

Each dispatch gets the preamble plus:

```
Stage: foundation. Your task slice: {this dispatch's task(s) only}.
{if not the first dispatch: "Already done by prior dispatches, do NOT redo:
 <explicit file list>."}
Before you finish, run the checks your task's acceptance names and report the
real exit codes.
```

**After the last foundation dispatch, verify yourself — do not trust:** run
`npm run typecheck` and `npm run build` (or the stack.md equivalents) via Bash.
Confirm the database schema, shared schemas, and app shell exist. If red: one
scoped re-dispatch naming the failure output; twice red → phase `blocked`.

Note that the build cannot succeed without a minimal app shell (root layout +
one page) — B4 must produce it even though Frontend will replace it in T-011/T-012.

## Stage C — features (parallel)

Compute each agent's slice: `status == "todo"`, `stage == "feature"`, owner
respectively, dependencies satisfied — then **cap each slice at ~2 tasks** per
the sizing rule above. Dispatch **oma-frontend** and **oma-backend** in the SAME
message (two Agent calls, both `run_in_background: false`) so they run
concurrently. Each prompt: preamble + stage `feature` + its slice + reserved
handoff seqs (give frontend seq N+1, backend N+2 — they append independently;
collisions in `ts` order are fine, seq collisions are not).

With ~2 tasks per slice, expect several rounds of Stage C. That's intended —
see the round cap in Stage D.

Both agents know the territory rules; your job is the slices being disjoint by
construction (they are, if Stage A assigned owners correctly — spot-check any
task whose title smells cross-boundary before dispatching).

## Stage D — reconcile and iterate

1. Read both handoffs. Update tasks.json: `tasks_completed` → `done` (with
   evidence), `blocked_on` items → `blocked` with notes.
2. **Audit the claims**: run typecheck + build yourself. Spot-check 2-3 `done`
   tasks' acceptance commands against `.oma/log/commands.jsonl` — were they
   actually run?
3. Surface `contract_changes` immediately if any (→ `/oma:change` decision
   before continuing).
4. Tasks still `todo` → repeat Stage C with the next slices. Cap at **8 rounds**
   (small slices mean many rounds are normal); then set `blocked` and report
   what's stuck. Stop early and report if a round completes zero tasks — that's
   a stuck dependency or a misassigned owner, and another round won't fix it.
5. Promote questions; bump `handoff_seq` past all appended records.

## Gate presentation

Set `awaiting_gate`. Show:

1. Task table: done/blocked/todo counts per owner; blocked tasks listed with reasons.
2. The tail of YOUR OWN typecheck + build runs (real output, not agent claims).
3. How to try it: `npm run dev` and which routes exist.
4. Assumptions from both agents' handoffs, merged.
5. Note: "QA has not run yet — this gate is 'the build compiles and the
   backlog is done', not 'it works'. That's the next phase."
6. `/oma:gate approve` / `/oma:gate reject "why"`.
