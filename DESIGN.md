# OMA — One Man Army

**A Claude Code plugin that runs a full SDLC with a team of role-specialized agents.**

Design document · v0.1 · 2026-08-11 · status: for review

---

## 1. What this is

You give it a project idea. It runs Discovery → Architecture → Design → Build → QA → DevOps → Growth, one phase at a time, with a team of specialist agents, and hands you a working repository plus the documents a real team would have produced along the way.

It stops after every phase and shows you what it made. You approve, correct, or redirect. Then it continues.

### Goals

- Turn a paragraph-length idea into a running, tested, deployable application.
- Produce the *supporting* artifacts too — PRD, data model, API contract, design system, test plan, CI, deploy runbook, SEO and launch material — because those are what make a codebase maintainable by a solo developer six months later.
- Be resumable. Close your laptop mid-project, come back next week, `/oma:status`, continue.
- Be inspectable. Every decision an agent makes is written to a file you can read and edit.

### Non-goals

- **It does not deploy.** DevOps writes the pipeline and the runbook; pushing to production is a command you run, with your credentials.
- **It does not post, publish, or send anything.** Marketer and Social write copy and calendars to disk. Distribution is yours.
- **It is not a replacement for judgment.** It's a very fast team that needs a decisive manager. You are the manager.

---

## 2. Constraints that shape the design

Three properties of Claude Code determine the entire architecture. Everything downstream is a consequence of these.

### 2.1 Subagents cannot communicate with each other

A subagent is spawned by the main thread, runs in an isolated context window, and returns a single text summary. There is no peer-to-peer messaging, no shared memory, no way for the Backend agent to ask the Frontend agent a question.

**Consequence: the filesystem is the message bus.** Agent-to-agent communication is implemented as durable artifacts plus an append-only handoff log. The Backend agent doesn't message the Frontend agent — it writes `api-contract.yaml` and appends a handoff record naming Frontend as a recipient. When Frontend runs, its prompt points at that record.

This is not a workaround so much as an accurate model of how engineering teams actually coordinate: through specs, tickets, and contracts, not telepathy. It also has a real benefit — every handoff is a file you can read, diff, and edit.

### 2.2 One session cannot hold an entire SDLC

Context runs out. A single `/build-my-app` invocation that runs to completion will die halfway through Build with no recoverable state.

**Consequence: phases are separate invocations over durable state.** `.oma/state.json` is the source of truth. The orchestrator reads it, decides what's next, dispatches, verifies, updates it, and stops. Running `/clear` between phases is not just safe — it's recommended, and `/oma:status` reconstructs everything from disk.

### 2.3 Plugin agents ignore some frontmatter

Agents shipped inside a plugin have their `hooks`, `mcpServers`, and `permissionMode` frontmatter ignored. Only agents installed into a project's or user's own `.claude/agents/` honor those fields.

**Consequence: all enforcement lives at plugin level**, in `hooks/hooks.json`, not in individual agent definitions. Contract-freeze protection, artifact validation, and phase-boundary checks are plugin hooks that see every agent's tool calls.

---

## 3. Repository layout (the plugin)

```
oma/
├── .claude-plugin/
│   ├── plugin.json                 # manifest
│   └── marketplace.json            # so users can /plugin marketplace add webmehedi/oma
├── agents/                         # 12 role definitions
│   ├── oma-project-manager.md      #   …architect, ux-designer, frontend,
│   ├── oma-architect.md            #   backend, qa, security, devops, seo,
│   ├── ...                         #   marketer, social
│   └── oma-archaeologist.md        # brownfield only (M5)
├── skills/
│   ├── oma-init/SKILL.md           # intake: idea → brief + clarifying questions
│   ├── oma-run/SKILL.md            # advance to the next phase
│   ├── oma-phase/SKILL.md          # run one named phase (re-runnable)
│   ├── oma-status/SKILL.md         # where am I, what's blocked
│   ├── oma-gate/SKILL.md           # approve / reject the current phase
│   ├── oma-change/SKILL.md         # request a change to a frozen contract
│   ├── oma-task/SKILL.md           # add / reassign a backlog item
│   └── oma-ship/SKILL.md           # final assembly + handoff report
├── phases/                         # 00-archaeology … 08-ship playbooks (orchestrator-read)
├── hooks/
│   ├── hooks.json
│   └── scripts/                    # contract-guard, deploy-guard, audit-guard,
│                                   # command-log, handoff-check, session-start
├── scripts/selftest.sh             # 41 behavioral cases across all six hooks
├── examples/ledgerly/              # a complete .oma/ from a real run (M6)
├── templates/
│   ├── state.schema.json
│   ├── handoff.schema.json
│   ├── prd.md
│   ├── adr.md
│   └── ...
├── stacks/
│   └── web-app-default.md          # the opinionated default stack profile
├── TROUBLESHOOTING.md
├── CHANGELOG.md
└── README.md
```

---

## 4. Workspace layout (created in the user's project)

```
.oma/
├── state.json                      # single source of truth
├── brief.md                        # the idea, normalized
├── 01-discovery/
│   ├── prd.md                      # requirements, each with a stable REQ-### id
│   ├── personas.md
│   ├── scope.md                    # in scope / out of scope / deferred
│   └── success-metrics.md
├── 02-architecture/
│   ├── stack.md                    # every dev agent reads this first
│   ├── data-model.md               # entities, relations, constraints
│   ├── api-contract.yaml           # OpenAPI 3.1 — FROZEN at the design gate
│   └── adr/ADR-001-*.md            # one file per irreversible decision
├── 03-design/
│   ├── design-system.md
│   ├── tokens.json                 # design tokens — FROZEN at the design gate
│   ├── motion-spec.md              # durations, easings, stagger — FROZEN
│   ├── components.md               # component inventory with props
│   ├── screens/<screen>.md         # layout, states, empty/error/loading, a11y notes
│   └── mockups/                    # runnable HTML/CSS — open in a browser
│       ├── index.html              #   mockup index, links every screen
│       ├── tokens.css              #   generated from tokens.json
│       ├── motion.js               #   Lenis + Motion setup from motion-spec.md
│       └── <screen>.html
├── 04-build/
│   └── tasks.json                  # the backlog agents pull from
├── 05-qa/
│   ├── test-plan.md
│   ├── security-review.md
│   └── reports/run-<n>.md          # actual command output, not claims
├── 06-devops/
│   ├── deploy-runbook.md
│   ├── env.template
│   └── (Dockerfile, CI config written into the repo proper)
├── 07-growth/
│   ├── seo-brief.md
│   ├── positioning.md
│   ├── landing-copy.md
│   ├── launch-plan.md
│   └── social-calendar.md
└── log/
    └── handoffs.jsonl              # append-only message bus
```

Application source code goes in the repository proper (`src/`, `app/`, wherever the stack dictates). `.oma/` holds process artifacts only. It is committed — it's the project's memory.

---

## 5. `state.json`

The orchestrator's entire working memory. Small enough to read on every invocation.

```json
{
  "version": 1,
  "project": {
    "name": "Ledgerly",
    "slug": "ledgerly",
    "created": "2026-08-11",
    "one_liner": "Invoicing for freelancers who hate invoicing."
  },
  "stack": {
    "profile": "web-app-default",
    "overrides": { "db": "sqlite" },
    "resolved": ".oma/02-architecture/stack.md"
  },
  "phase": {
    "current": "04-build",
    "status": "in_progress",
    "iteration": 1,
    "started": "2026-08-11T18:40:00Z"
  },
  "gates": [
    { "phase": "01-discovery",    "status": "approved", "at": "2026-08-11T17:02:00Z", "notes": "cut multi-currency" },
    { "phase": "02-architecture", "status": "approved", "at": "2026-08-11T17:48:00Z", "notes": "" },
    { "phase": "03-design",       "status": "approved", "at": "2026-08-11T18:39:00Z", "notes": "" }
  ],
  "contracts": {
    "stack":      { "path": ".oma/02-architecture/stack.md",          "frozen": true, "sha256": "b204…", "version": "1.0" },
    "data_model": { "path": ".oma/02-architecture/data-model.md",     "frozen": true, "sha256": "77de…", "version": "1.1" },
    "api":        { "path": ".oma/02-architecture/api-contract.yaml", "frozen": true, "sha256": "3f9a…", "version": "1.2" },
    "tokens":     { "path": ".oma/03-design/tokens.json",             "frozen": true, "sha256": "c81b…", "version": "1.0" },
    "motion":     { "path": ".oma/03-design/motion-spec.md",          "frozen": true, "sha256": "30e2…", "version": "1.0" }
  },
  "decisions": [
    { "id": "D-004", "question": "Auth: sessions or JWT?", "answer": "Cookie sessions, 7d", "by": "oma-architect", "at": "2026-08-11T17:31:00Z", "adr": "ADR-003" }
  ],
  "open_questions": [
    { "id": "Q-011", "from": "oma-backend", "for": "user", "text": "Should invoices be soft-deleted or hard-deleted?", "blocking": true }
  ],
  "qa": {
    "last_run": "2026-08-11T19:10:00Z",
    "install": "pass", "typecheck": "pass", "lint": "warn", "build": "pass", "test": "fail",
    "open_failures": 3,
    "loop_iteration": 1
  },
  "handoff_seq": 27
}
```

**Phase status values:** `not_started` · `in_progress` · `awaiting_gate` · `approved` · `blocked`

**Invariant:** the orchestrator never advances past a phase whose gate is not `approved`, and never dispatches a build agent while `open_questions` contains a `blocking: true` entry addressed to `user`.

---

## 6. Shared memory and communication

Agents have no shared context window. Everything they "know in common" is reconstructed from disk at the start of every dispatch. This section defines exactly what gets loaded, in what order, and how one agent's output becomes another's input.

### 6.1 The five memory layers

Every agent, on every dispatch, assembles its working knowledge from five layers. Layers 0–2 are identical for all agents — that's the *shared* memory. Layers 3–4 are what makes each dispatch different.

| Layer | What | Loaded how | Scope |
|---|---|---|---|
| **L0 — Constitution** | Role, boundaries, definition of done | Baked into `agents/oma-*.md` | Per role, never changes |
| **L1 — Project memory** | Stack, conventions, directory map, current phase | `CLAUDE.md` at repo root, auto-loaded | Every agent, every dispatch |
| **L2 — Shared facts** | Contracts, PRD, data model, design tokens | Mandatory bootstrap reads (§6.2) | Every agent, every dispatch |
| **L3 — Inbox** | What other agents just did and said | Handoff log slice, pointer in prompt | Per dispatch |
| **L4 — Assignment** | Which tasks, which requirements | `tasks.json` slice + `state.json` | Per dispatch |

**L1 is the important one.** OMA generates and maintains `CLAUDE.md` at the repository root — the file Claude Code loads as project memory. The orchestrator rewrites it at every phase gate so it always reflects reality:

```markdown
<!-- Maintained by OMA. Edit .oma/ artifacts, not this file. -->
# Ledgerly
Invoicing for freelancers who hate invoicing.

## Stack
Next.js App Router · TypeScript strict · Prisma/Postgres · Tailwind · Zod · Vitest
Full detail: .oma/02-architecture/stack.md — do not deviate.

## Conventions
- Server code in src/server/, client in src/app/. Never cross.
- Every API route validates input with a Zod schema shared from src/shared/schemas/.
- Animation values come from .oma/03-design/motion-spec.md. No magic numbers.

## Current state
Phase 04-build · contracts FROZEN (api v1.2, tokens v1.0)
Read .oma/state.json before doing anything.
```

This is the cheapest possible mechanism for shared memory: one file, loaded automatically, always current. It carries the facts *every* agent needs. Everything larger stays in `.oma/` and gets read on demand.

### 6.2 The bootstrap sequence

L2 is not left to chance. Every agent definition opens with the same mandatory four-step read, in the same order, before it is permitted to do anything:

```
1. .oma/state.json                        — where am I, what's frozen, what's blocking
2. .oma/02-architecture/stack.md          — non-negotiable technology constraints
3. .oma/log/handoffs.jsonl (your slice)   — what just happened, addressed to you
4. your phase's contract artifacts        — api-contract.yaml, tokens.json, data-model.md
```

Four files, ~3–5k tokens, and two agents that run a week apart start from an identical picture of the project. This is what "same memory" actually means in practice — not a shared context window, but a deterministic reconstruction procedure that every agent follows identically.

### 6.3 The handoff protocol

`.oma/log/handoffs.jsonl` — append-only, one JSON object per line. Every agent's final act is to append one record. This is the entire inter-agent communication mechanism.

```json
{
  "seq": 27,
  "ts": "2026-08-11T19:04:00Z",
  "from": "oma-backend",
  "phase": "04-build",
  "to": ["oma-frontend", "oma-qa"],
  "summary": "Auth + invoice CRUD implemented against api-contract.yaml v1.2. Sessions are httpOnly cookies.",
  "produced": ["src/server/routes/auth.ts", "src/server/routes/invoices.ts", "prisma/migrations/0003_invoices/"],
  "consumed": [".oma/02-architecture/api-contract.yaml", ".oma/02-architecture/data-model.md"],
  "tasks_completed": ["T-014", "T-015", "T-016"],
  "assumptions": [
    "Invoice line items are embedded, not a separate queryable entity — matches data-model.md but worth confirming."
  ],
  "blocked_on": [],
  "questions": [
    { "id": "Q-011", "for": "user", "text": "Soft-delete or hard-delete invoices?", "blocking": true }
  ],
  "contract_changes": []
}
```

### How an agent reads its inbox

The orchestrator does **not** paste handoff content into the agent prompt — that wastes context and doesn't scale. Instead the dispatch prompt says:

> Your inbox is `.oma/log/handoffs.jsonl`, records seq 19–27, filtered to those where `to` includes `oma-frontend`. Read them before you begin.

The agent reads the file itself. Cheap, and the agent sees the raw record rather than a lossy paraphrase.

### `contract_changes` is the dangerous field

If an agent needs to alter a frozen contract, it does **not** edit it. It records the requested change here and stops. The orchestrator surfaces it to you as a change request. See §9.

### 6.4 The five communication patterns

Everything agents need to say to each other reduces to five patterns. Agents never route messages themselves — they **declare intent** in a structured field, and the orchestrator does the routing on the next dispatch.

**1. Broadcast** — "here is a fact everyone must respect."
Write to a shared artifact. Architect writes `api-contract.yaml`; every downstream agent reads it in bootstrap. No addressing needed. This is how the load-bearing decisions travel.

**2. Directed handoff** — "I finished X, you need to know."
Append a handoff with `to: ["oma-frontend", "oma-qa"]`. Those agents' next dispatch prompt names the seq range.

**3. Work assignment** — "someone must do this."
Append to `tasks.json` with an `owner`. This is the ticket system, and it's how work crosses phase boundaries:

```json
{
  "id": "T-041",
  "req": "REQ-012",
  "title": "Invoice list paginates at 25 and preserves filters in the URL",
  "owner": "oma-frontend",
  "status": "todo",
  "depends_on": ["T-038"],
  "opened_by": "oma-qa",
  "evidence": ".oma/05-qa/reports/run-2.md#L84",
  "acceptance": "playwright: invoices.spec.ts 'preserves filter on page 2' passes"
}
```

Every task cites a `req` — that's the shared vocabulary of features. A task that traces to no requirement is scope creep and gets rejected at the gate.

**4. Question upward** — "I can't decide this alone."
Append to `questions` on the handoff with `for: "user"` or `for: "oma-architect"`, and `blocking: true|false`. The orchestrator promotes these into `state.open_questions`. A blocking question addressed to `user` halts dispatch — the system refuses to build on a guess. A non-blocking one is recorded as an assumption and surfaced at the gate, so you can catch it before it compounds.

**5. Feedback loop** — "this is wrong, fix it."
QA files a task back to the original owner with `evidence` pointing at a specific line of a real command log. The owner cannot close it without a passing `acceptance` command. This is the only backward edge in the system, and it's what makes the build converge rather than merely terminate.

### 6.5 Why the orchestrator must be the router

It would be possible to let agents spawn each other directly — a subagent can invoke the `Agent` tool. I'm deliberately not doing that:

- **Depth limits.** Nested agents lose the `Agent` tool at the nesting limit, so the call graph silently changes shape depending on how deep you are. Unpredictable.
- **Lost state.** A nested agent's output returns to its *parent agent*, not to the orchestrator, so it never reaches `state.json`. Work happens that the project has no record of.
- **No gate.** Nested spawning routes around your phase approvals entirely.
- **Unbounded cost.** Agents spawning agents is how a single command turns into a very large bill.

Keeping all dispatch in the main thread means every agent invocation is logged, gated, budgeted, and visible to you. The cost is that agents can't get an instant answer from a peer — they have to record a question and wait for the next dispatch. That's the right trade.

### 6.6 Cross-session memory

`.oma/` is committed to git. That is the memory. A fresh session with an empty context window runs `/oma:status`, reads `state.json`, and knows the project as well as the session that built it — because no knowledge ever lived in conversation.

Agent definitions may additionally set `memory: project` for role-scoped learning that persists across sessions (e.g. Frontend remembering a recurring pattern in this codebase). This is a nice-to-have layered on top, not load-bearing — I'll verify it behaves correctly for plugin-supplied agents during M1 and drop it if it doesn't.

---

## 7. Phase model

Every phase has: a **trigger**, a set of **agents**, **required artifacts**, and a **gate condition**. The orchestrator will not mark a phase `awaiting_gate` until every required artifact exists and is non-trivial.

| # | Phase | Agents | Required artifacts | Gate |
|---|-------|--------|--------------------|------|
| 0 | **Intake** | — (main thread) | `brief.md` | You answer the clarifying questions |
| 1 | **Discovery** | PM, Marketer (positioning input) | `prd.md`, `scope.md`, `personas.md`, `success-metrics.md` | You approve scope and non-goals |
| 2 | **Architecture** | Architect, then Security (design review) | `stack.md` (with compatibility proof), `data-model.md`, `api-contract.yaml`, `adr/` | You approve the stack and data model. **`stack` + `data_model` freeze here.** |
| 3 | **Design** | UX Designer | `design-system.md`, `tokens.json`, `motion-spec.md`, `components.md`, `screens/`, **`mockups/` (runnable HTML)** | You open the mockups in a browser and approve. **Contracts freeze here.** |
| 4 | **Build** | Frontend ∥ Backend | working code, `tasks.json` all `done` | build passes (checked, not claimed) |
| 5 | **QA** | QA | `reports/run-N.md` | tests green or you accept known failures |
| 6 | **DevOps** | Security, then DevOps | `security-review.md`, Dockerfile, CI config, `deploy-runbook.md`, `env.template` | You approve the security posture and the deploy plan |
| 7 | **Growth** | SEO ∥ Marketer ∥ Social | `seo-brief.md` + implemented metadata, `landing-copy.md`, `social-calendar.md` | You approve |
| 8 | **Ship** | — (main thread) | project `README.md`, `ship-report.md` | done |

**Security moved to phase 6 during M4.** It was specified to run in phases 2 and
5. In practice it needs two things phase 5 can't offer: a *running* application
to probe (its highest-value finding class — cross-user authorization — is only
provable against a live instance), and a position *before* the deploy configs,
because headers, secret handling and container hardening are inputs to what
DevOps writes. Reviewing after the runbook exists means writing the runbook
twice. Its findings still route back to the build agents as `harden` tasks in a
bounded 2-round loop, which is the phase-5 loop shape applied one phase later.

### Parallelism

Two places where agents genuinely run concurrently, both enabled by frozen contracts:

- **Phase 4:** Frontend and Backend both code against `api-contract.yaml`. Neither reads the other's source. Frontend mocks the API from the contract until Backend lands.
- **Phase 7:** SEO, Marketer, and Social touch disjoint files.

Everywhere else, agents run in sequence because each genuinely depends on the previous one's output.

### Re-running a phase

`/oma:phase design` re-runs Design with the existing artifacts as input and your correction as the instruction. Downstream gates that depended on it are invalidated and re-requested. This is the normal way to iterate — not by arguing with an agent mid-run.

### The design mockup pipeline

The Design phase produces **runnable HTML/CSS you open in a browser**, not descriptions and not images. This is the highest-leverage quality lever in the whole system: it moves the "that's not what I wanted" conversation from after the build to before it, when it costs minutes instead of hours.

```
tokens.json ──generate──> mockups/tokens.css ──┐
                                                ├──> mockups/<screen>.html  (static, opens in any browser)
motion-spec.md ─generate─> mockups/motion.js ──┘
                                                       │
                                        you review ────┤
                                                       ▼
                                            Frontend implements in the real
                                            stack, reading the SAME tokens.css
                                            and motion-spec.md
```

**Mockup stack** (all CDN, zero build step, single-file-openable):

- **Tailwind** via Play CDN, configured from `tokens.css` custom properties
- **Lenis** for smooth scroll
- **Motion** (motion.dev) for animation — the vanilla-JS library from the Framer Motion author. *Framer Motion itself is React-only and cannot run in a standalone HTML file;* Frontend translates Motion's declarations to Framer Motion at build time, and because both read `motion-spec.md`, the values match.
- **View Transitions API** for page-to-page morphs where supported
- Optional per-project: GSAP ScrollTrigger for complex scroll choreography

**`motion-spec.md` is what prevents drift.** Animation is where mockups and production diverge worst — the mockup feels great, the build feels wrong, and nobody can say why. Defining motion as frozen tokens rather than per-implementation taste fixes that:

```markdown
| token            | duration | easing                          | use |
|------------------|----------|---------------------------------|-----|
| `enter.fast`     | 180ms    | cubic-bezier(.2,0,0,1)          | tooltips, menus |
| `enter.default`  | 320ms    | cubic-bezier(.2,0,0,1)          | cards, modals |
| `exit.default`   | 200ms    | cubic-bezier(.4,0,1,1)          | dismissals |
| `stagger.list`   | 40ms     | —                               | list item cascade |
| `scroll.lerp`    | 0.1      | Lenis default                   | page smooth scroll |

All motion respects `prefers-reduced-motion: reduce` — durations collapse to 0ms,
transforms become opacity-only. This is not optional.
```

**Self-review:** Claude Code has browser tools, so the UX agent opens its own mockup, screenshots it at mobile/tablet/desktop widths, and fixes what's visibly broken before handing it to you. It reviews its own work rather than shipping you the first draft.

**Acceptance:** the mockup becomes the reference. A Frontend task isn't done because the code compiles — it's done when the built screen matches `mockups/<screen>.html`, which QA can check by loading both.

---

## 8. Agent contracts

Every agent definition follows the same template so behavior is predictable:

```markdown
---
name: oma-backend
description: Implements server-side code against the frozen API contract and data model. Use during the Build phase for API endpoints, business logic, database access, and migrations.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
color: green
---

## Role
[one paragraph]

## Always do first
1. Read `.oma/state.json`.
2. Read `.oma/02-architecture/stack.md` — this is not negotiable, do not introduce
   a different framework, ORM, or language.
3. Read your inbox from `.oma/log/handoffs.jsonl`.
4. Read `.oma/02-architecture/api-contract.yaml` and `data-model.md`.

## Your outputs
[explicit file list]

## Boundaries
- You never edit files under `src/client/` or `.oma/03-design/`.
- You never edit a frozen contract. If you need one changed, record it in
  `contract_changes` on your handoff and stop.
- You never mark a task `done` without running the command that proves it.

## Definition of done
[checklist that must be literally true]

## Always do last
Append one handoff record to `.oma/log/handoffs.jsonl`. Do not summarize your work
in prose to the caller beyond three sentences — the handoff record is the deliverable.
```

### The roster

| Agent | Owns | Writes | Never touches |
|---|---|---|---|
| **project-manager** | scope, requirements, backlog | `01-discovery/*`, `04-build/tasks.json` | source code |
| **architect** | stack, data model, API contract, ADRs | `02-architecture/*` | source code |
| **ux-designer** | design system, tokens, screen specs | `03-design/*` | source code |
| **frontend** | client code | `src/client/**`, `app/**` | server code, contracts |
| **backend** | server code, migrations | `src/server/**`, `prisma/**` | client code, contracts |
| **qa** | verification | `05-qa/*`, failing tasks in `tasks.json` | feature code (files bugs, doesn't fix them) |
| **security** | threat review | `05-qa/security-review.md`, tasks | feature code |
| **devops** | CI, containers, deploy | `Dockerfile`, `.github/**`, `06-devops/*` | app logic |
| **seo** | technical SEO + content briefs | metadata/sitemap/schema in source, `07-growth/seo-brief.md` | app logic |
| **marketer** | positioning, copy, launch plan | `07-growth/positioning.md`, `landing-copy.md`, `launch-plan.md` | source code |
| **social** | content calendar, post drafts | `07-growth/social-calendar.md`, `posts/` | source code |

**Three roles you didn't list, added deliberately:**

- **architect** — without a single owner of the stack and data model, Frontend and Backend each invent their own and the code doesn't compose. This is the highest-value addition.
- **qa** — the difference between a working project and plausible-looking code. Its job is to *run things*, not write a test plan document.
- **security** — cheap, and catches the auth/secrets/injection class before it ships.

**On the non-engineering roles, honestly:** Marketer and Social produce genuinely useful artifacts (positioning, landing copy, a 30-day calendar, drafted posts) but cannot distribute anything, and I'm not going to build them to. SEO is the strongest of the three because most of its work is real code — metadata, structured data, sitemaps, canonical URLs, Core Web Vitals.

### Model and effort

Agents ship with no `model:` field, so they inherit your session model. A plugin setting will let you downgrade the cheap roles (`social`, `marketer`) to a smaller model without editing agent files.

---

## 9. Contract freezing

The single biggest failure mode in a multi-agent build is silent contract drift: Backend renames a field, Frontend keeps using the old name, and neither notices until QA — or worse, until you do.

**Mechanism:**

1. Each contract is hashed into `state.contracts[*].sha256` and set `frozen: true` at the gate of the phase that authored it. **Architecture gate:** `stack.md`, `data-model.md` — every dev agent treats `stack.md` as non-negotiable, so nothing may edit it silently. **Design gate:** `api-contract.yaml`, `tokens.json`, `motion-spec.md` — the API freezes one gate late on purpose, because UX routinely surfaces screen needs that bend it and that's the last cheap moment to bend it.
2. A `PreToolUse` hook matching `Write|Edit` checks whether the target path is a frozen contract. If so, it returns `permissionDecision: "deny"` with a reason pointing at `/oma:change`.
3. To change a contract, an agent records the request in `contract_changes` and stops. The orchestrator surfaces it to you with an impact analysis: which tasks, which files, which agents need to re-run.
4. On approval, `/oma:change` bumps the contract version, re-hashes, and files re-work tasks for every affected agent.

This turns the worst failure mode into an explicit, visible decision.

---

## 10. The QA loop

This is what separates a repository that runs from one that merely looks finished.

```
/oma:phase qa
  │
  ├─ oma-qa runs the real commands: install → typecheck → lint → build → test
  │  and writes the actual output to .oma/05-qa/reports/run-N.md
  │
  ├─ green? → phase status = awaiting_gate → done
  │
  └─ red?  → parse failures → append tasks to tasks.json with an owner
            → orchestrator dispatches oma-frontend / oma-backend on those tasks only
            → re-run QA (iteration += 1)
            → after 3 iterations without full green: STOP, escalate to you
              with the failure list and what was tried
```

Two rules that matter:

- **QA never fixes.** It files. Separating the agent that judges from the agent that repairs prevents the "I'll just relax the assertion" failure.
- **The loop is bounded.** Three iterations, then it stops and asks. An unbounded repair loop is the fastest way to burn a large amount of tokens producing nothing.

**Anti-fabrication:** a `PostToolUse` hook on `Bash` records exit codes. QA's report must cite a recorded command. A claim of "tests pass" with no corresponding recorded successful test run is caught at the gate.

---

## 11. Commands

| Command | Does |
|---|---|
| `/oma:init "<idea>"` | Creates `.oma/`, writes `brief.md`, asks 5–8 clarifying questions, picks a stack profile |
| `/oma:run` | Advances one phase from wherever you are, then stops at the gate |
| `/oma:status` | Current phase, gate states, open blocking questions, QA status, next action |
| `/oma:phase <name>` | Re-runs a specific phase with your correction as input |
| `/oma:gate approve \| reject "<why>"` | Passes or bounces the current phase |
| `/oma:change "<request>"` | Opens a change request against a frozen contract, with impact analysis |
| `/oma:task add \| reassign \| close` | Manual backlog control |
| `/oma:ship` | Final assembly: README, handoff report, deploy checklist |

`/oma:run` is the main loop. Realistic usage is: `/oma:run` → read → `/oma:gate approve` → `/clear` → `/oma:run` → repeat.

---

## 12. Hooks

All in `hooks/hooks.json`, because plugin agents ignore agent-level hooks.

| Event | Matcher | Purpose |
|---|---|---|
| `SessionStart` | — | If `.oma/state.json` exists, inject a 5-line status summary so a fresh session knows where it is |
| `PreToolUse` | `Write\|Edit` | **Contract freeze guard.** Deny writes to frozen contracts |
| `PreToolUse` | `Write\|Edit` | **Boundary guard.** Warn when an agent writes outside its declared ownership |
| `PostToolUse` | `Bash` | Record command + exit code to `.oma/log/commands.jsonl` for QA anti-fabrication |
| `PreToolUse` | `Bash` | **Deploy guard.** Deny deploy/publish commands; ask on `git push` and remote repo creation (M4) |
| `SubagentStop` | — | Verify the agent appended a handoff record; if not, flag it |
| `Stop` | — | If phase status changed, print the next suggested command |

The deploy guard is what makes "OMA does not deploy" a property of the system
rather than a promise in a prompt. It is active only inside an OMA project, it
denies production-affecting commands outright (`vercel deploy`, `fly deploy`,
`docker push`, `npm publish`, `terraform apply`, `kubectl apply`, …), and it
*asks* rather than denies on `git push` and `gh repo create` — publishing the
user's own source is a reasonable thing for them to want and an unreasonable
thing for an agent to decide alone. Like every other hook it fails open.

---

## 13. Default stack profile

`stacks/web-app-default.md` — used unless you say otherwise at intake.

- **Framework:** Next.js (App Router) + TypeScript, strict mode
- **Styling:** Tailwind CSS, tokens generated from `tokens.json`
- **Motion:** Framer Motion + Lenis, values read from `motion-spec.md`; `prefers-reduced-motion` honored everywhere
- **Database:** PostgreSQL via Prisma (SQLite override for local-only projects)
- **Auth:** cookie sessions, httpOnly + SameSite, argon2 password hashing
- **Validation:** Zod at every trust boundary, shared between client and server
- **Testing:** Vitest (unit) + Playwright (e2e on critical paths only)
- **Lint/format:** ESLint + Prettier, enforced in CI
- **CI:** GitHub Actions — install, typecheck, lint, test, build
- **Container:** multi-stage Dockerfile, non-root user

Opinionation is the point. Agent prompts can reference concrete APIs and idioms, which produces materially better code than "use whatever the user picked." Overriding at intake (`/oma:init "…" --stack django`) makes the Architect interview you instead, at some cost to output quality — which the doc will say plainly.

---

## 14. Context strategy

- The orchestrator reads only `state.json` and a phase index. Never a full artifact.
- Agents write long output to files; they return ≤3 sentences to the caller.
- Each phase is fresh subagent contexts, so per-phase context is bounded regardless of project size.
- `/clear` between phases is documented as the recommended workflow, and safe because nothing lives in conversation.
- `tasks.json` is chunked: build agents receive a slice of tasks, not the whole backlog.

---

## 15. Failure modes and mitigations

| Failure | Mitigation |
|---|---|
| Agent claims done without verifying | `SubagentStop` artifact check; QA runs real commands; command log |
| Contract drift between Frontend and Backend | Freeze + `PreToolUse` deny + explicit change requests |
| Infinite QA repair loop | Bounded at 3 iterations, then escalate |
| Scope creep | Every task must cite a `REQ-###`; PM owns non-goals; tasks with no requirement are rejected |
| Agents inventing different stacks | `stack.md` is mandatory reading step 2 for every dev agent, and is a frozen contract from the Architecture gate |
| Pinned versions that don't compose | Architect proves the pin set in a throwaway install (install→typecheck→lint→build green) before `stack.md` freezes |
| Agent dies mid-dispatch, work lost | Slices capped at ~2 tasks; on death, re-dispatch scoped to the gap only, never the whole slice |
| Context exhaustion mid-build | Phase gates + disk state + `/clear` guidance |
| Agent edits another agent's files | Boundary guard hook + explicit `Never touches` in each agent |
| Token blowup on a bad premise | Per-phase gates catch a misread requirement in Discovery, before Build |
| Generic, lifeless UI | UX ships runnable mockups you approve *before* any code exists; tokens frozen |
| Build doesn't match the approved mockup | Mockup is the acceptance reference; both read the same `tokens.css` and `motion-spec.md` |
| Animation feels wrong in production though the mockup felt right | Motion defined as frozen tokens, not per-implementation taste |
| Agents spawning agents, unbounded | All dispatch stays in the main thread (§6.5) |

---

## 16. Build plan

| Milestone | Contents | Why this order |
|---|---|---|
| **M1 — Skeleton** | `plugin.json`, `marketplace.json`, `state.json` schema, handoff schema, `/oma:init`, `/oma:status` | Nothing works until state and the bus exist |
| **M2 — Spec phases** | PM, Architect, UX agents + Discovery/Architecture/Design phases + gates + contract freeze + **the mockup pipeline** | Proves the gate + handoff mechanism on cheap phases, and gets you something to look at early |
| **M3 — Build & QA** | Frontend, Backend, QA agents + parallel build + the repair loop + hooks | The hard part and the real risk. Test on a real sample idea before going further |
| **M4 — Ops & Growth** | DevOps, Security, SEO, Marketer, Social + `/oma:ship` + the deploy guard | Additive; each is independent |
| **M5 — Brownfield** | `oma-archaeologist` + `00-archaeology` + scope modes + the audit guard | Inherits all the machinery above; only safe to build once that machinery is proven |
| **M6 — Distribution** | README, marketplace listing, worked example, troubleshooting, hook self-test | — |

**M6 status: built (v0.6.0).** `examples/ledgerly/` carries the complete 74-file
`.oma/` from a real run; `TROUBLESHOOTING.md` documents the failure modes hit
during validation; `scripts/selftest.sh` covers all six hooks in 41 behavioral
cases and runs in CI. Writing that self-test immediately found a real bug:
`session-start.sh` resolved `.oma/state.json` by relative path and was therefore
silent whenever the hook ran from anywhere but the project root — a hook that had
never been exercised in two years of design and three validation runs.

*Renumbered 2026-08-13.* Brownfield was specified in §18 as "post-v1" and built
as M5 once M4 was validated, which displaced the original M5. Distribution is
now M6, and two of its four items are still outstanding: a **worked example**
committed to the repo (the validation project lives in a scratch directory and
is lost when the session ends) and a **troubleshooting guide** for the failure
modes that are normal at this scale — agents dying mid-dispatch, a phase stuck
at `blocked`, resuming after a week away.

**M4 status: built and validated (v0.4.1).** Phases 06-devops, 07-growth and 08-ship ship
playbooks; the five agents, six artifact templates, the `harden` task stage,
`state.security` / `state.ship`, and the deploy-guard hook are in place. Not yet
validated end-to-end on a real project the way M3 was — the mechanisms are
individually sound and the deploy guard is behaviorally tested, but the phases
have not been run against a live build.

*Updated after the M4 validation run:* phases 06–08 were run end to end on the
Ledgerly project through to a tagged `oma/ship`. Two defects were found and
fixed — `state.security` missing on projects initialized before 0.4.0, and the
Growth phase introducing an environment variable that nothing re-checked against
`env.template`. The security agent was mutation-tested with an injected IDOR and
caught it, graded it correctly, and filed it. The harden loop's *dispatch* step
remains unexercised, because the application had no critical or high findings of
its own.

**M3 is where this succeeds or fails.** Everything before it is document generation, which Claude does reliably. I'd validate M3 against a real project (e.g. "invoicing app for freelancers") and only build M4 once the loop reliably produces a green build.

---

## 17. Decisions

Resolved 2026-08-11.

| # | Decision | Detail |
|---|---|---|
| 1 | **Greenfield for v1** | Brownfield support designed as a post-M3 addition — see §18 |
| 2 | **Runnable HTML/CSS mockups** | Not images, not descriptions. Lenis + Motion + View Transitions, governed by a frozen `motion-spec.md` — see §7 |
| 3 | **Commit per phase** | Structured message, never pushes |
| 4 | **Name stays `oma`** | Commands `/oma:*`, agents `oma-<role>`. Note for the README: *oma* means "grandma" in German and Dutch — worth knowing before publishing |

### Git behavior in detail

One commit per phase, authored by the orchestrator, never by an individual agent — otherwise concurrent Frontend and Backend agents race on the index.

```
oma(03-design): design system, tokens, motion spec, 7 screen mockups

Requirements: REQ-001..REQ-014
Artifacts: .oma/03-design/
Contracts frozen: api-contract.yaml v1.2, tokens.json v1.0, motion-spec.md v1.0
Gate: approved by user
```

A tag is written at each gate (`oma/gate-03-design`), so rolling back a bad phase is `git reset --hard oma/gate-02-architecture`. The orchestrator never pushes, never force-pushes, and never touches a branch other than the current one.

---

## 18. Brownfield mode (post-v1)

You said new projects matter more, and I agree that's where v1 should land — but here's the design, because it's a smaller addition than it looks and it's what makes OMA useful on the work you already have.

The insight: the pipeline doesn't actually care whether `.oma/` artifacts were *authored* or *inferred*. If you can reverse-engineer `stack.md`, `data-model.md`, and `api-contract.yaml` from an existing codebase, every phase from Architecture onward works unchanged.

**One new agent, one new phase.**

`oma-archaeologist` runs as Phase 0.5 and reads the existing repo to produce the same artifacts a greenfield Architect would have written:

| Reads | Infers |
|---|---|
| `package.json`, lockfiles, config | `stack.md` — actual versions, not aspirational ones |
| schema/migrations/models | `data-model.md` |
| route handlers, controllers | `api-contract.yaml` (generated from real routes) |
| existing components, CSS | `tokens.json`, `components.md` — extracted from what's there |
| README, git log, comments | `adr/` — decisions already made, with the reasoning if recoverable |
| test files, CI config | baseline `qa` block in `state.json` |

**Three rules that make it safe:**

1. **Everything is marked `inferred: true`** and cannot be frozen until you review it. Inferred contracts are the highest-risk artifacts in the system — a wrong `data-model.md` poisons every phase downstream.
2. **It establishes a green baseline first.** Before proposing any change, it runs install/typecheck/lint/build/test and records the result. If the project is already red, that's reported as the starting condition — OMA must never be blamed for pre-existing failures, and must never "fix" them without being asked.
3. **Conventions are extracted, not imposed.** The default stack profile is *ignored* in brownfield mode. `stack.md` describes what the codebase actually does, and dev agents match existing patterns even where they'd choose differently. An agent that rewrites your working code in its preferred idiom is worse than useless.

**Scope modes** for brownfield, chosen at `/oma:init`:

- `extend` — add a feature. Discovery scoped to the new feature only, existing contracts read-only.
- `refactor` — improve structure with behavior frozen. The test suite is the contract; QA's job is proving nothing changed.
- `audit` — read-only. Produces findings and a prioritized backlog, writes no source code.

**Why after M3:** brownfield inherits the entire dispatch, gate, contract, and QA machinery. Building it before that machinery is proven means debugging two hard things at once. Once M3 is green, the archaeologist is roughly one agent and one phase definition.

**M5 status: built (v0.5.0).** `oma-archaeologist`, the `00-archaeology` phase,
the three scope modes, `state.mode`/`state.brownfield`, the baseline and audit
report templates, and the **audit guard** — a PreToolUse hook that denies every
write outside `.oma/` when scope is `audit`, making "read-only" a property of the
system rather than a promise in a prompt. The estimate above held: one agent and
one phase, plus the mode plumbing through init/run/gate/status and brownfield
sections in the playbooks whose behavior genuinely changes (01, 04, 05, 06, 08).

**Validated 2026-08-13 against ground truth.** The Ledgerly application was
stripped of `.oma/`, `CLAUDE.md`, the README, git history and every agent
attribution in a comment, then handed to the archaeologist as an unfamiliar
codebase. Scored against the originals: 17/17 API operations (verified by calling
them, not by reading), 5/5 entities and 24/24 scalar fields, 10/10 lockfile
versions, zero source files modified. It documented four self-contradictions in
the codebase without resolving any of them, and marked 17 artifacts `inferred`.

Two findings the greenfield run had missed: an endpoint present in code but
absent from the frozen contract, and a repository that does not work from a
fresh clone — the generated database client is gitignored with no `postinstall`,
so most tests fail until a manual step is run. The ship report had called it
green because the working directory already had the generated code. **Consequence
for the design: ship-time verification must install from clean, not trust the
working tree.**

---

## 19. Honest assessment

**Scope of the evidence: Next.js only.** Every validation run — M3, M4 and M5, greenfield and brownfield — used a single Next.js + TypeScript + Prisma application. The stack-agnostic machinery (gates, contracts, the handoff bus, the QA loop, the archaeologist's method) should carry to any stack; the default profile, the Framer Motion translation in the mockup pipeline, the SEO agent's metadata idioms and the DevOps container/CI templates are all written around Next.js and would need work elsewhere. Treat any non-Next.js run as unexplored territory.

For well-scoped applications — SaaS CRUD, marketing sites, dashboards, REST/GraphQL APIs, admin panels, internal tools — this produces a real, running, tested project. That claim rests entirely on the QA loop in §10 being real: actual commands, actual exit codes, failures fed back as tasks.

For novel algorithmic work, hard realtime systems, or anything requiring deep domain expertise, expect a strong scaffold and a clear plan that you finish yourself.

The failure mode to watch for is not bad code. It's *confident, complete-looking* output built on a misread requirement. Which is exactly why the Discovery gate exists, and why it's the one you should read most carefully.
