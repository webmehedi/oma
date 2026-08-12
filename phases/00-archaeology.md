# Phase playbook: 00-archaeology

Read by the orchestrator. Not read by agents.

**Brownfield only.** This phase runs once, before Discovery, when `/oma:init`
was pointed at a repository that already has source code. Greenfield projects
skip it entirely. Its job: reconstruct the `.oma/` artifacts a greenfield team
would have authored, so every later phase runs against an existing project
unchanged.

The load-bearing idea (DESIGN §18): the pipeline doesn't care whether the
artifacts were *authored* or *inferred*. If `stack.md`, `data-model.md` and
`api-contract.yaml` can be reverse-engineered accurately, Architecture onward
works as-is. The risk is entirely in that word *accurately* — a wrong inferred
data model poisons every phase downstream, which is why nothing here freezes
without the user's review at the gate.

## Preconditions

- `state.mode` is `brownfield` and `state.brownfield.scope` is one of
  `extend` · `refactor` · `audit` (set at init).
- The target directory contains source code and, ideally, a git history.
- This phase has not already produced an approved baseline. If it has, do not
  re-run it silently — re-running the archaeologist is a deliberate `/oma:phase
  00-archaeology` action, because it overwrites inferred artifacts the user may
  have since corrected.

## The dispatch preamble (prepend to the agent prompt)

```
You run in the project root (the directory containing .oma/ and the existing
source). All `.oma/...` paths are relative to it, and ${CLAUDE_PLUGIN_ROOT} is
the installed OMA plugin directory. This is an EXISTING repository — you read
and reconstruct; you never modify source code.
```

## Dispatch

Dispatch **oma-archaeologist**, foreground:

```
Brownfield scope: {state.brownfield.scope}.
Baseline template: ${CLAUDE_PLUGIN_ROOT}/templates/baseline.md
Establish the baseline FIRST — run install/typecheck/lint/build/test, record
real exit codes in .oma/00-archaeology/baseline.md, red or green stated plainly.
Do the install non-destructively if a working node_modules already exists.
Then reconstruct, every artifact marked inferred:true with a confidence line:
  .oma/00-archaeology/map.md
  .oma/02-architecture/stack.md          (versions from the LOCKFILE)
  .oma/02-architecture/data-model.md
  .oma/02-architecture/api-contract.yaml (from real routes)
  .oma/02-architecture/conventions.md    (contradictions documented, not resolved)
  .oma/02-architecture/adr/              (reasoning marked recovered vs inferred)
  .oma/03-design/tokens.json + components.md  (only if a design system is extractable)
Do not invent requirements — those come from the user in Discovery, after you.
Next handoff seq: {seq}.
```

## Verification — run these yourself, do not trust the summary

1. **Source is untouched.** `git status --porcelain` shows changes only under
   `.oma/` (and only if `.oma/` is inside the repo). A single modified source
   file is a boundary violation — revert it and re-dispatch with the boundary
   restated. This is the check that matters most in this phase.
2. **The baseline is real.** `.oma/00-archaeology/baseline.md` exists with a
   verdict per stage. Spot-run one stage yourself (typecheck or test) and
   confirm your exit code matches what it reported. A baseline that claims green
   on a red repo is the worst possible start.
3. **Versions came from the lockfile.** Pick two dependencies in `stack.md` and
   confirm the pinned versions match the lockfile, not the `package.json` range.
4. **Artifacts are marked inferred.** Grep the produced files for `inferred:
   true`. Any architecture artifact missing it must not be eligible to freeze —
   re-dispatch to add it.
5. **Nothing is frozen.** Confirm every contract in `state.contracts` still has
   `frozen: false`. Inferred artifacts cannot freeze here; they freeze only
   after the user reviews them, at the Architecture gate on the next pass.

Reconcile the handoff. Promote its `questions` into `state.open_questions` —
committed secrets, contradictory schemas, "which of these two patterns is
canonical" are the usual ones, and they are exactly what the user must resolve
before Discovery. Record the baseline verdict into `state.qa` and
`state.brownfield.baseline`. Bump `handoff_seq`.

## Gate presentation

Set `awaiting_gate`. This gate is different from every other: the user is not
approving *work*, they are **confirming a reconstruction is accurate**. Frame it
that way. Show:

1. **The baseline, first and plainly:** green or red, per stage, with the exact
   commands. If red, say so at the top — it changes everything about what the
   scope can safely be.
2. **The map:** entry points and the handful of files that matter, so the user
   can sanity-check that the archaeologist understood the shape of their project.
3. **What to check hardest:** the lowest-confidence inferences and every
   documented contradiction, each as a question the user can answer. This is
   where a wrong reconstruction is caught cheaply — an unreviewed `data-model.md`
   is a landmine.
4. **Blocking questions** — committed secrets, or a schema ambiguity that Discovery
   can't proceed past — listed for an answer before anything advances.
5. The scope mode and what it permits, restated:
   - `extend` — existing contracts are read-only; Discovery scopes to the new feature.
   - `refactor` — behavior is frozen; the existing test suite becomes the contract.
   - `audit` — read-only; the pipeline will produce findings and a backlog, no source changes.
6. `/oma:gate approve` — accepts the reconstruction and moves to Discovery.
   `/oma:gate reject "what's wrong"` — corrections route back to a re-run.

On approval, advance to `01-discovery`. The inferred artifacts are now the
project's working memory; they freeze later, at their normal gates, once the
work built on them has been reviewed too.
