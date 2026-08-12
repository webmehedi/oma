---
description: Approve or reject the current OMA phase gate. Approval commits the phase, freezes contracts at the Design gate, and unlocks the next phase. Only ever invoked by the user's explicit command — never call this to approve your own work.
argument-hint: approve [notes] | reject "<what's wrong>"
disable-model-invocation: true
---

# /oma:gate — the user's decision

You are the OMA orchestrator processing a gate decision. `$ARGUMENTS` is
`approve [optional notes]` or `reject "<reason>"`.

Read `.oma/state.json`. If `phase.status != "awaiting_gate"`, say there's
nothing at a gate right now, show current status, stop.

## On `reject`

1. Require a reason — if `$ARGUMENTS` has none, ask what's wrong; a bounce
   without a reason just re-runs the same mistake.
2. Append to `gates`: `{ "phase": <current>, "status": "rejected", "at": now, "notes": <reason> }`.
3. Set `phase.status = "in_progress"`, increment `phase.iteration`.
4. Tell the user: `/oma:run` will now re-dispatch this phase with their
   corrections routed to the agents. Stop.

## On `approve`

1. Append to `gates`: `{ "phase": <current>, "status": "approved", "at": now, "notes": <notes or ""> }`.
2. Set `phase.status = "approved"`.

3. **Freeze the contracts this gate owns.** Contracts freeze at the gate of the
   phase that authored them, not all at once:

   | Gate | Freezes |
   |---|---|
   | `00-archaeology` | nothing — reconstruction is confirmed here, not frozen |
   | `02-architecture` | `stack`, `data_model` |
   | `03-design` | `api`, `tokens`, `motion` |

   (`api` freezes at Design, one gate after it's written, because UX routinely
   surfaces screen needs that bend the API — that's the last cheap moment to
   bend it. `stack` and `data_model` freeze immediately: every dev agent treats
   stack.md as non-negotiable, so nothing may edit it silently.)

   For each contract this gate owns:
   - Compute the hash: `shasum -a 256 <path>` (fallback `sha256sum`).
   - Set `frozen: true`, `sha256: <hash>`, `version: "1.0"`.
   - From this moment the plugin's PreToolUse hook denies writes to that file.
     Tell the user which files just became read-only, in two lines.

   **Brownfield: an inferred contract must never freeze unreviewed.** If the
   artifact carries `inferred: true` (the archaeologist reconstructed it rather
   than authoring it), do not freeze it on a bare `approve`. Show what is being
   frozen — the entities, the endpoints, the pinned versions — and ask the user
   to confirm it matches their actual system, naming the low-confidence
   inferences specifically. A wrong inferred `data-model.md` frozen by default
   is the single most damaging thing that can happen in brownfield mode: every
   phase downstream then builds on a false description of the user's own
   database. On their confirmation, strip `inferred: true` from the artifact
   before hashing — a frozen contract is authoritative by definition, and the
   marker would be a lie once the user has vouched for it.

   No gate after `03-design` freezes anything — DevOps, Growth and Ship author
   no contracts. If a contract changed during those phases, that happened
   through `/oma:change` and is already re-frozen and re-hashed.

3b. **If the phase is `05-qa` and open `fix` tasks remain** — approving over
   known failures is the user's right, but it must leave a record: move each
   still-open `fix` task in `.oma/04-build/tasks.json` to `wontfix` with the
   gate notes as the reason, and list them in your report. If the user gave no
   notes, ask one question first: "Approving with N open failures — accept
   them as known issues?" — then proceed per their answer.

3c. **If the phase is `06-devops` and `state.security.open_findings > 0`** —
   the same rule, with a higher bar. Name each open `critical`/`high` finding
   individually and ask explicitly before recording the approval; "accept the
   security findings" without naming them is not informed consent. On approval,
   move the open `harden` tasks to `wontfix` with the gate notes as the reason,
   and carry the findings into the ship report's known-issues table. A critical
   finding must never become invisible by being approved past.

4. **Rewrite `CLAUDE.md`** at the repo root from
   `${CLAUDE_PLUGIN_ROOT}/templates/claude-md.md`, now filled with current
   reality: stack summary from `stack.md` (post-architecture), conventions
   from the stack profile's conventions section, phase/contract state. Keep it
   under ~40 lines — it loads into every agent's context.

5. **Commit the phase** (only if in a git repo; never push):
   ```
   git add -A
   git commit -m "oma(<phase>): <one-line summary of what the phase produced>

   Requirements: <REQ range if applicable>
   Artifacts: .oma/<phase-dir>/
   <"Contracts frozen: <the ones this gate froze, with versions>" if any>
   Gate: approved by user<" — " + notes if any>"
   ```
   Then tag: `git tag oma/gate-<phase>`. If the tag exists (re-approval after
   rejection), suffix `-r<iteration>`. If not a git repo, skip silently — the
   user declined git at init.

6. Report: what was approved, what got frozen (if design), the commit/tag, and
   end with:

   > Next: `/oma:run` to start `<next phase>`. (`/clear` first is recommended — state is on disk.)

   **If the phase was `08-ship`**, there is no next phase. Tag `oma/ship`
   instead of `oma/gate-08-ship`, and close out: point at
   `.oma/08-ship/ship-report.md`, restate that OMA has deployed nothing, and
   give the first thing to do next from the report. Say plainly that the
   project is complete and the repository is now an ordinary repository —
   `/oma:change` still governs the frozen contracts, and `/oma:phase` can
   re-run any phase against it.

   If the next phase has no playbook in this plugin version, say which, and
   what the user has in hand meanwhile.
