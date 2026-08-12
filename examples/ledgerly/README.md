# Worked example — Ledgerly

This is the complete `.oma/` workspace from a real OMA run: **74 files, 8 phases,
28 agent dispatches**, from a one-sentence idea to a tested application tagged
`oma/ship`.

Nothing here is illustrative or written for the README. It is the actual output,
including the parts that went wrong.

> **The idea it started from:** *"Invoicing app for freelancers who hate invoicing."*
>
> **What came out:** a Next.js + Prisma application, 191 unit tests and 11
> Playwright e2e tests passing, 10/10 requirements shipped, a security review, CI,
> a container, a deploy runbook, landing copy and a 30-day launch calendar.

The application source is not included — it's an unremarkable Next.js app, and
the point of this example is the paper trail, which is the part nobody else can
show you.

## Start here — five files worth your time

If you read nothing else, read these in order. They're where the system's
behavior is visible rather than described.

### 1. `01-discovery/prd.md` — requirements with stable ids

Every requirement gets a `REQ-###`. Every build task later cites one. A task that
cites no requirement is scope creep and gets rejected at the gate. This is the
vocabulary the whole run is conducted in.

Read `scope.md` beside it — the **out of scope** table is what stopped the
marketing agent, six phases later, from writing copy that implied features the
product doesn't have.

### 2. `05-qa/reports/run-1.md` — the one that justifies the architecture

QA found that **nine tasks (T-002…T-010) were marked `done` against acceptance
criteria naming vitest tests that did not exist.** The build agents had accepted
their own work.

Because QA is structurally forbidden from fixing anything, it filed rather than
quietly writing a token test suite. Run 2 then mutation-tested the resulting
suite with ten deliberate defects the backend agent had never named — all caught.

This is the failure mode the gates exist for: not bad code, but confident,
complete-looking output.

### 3. `02-architecture/adr/ADR-006-bigint-money-and-quantity-columns.md`

A frozen contract being changed, properly. QA found that the money columns
couldn't hold values the API contract accepts — which made ADR-001's portability
promise quietly false. The change ran through `/oma:change`: impact analysis,
your decision, a surgical edit, a new ADR, re-freeze at v1.1 with a new hash,
and rework tasks filed.

Compare it with `ADR-001` to see the original decision it corrects.

### 4. `03-design/mockups/index.html` — open this in a browser

```bash
python3 -m http.server 4173 -d 03-design/mockups
```

Eight runnable screens with real motion, produced **before any application code
existed**. Each screen has all five states — empty, loading, populated, error,
edge. This is what you approve at the Design gate, and what the frontend agent
is later held to.

`03-design/motion-spec.md` is the frozen token set that keeps the built app
feeling like the mockup.

### 5. `06-devops/security-review.md`

A security review that ran things rather than reading them. The cross-user
authorization probe took two accounts and ran 11 operations as user B against
user A's records — all 404, data byte-identical. It also *measured* a timing
oracle: sign-in responses in non-overlapping bands, 3.3–8.9 ms unregistered vs
18.9–20.9 ms registered.

Note the **"checked and clean"** section. A review that lists only problems is
indistinguishable from one that stopped early.

## The whole map

| Path | What it is |
|---|---|
| `01-discovery/` | PRD with `REQ-###` ids, scope boundary, personas, success metrics |
| `02-architecture/` | `stack.md` with proven version pins, data model, OpenAPI contract, **6 ADRs** |
| `03-design/` | design system, tokens, motion spec, 7 screen specs, **8 runnable mockups** |
| `04-build/tasks.json` | 29 tasks, each citing a requirement, with the command that proved it done |
| `05-qa/` | test plan and **3 evidence-based run reports** |
| `06-devops/` | security review, deploy runbook, environment template |
| `07-growth/` | positioning, landing copy, launch plan, calendar, **23 drafted posts** |
| `08-ship/ship-report.md` | what shipped, what didn't, what's known-broken |
| `log/handoffs.jsonl` | **28 records** — the entire inter-agent message bus |

## Read the message bus

```bash
python3 -c "
import json
for l in open('.oma/log/handoffs.jsonl'):
    r = json.loads(l)
    print(f\"{r['seq']:>3} {r['from']:<22} -> {','.join(r['to'])}\")
    print(f\"    {r['summary'][:120]}\")
"
```

Agents cannot talk to each other — each runs in an isolated context and returns
one summary. So they coordinate the way real teams do: through artifacts and a
log. Every line in that file is one agent handing work to the next.

Note the `assumptions` fields. Those are surfaced at gates, which is how a wrong
guess gets caught before it compounds.

## The honest parts

This example is more useful for what it admits than what it claims:

- **`08-ship/ship-report.md`** lists every known issue, every accepted security
  finding, and the requirements that were verified only by inspection.
- **T-029** is still open: an environment variable the Growth phase introduced
  that the DevOps template — written a phase earlier — never learned about.
  Unfixed, canonical URLs ship pointing at `localhost`.
- The project **was never deployed.** OMA writes the runbook; deploying is the
  user's credentials and the user's call.
- Three medium security findings were accepted rather than fixed, each named
  individually in the gate notes.
- Later, reading this same project as a stranger, the brownfield archaeologist
  found that **a fresh clone doesn't work** — the generated database client is
  gitignored with no `postinstall`. The ship report had called it green, because
  it was green in a working directory that already had the generated code. That
  defect is why `08-ship` now verifies from a clean clone.

A worked example that showed only successes would be marketing. These are the
things a real run produces.
