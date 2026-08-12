# Phase playbook: 01-discovery

Read by the orchestrator (`/oma:run` and `/oma:phase`). Not read by agents.

## Preconditions

- `.oma/brief.md` exists and reflects the user's answers from intake.
- No blocking `open_questions` addressed to `user` in state.json.

## Dispatch

One agent, foreground:

**oma-project-manager** — dispatch with a prompt containing exactly this context
(pointers, not pasted content):

```
You run in the project root (the directory containing .oma/). All `.oma/...`
paths in your role file are relative to it, and ${CLAUDE_PLUGIN_ROOT} is the
installed OMA plugin directory.

You are running Phase 01-discovery for this project.

Inputs (read in this order):
- .oma/state.json
- .oma/brief.md
- Your handoff inbox: .oma/log/handoffs.jsonl, records addressed to
  oma-project-manager (seq range: {computed by orchestrator; "none yet" on first run})
{if this is a re-run, add:}
- The user rejected the previous gate with these corrections: "{notes}".
  The existing artifacts in .oma/01-discovery/ are your starting point — revise,
  don't restart, except where the corrections demand it.

Templates: use ${CLAUDE_PLUGIN_ROOT}/templates/prd.md as the PRD skeleton.

Outputs (all required):
- .oma/01-discovery/prd.md
- .oma/01-discovery/scope.md
- .oma/01-discovery/personas.md
- .oma/01-discovery/success-metrics.md

Next handoff seq to use: {state.handoff_seq + 1}
```

## Verification (orchestrator, after the agent returns)

- [ ] All four artifact files exist and are non-trivial (> 30 lines each except success-metrics).
- [ ] `prd.md` contains at least 5 `REQ-` ids and every REQ has acceptance criteria.
- [ ] `scope.md` has a non-empty "Out of scope" table — a scope doc with no non-goals is a rejection.
- [ ] A handoff record with `from: "oma-project-manager"` was appended.
- [ ] Promote any `questions` from the handoff into `state.open_questions`; update `state.handoff_seq`.

If verification fails: re-dispatch the agent once with the specific gap named.
If it fails twice: set phase status `blocked` and tell the user what's wrong.

## Gate presentation

Set phase status to `awaiting_gate`, then show the user:

1. The one-paragraph solution summary from the PRD.
2. The full REQ table: id, title, priority — so scope is scannable in ten seconds.
3. The out-of-scope table verbatim — **this is the part to read most carefully;
   a misread requirement caught here costs minutes, caught in Build it costs hours.**
4. Any assumptions and non-blocking questions from the handoff.
5. Instruct: `/oma:gate approve` or `/oma:gate reject "what's wrong"`.

## Brownfield

When `state.mode == "brownfield"`, the PM is writing requirements for a system
that already exists, and the archaeologist's artifacts are its description. Add
to the dispatch: read `.oma/00-archaeology/map.md` and
`.oma/02-architecture/conventions.md` first.

- **`extend`** — Discovery covers the **new feature only**. `REQ-###` ids are
  assigned for the new work; existing behavior is context, not requirements to
  re-derive. The scope document's most useful section becomes "what this feature
  must not change".
- **`refactor`** — there is no new user-facing requirement. Discovery produces a
  short statement of the structural goal, the behavior that must be preserved,
  and how preservation will be proved (which is the existing test suite —
  including its blind spots, named from the baseline).
- **`audit`** — Discovery is skipped. The user's goal is in `brief.md` and the
  findings come from assessment, not from requirements.
