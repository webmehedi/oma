---
description: Manual control of the OMA build backlog — add a task, reassign an owner, close or reopen a task, or list the backlog. Use when the user wants to inspect or adjust .oma/04-build/tasks.json directly rather than through a phase run.
argument-hint: list | add "<title>" [--req REQ-###] [--owner oma-frontend|oma-backend] | close T-### | reopen T-### | reassign T-### <owner>
---

# /oma:task — backlog control

You are the OMA orchestrator doing manual backlog surgery. Read
`.oma/state.json` and `.oma/04-build/tasks.json` (if the backlog doesn't exist
yet, only `list` and `add` make sense — `add` creates the file conforming to
`${CLAUDE_PLUGIN_ROOT}/templates/tasks.schema.json`).

Parse `$ARGUMENTS`:

## `list` (or empty)

Compact table — id, req, title, owner, status — grouped by status (blocked
first, then todo, in_progress, done last; `wontfix` only with a count unless
asked). One honest line at the end: what `/oma:run` would do with this backlog.

## `add "<title>"`

- **REQ required.** If `--req` names an existing REQ in prd.md, use it. If
  omitted: show the REQ list, ask which this serves. If it serves none — that's
  scope the PRD doesn't cover; offer to record it as a new requirement first
  (a REQ-### appended to prd.md with the user's one-line acceptance, plus a
  note in state.decisions), or park it in scope.md's deferred table. Never
  create an orphan task — every task citing a requirement is the invariant
  that keeps the backlog honest.
- Owner: from `--owner`, else infer from the title's territory and confirm.
- Acceptance: ask for it if not obvious — "done when what command passes, or
  what is visible where?" Write the task with `opened_by: "user"`, next
  `T-###` id, `next_id` incremented.

## `close T-###`

Mark `done` with `evidence: "closed by user"` — or `wontfix` if the user says
it shouldn't be done at all (ask which they mean if ambiguous). If other tasks
`depends_on` it, mention they just unblocked.

## `reopen T-###`

Back to `todo`, note appended with the reason. If it was a `fix` task closed by
a dev agent, flag that QA will re-verify it anyway on the next run.

## `reassign T-### <owner>`

Update owner. If the task's territory obviously mismatches the new owner
(a `src/server` task to oma-frontend), say so once — then do what the user says.

Always: preserve ids, never renumber, keep the JSON valid (parse it back after
writing). Report the change in one line.
