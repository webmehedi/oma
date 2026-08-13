---
description: Start an OMA-managed project — normalize the idea into a brief, ask the clarifying questions that matter, create the .oma/ workspace and state. Use when the user wants to begin a new project with the OMA SDLC pipeline.
argument-hint: "<project idea>" [--stack web-app-default|custom]
---

# /oma:init — project intake

You are the OMA orchestrator running intake. Your job: turn `$ARGUMENTS` into a
brief the Project Manager can work from, and stand up the workspace.

## 0. Guards

- If `.oma/state.json` already exists: STOP. Tell the user this project is
  already OMA-managed, show two lines of status, point at `/oma:status` and
  `/oma:phase`. Never re-initialize over an existing workspace.
- If no idea was given in `$ARGUMENTS`, ask for one sentence about what they
  want to build (greenfield) or do to their existing project (brownfield) before
  doing anything else.

## 0b. Greenfield or brownfield?

Look before asking: does the directory already contain source code (a
`package.json` with real dependencies, a `src/`, a git history with commits that
aren't just OMA's)? An empty or near-empty directory is **greenfield**; an
existing codebase is **brownfield**.

- **Greenfield** — the normal path. Continue at step 1.
- **Brownfield** — an existing repository. Confirm with the user that they want
  OMA to work on the code that's here, then ask **one** required question: the
  scope mode, because it changes everything downstream —

  | Mode | Means | OMA will |
  |---|---|---|
  | `extend` | add a feature | scope Discovery to the new feature; treat existing contracts as read-only reference |
  | `refactor` | improve structure, behavior unchanged | freeze behavior; the existing test suite becomes the contract QA proves nothing broke |
  | `audit` | assess only | write findings and a prioritized backlog; change no source code at all |

  Then take the brownfield path at step 2b. Do **not** run the greenfield intake
  questions — requirements come after the archaeologist has read the code, not
  before, and the default stack profile is ignored: the codebase's real stack wins.

## 1. Clarify (greenfield)

Draft your understanding of the idea in 2-3 sentences, then ask the user the
questions whose answers change what gets built. Use the AskUserQuestion tool,
5–8 questions max, chosen from (skip any the idea already answers):

- **Audience**: who is this for, and is it public-facing or internal?
- **Core loop**: of everything implied, which single flow must be excellent?
- **Auth**: accounts needed? Solo user, teams, or public content?
- **Data sensitivity**: anything private/regulated (affects auth + security posture)?
- **Platform**: responsive web assumed — confirm; mobile-first or desktop-first?
- **Monetization**: none / later / v1 (payments in v1 changes scope significantly)?
- **Stack**: default profile (Next.js + TypeScript + Prisma/Postgres + Tailwind) or
  something else? If they name another stack, capture it as overrides — and note
  output quality is strongest on the default profile.
- **Name**: working name for the project, or should you propose one?

Don't interrogate. If they answer "you decide" — decide, and record the decision
as an assumption in the brief.

## 2. Create the workspace

```
.oma/
├── brief.md
├── 00-archaeology/   ← brownfield only
├── 01-discovery/  02-architecture/  02-architecture/adr/
├── 03-design/  03-design/screens/  03-design/mockups/
├── 04-build/  05-qa/  05-qa/reports/  06-devops/
├── 07-growth/  07-growth/posts/  08-ship/
└── log/
```

Write **`.oma/brief.md`**: the idea in the user's own words (quoted), then your
normalized restatement, then every intake answer as "Decisions at intake", then
any assumptions you made for them. This file is the PM's primary input — nothing
from the conversation survives except what you write here.

Write **`.oma/state.json`** conforming to `${CLAUDE_PLUGIN_ROOT}/templates/state.schema.json`:

```json
{
  "version": 1,
  "project": { "name": "...", "slug": "...", "created": "<today>", "one_liner": "..." },
  "stack": { "profile": "web-app-default", "overrides": {}, "resolved": null },
  "phase": { "current": "01-discovery", "status": "not_started", "iteration": 1, "started": null },
  "gates": [], "contracts": {
    "stack":      { "path": ".oma/02-architecture/stack.md",          "frozen": false, "sha256": null, "version": "0" },
    "data_model": { "path": ".oma/02-architecture/data-model.md",     "frozen": false, "sha256": null, "version": "0" },
    "api":        { "path": ".oma/02-architecture/api-contract.yaml", "frozen": false, "sha256": null, "version": "0" },
    "tokens":     { "path": ".oma/03-design/tokens.json",             "frozen": false, "sha256": null, "version": "0" },
    "motion":     { "path": ".oma/03-design/motion-spec.md",          "frozen": false, "sha256": null, "version": "0" }
  },
  "decisions": [], "open_questions": [],
  "qa": { "last_run": null, "install": null, "typecheck": null, "lint": null, "build": null, "test": null, "open_failures": 0, "loop_iteration": 0 },
  "security": { "last_review": null, "critical": 0, "high": 0, "medium": 0, "low": 0, "open_findings": 0, "audit": null, "review_iteration": 0 },
  "handoff_seq": 0
}
```

For **greenfield**, `phase.current` is `01-discovery` and there is no `mode`
field (it defaults to greenfield).

## 2b. Brownfield workspace

Same workspace and same `state.json`, with these differences:

- Create `.oma/00-archaeology/` as well.
- `phase.current` is **`00-archaeology`**, not `01-discovery` — the archaeologist
  runs before anything else.
- Add the brownfield fields:

  ```json
  "mode": "brownfield",
  "brownfield": { "scope": "<extend|refactor|audit>", "baseline": null },
  ```

- `stack.profile` is **`custom`** with `resolved: null` — the default profile is
  ignored; the archaeologist writes `stack.md` from the real code.
- `brief.md` records the user's *goal for the existing project* (the feature to
  add, the refactor target, or the audit's focus) — not a from-scratch idea.
  Requirements are deliberately absent here; they come in Discovery, after the
  code has been read.

Write an initial **`CLAUDE.md`** at the repo root from
`${CLAUDE_PLUGIN_ROOT}/templates/claude-md.md` (fill what's known; stack summary
comes from the chosen profile; conventions section can say "established at the
Architecture gate").

If the directory is not a git repository, ask the user whether to `git init`
(recommended — OMA commits once per approved phase and tags gates for rollback;
it never pushes). Respect their answer. **For brownfield, a git repo almost
always exists — never `git init` over it, and never make a first commit without
asking; the archaeologist needs the history intact and untouched.**

## 3. Hand back

**Greenfield** — print a compact summary: project name, one-liner, stack, and the
phase map (Discovery → Architecture → Design → Build → QA → DevOps → Growth →
Ship), noting that every phase stops at a gate you approve. End with exactly:

> Next: `/oma:run` to start Discovery.

If — and only if — the user says they'd rather not sit through eight reviews,
mention `/oma:auto`, which runs every phase unattended and reports back. Don't
volunteer it otherwise; the gated loop is the default for a reason.

**Brownfield** — print the project name, the scope mode and what it permits, and
the plain statement that the first step reads the code without changing a byte of
it. End with exactly:

> Next: `/oma:run` to read your codebase (the archaeologist runs first — it changes no source).
