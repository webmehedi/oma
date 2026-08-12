# Phase playbook: 08-ship

Read by the orchestrator. Not read by agents.

**No agents run in this phase.** Ship is assembly and honest accounting, both of
which need the whole picture at once — which is exactly what the orchestrator
has and a subagent doesn't. You do this work yourself.

## Preconditions

- Gate `07-growth` is `approved`.
- Reachable early via `/oma:ship` from any phase — in which case the report says
  plainly which phases never ran, and the checklist reflects that.

## Step 1 — the final verification run

Run the full pipeline yourself, now: install → typecheck → lint → build → test.
Record real exit codes.

**Verify from clean, not from the working tree.** A directory that has been
built in for days accumulates state — generated clients, caches, artifacts that
are gitignored and therefore absent from a fresh clone. "It passes here" is not
the claim the ship report makes; the claim is that *someone else can clone this
and run it*. So:

```bash
git clone . /tmp/ship-check && cd /tmp/ship-check && <install> && <the pipeline>
```

If the clean clone fails where the working tree passed, that gap **is** the
finding — usually a generated artifact that is gitignored with no `postinstall`
step to recreate it. File it, fix it before shipping, and never paper over it by
reporting the working tree's result. This exact defect survived a full
greenfield run undetected and was only caught later by the archaeologist reading
the project as a stranger.

This is not redundant with QA. Growth changed source, the harden round changed
source, and the last full pipeline run was several dispatches ago. **A ship
report is a claim about the state of the repository at ship time**, and it needs
evidence from ship time. If anything is red, stop and report — do not write a
ship report over a red build.

## Brownfield `audit` — write an audit report instead

In `audit` scope this phase produces
`.oma/08-ship/audit-report.md` from
`${CLAUDE_PLUGIN_ROOT}/templates/audit-report.md`, and **skips step 2 entirely**
— an audit does not write the user's README. Step 1's verification run still
happens: the audit's central number is whether the project is green *now*,
compared against the baseline the archaeologist recorded on arrival.

The report is findings, prioritized, each with evidence and an effort estimate,
plus the backlog in `tasks.json` — handed over, not started.

## Step 2 — the project's README

Write `README.md` at the repository root — the *project's* readme, for whoever
opens this repo next (including the user in six months).

**Check first whether one exists.** If it does and it wasn't written by OMA,
never overwrite it: write `README.oma.md` beside it and say so at the gate. A
scaffolded framework README (the default `create-next-app` one) may be replaced.

Contents, in this order:

- What it is — one sentence from `state.project.one_liner`.
- Status, honestly: what works, and known issues carried from QA `wontfix`.
- Stack, from `stack.md`, with versions.
- Quickstart: clone → install → env → migrate → run. Every command copy-pasteable.
- Environment variables, pointing at `.oma/06-devops/env.template`.
- Scripts table: every script in `package.json` and what it does.
- Project structure: the directories that matter, one line each.
- Deployment: one line plus a pointer to the runbook. Never inline the runbook.
- Where the project's own documentation lives — the `.oma/` map — and the
  sentence that makes it useful: *these are the decisions and the reasoning,
  not just the output.*
- License, if the user has stated one. If not, say it's unlicensed and that
  this means all rights reserved by default — a real consequence people miss.

## Step 3 — the ship report

Write `.oma/08-ship/ship-report.md` from
`${CLAUDE_PLUGIN_ROOT}/templates/ship-report.md`. This is the document that
makes the project inheritable, and its value is entirely in its honesty.

Assemble from state and artifacts — every number cited, none estimated:

- **Requirements:** every REQ with its status (shipped / partial / dropped) and
  where it was verified. Dropped requirements name the gate note or task that
  dropped them. This table is the honest scope of what exists.
- **Verification at ship time:** the exit codes from step 1, test counts, and
  the QA coverage table's `untested` rows repeated here rather than buried.
- **Known issues:** every `wontfix` task and every accepted security finding,
  with the reason recorded at the gate. Nothing quietly disappears at the end.
- **Security posture:** severity counts from the review, what was fixed, what
  was accepted, and the date of the review.
- **Contracts:** each contract with its final version and hash — the fingerprint
  of what the code was built against.
- **Decisions:** the `D-###` list with links to their ADRs — why it is the way
  it is, which is the first thing a future maintainer needs.
- **Open questions** still unanswered, including non-blocking ones.
- **Deploy checklist:** the numbered pre-flight from the runbook, condensed, with
  the reminder that the user runs it.
- **Growth assets:** an index of what's in `07-growth/` and what `[[TODO]]`s
  remain in it.
- **What to do next:** the three or four highest-value things, ordered — usually
  deploy, fill the copy TODOs, the deferred requirements, the medium security
  findings.
- **Cost:** if `.oma/log/commands.jsonl` and the handoff log make dispatch counts
  available, state how many agent dispatches and phases produced this. It's
  useful context for the user's next project.

## Step 4 — close the loop

0. If `state.ship` is absent (project initialized by OMA < 0.4.0), create it.
1. Rewrite `CLAUDE.md` from the template — final state, no phase in flight.
2. Set `state.ship`: `at`, `report` path, and the final pipeline verdicts.
3. Set `phase.status = "awaiting_gate"`.

## Gate presentation

The last gate. Show:

1. **The one-paragraph verdict:** what was built, what's verified, what isn't.
2. The requirements table: shipped / partial / dropped counts, with dropped named.
3. Ship-time pipeline results — your own exit codes.
4. Known issues and accepted security findings, listed.
5. The deploy checklist, and the plain statement that OMA has not deployed
   anything and will not.
6. Remaining `[[TODO]]`s the user must fill.
7. `/oma:gate approve` — records the final gate, commits, and tags `oma/ship`.

On approval the project is complete. Say so, and say what OMA no longer manages:
from here the repository is an ordinary repository, and future work is ordinary
development — `/oma:change` still governs the frozen contracts if they're
touched, and `/oma:phase` can re-run any phase against the built project.
