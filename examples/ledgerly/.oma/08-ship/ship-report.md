# Ship report — Ledgerly

Tiny invoicing app for freelancers: clients, line-item invoices, paid/unpaid
tracking, outstanding-totals dashboard.

Shipped 2026-08-13 · commit `7ece15c` · 8 phases · 28 agent dispatches

## Verdict

Ledgerly does what its PRD says and nothing more. All ten requirements ship,
verified by 191 unit tests and 11 end-to-end tests, with a clean typecheck,
lint, format and production build at ship time. It is a single-user ledger: it
records who owes what and whether they paid. It does not send invoices, take
payments, export PDFs, handle multiple currencies or support more than one user,
and each of those is a decision recorded in `scope.md`, not an omission.

**It has never been deployed.** The container was built and booted locally and
the runbook is written, but no production environment exists, no domain is
configured, and three medium security findings are open — none of which matters
for local use and all of which matter the moment a sign-in form is on the public
internet.

## Requirements

| REQ | Priority | Status | Verified by |
|---|---|---|---|
| REQ-001 Account authentication | must | shipped | `e2e/auth.spec.ts` + unit suite |
| REQ-002 Client management | must | shipped | unit suite, API probes |
| REQ-003 Invoice creation with line items | must | shipped | `e2e/invoice-flow.spec.ts`, server arithmetic tests |
| REQ-004 Send-ready invoice view | must | shipped | e2e + print-preview check |
| REQ-005 Paid/unpaid status tracking | must | shipped | `e2e/paid-lock.spec.ts` |
| REQ-006 Outstanding-totals dashboard | must | shipped | unit + QA run-3 |
| REQ-007 Invoice list with status filter | must | shipped | e2e + unit |
| REQ-008 Editing unpaid invoices | must | shipped | `e2e/paid-lock.spec.ts` (lock + revert) |
| REQ-009 Empty and error states | should | shipped | QA run-3 state sweep |
| REQ-010 Responsive layout | should | shipped | QA run-3 at 375px (was untested until run 3) |

**10 of 10 requirements shipped. None dropped, none partial.**

## Verification at ship time

Run on the tree as shipped, after the Growth phase changed source — not copied
from an earlier report:

| Check | Command | Exit | Result |
|---|---|---|---|
| typecheck | `npm run typecheck` | 0 | clean |
| lint | `npm run lint` | 0 | clean |
| format | `npm run format:check` | 0 | clean |
| build | `npm run build` | 0 | production build succeeds |
| unit | `npx vitest run` | 0 | 191 passed, 10 files |
| e2e | `npx playwright test` | 0 | 11 passed |

**Untested, honestly:** the app has never run under real concurrent use, never
against Postgres (SQLite only), and never on a hosted platform. Rollback has
been written but not exercised. The container's first boot was proven locally
on an empty volume; it has not been proven against a real persistent volume
after a platform restart.

## Known issues

| id | What | Why it's still here | Accepted at |
|---|---|---|---|
| T-029 | `NEXT_PUBLIC_SITE_URL` missing from `env.template` and the runbook | Found at the 07-growth gate; SEO introduced the variable one phase after DevOps wrote the template. **Fix before first deploy** or canonicals, OG tags and the sitemap ship pointing at `localhost:3000` | 07-growth gate |
| SEC-001 | No rate limit, throttle or lockout on auth endpoints (medium) | 21 credential attempts ran at full speed in 0.97s | 06-devops gate |
| SEC-002 | Sign-in timing discloses whether an email is registered (medium) | Non-overlapping bands: 3.3–8.9 ms unregistered vs 18.9–20.9 ms registered — defeats the contract's stated no-enumeration promise | 06-devops gate |
| SEC-003b | CSP is report-only, not enforced (medium, partial) | Headers shipped; enforcement needs a nonce in `src/proxy.ts`, which is application territory | 06-devops gate |
| SEC-004…008 | CSRF resting on `SameSite=Lax`, non-revocable sessions, signup email disclosure, length-only password policy, no body size cap (low) | Recorded, not fixed | 06-devops gate |

Nothing else is outstanding: 28 of 29 tasks are `done`, and the one `todo` is
T-029 above.

## Security posture

Reviewed 2026-08-12, round 1: **0 critical, 0 high, 3 medium, 6 low.**
SEC-003 (missing headers) and SEC-009 (`X-Powered-By`) were fixed in
`next.config.ts` and verified live. Dependency audit clean: 0 vulnerabilities
across 685 packages.

The check that mattered most came back clean: a **cross-user authorization
probe** ran 11 operations as user B against user A's invoice and client ids —
GET, PATCH, DELETE, status toggle, list, dashboard, and creating an invoice
against A's client — and every one returned 404 with A's data byte-identical
afterwards. Ownership scoping is enforced in the data layer, not in the UI.

Not covered by the review: infrastructure, the deploy platform's own
configuration, third-party services, and anything requiring credentials this
environment doesn't have.

## Contracts

| Contract | Version | sha256 | Path |
|---|---|---|---|
| api | 1.0 | `98f0cc93…` | `.oma/02-architecture/api-contract.yaml` |
| data_model | 1.1 | `e6054a3d…` | `.oma/02-architecture/data-model.md` |
| tokens | 1.0 | `08c5cb2f…` | `.oma/03-design/tokens.json` |
| motion | 1.0 | `30e25267…` | `.oma/03-design/motion-spec.md` |

All four hash-matched at every gate from Design onward. `data_model` is at 1.1
because of one deliberate change through `/oma:change` — see D-003.

## Decisions

| id | Decision | ADR |
|---|---|---|
| D-001 | SQLite-only assumptions confined to `src/server/db.ts` (cuid2 ids, no raw SQL, integer money, DB-backed sessions) so a Postgres move stays possible | ADR-001 |
| D-002 | Pin the latest package set that *composes*, not the latest of each: typescript 7.0.2→6.0.3, eslint 10.8.1→9.39.5 | — |
| D-003 | Widen money columns to `BigInt`: the `Int` columns could not hold values the frozen API accepts, which made ADR-001's portability promise quietly false | ADR-006 |

**Caveat on ADR-001, from the DevOps review:** "swap the adapter" understates
the Postgres move. `migration_lock.toml` pins sqlite, the BigInt migration is a
SQLite PRAGMA table-redefine, and the data needs a hand-written cuid2-preserving
copy script. Read `.oma/06-devops/deploy-runbook.md` before believing the
migration is cheap.

## Open questions

| id | For | Question |
|---|---|---|
| Q-002 | ux-designer | Dashboard stat captions need per-status counts the frozen `/dashboard` shape lacks |
| Q-003 | ux-designer | Two <640px layout deviations from the mockups, from the responsive row-card treatment |
| Q-004 | user | (superseded by D-003 — money columns are now BigInt) |
| Q-005 | user | Frozen-contract worst case (100 lines × 1e14 cents) exceeds `Number.MAX_SAFE_INTEGER` on the JSON wire |

Plus, from this phase: CSP enforcement needs an application-side nonce, and the
one-machine constraint is load-bearing (better-sqlite3 is a single writer) — that
is a limit, not advice.

## Deploy checklist

OMA has not deployed anything and will not. Full procedure in
`.oma/06-devops/deploy-runbook.md`.

- [ ] **Fix T-029 first** — set `NEXT_PUBLIC_SITE_URL` at *build* time
- [ ] Environment variables set from `.oma/06-devops/env.template`
- [ ] Persistent volume provisioned for the SQLite file
- [ ] Migrations run as a release step, never in the image build
- [ ] Health endpoint returns 200 and a signup round-trips
- [ ] Rollback command known and to hand (and note it does not undo a migration)
- [ ] Single machine only — do not scale to 2+ instances
- [ ] Consider closing SEC-001 and SEC-002 before pointing traffic at sign-in

## Growth assets

| File | What | Outstanding |
|---|---|---|
| `07-growth/seo-brief.md` | page inventory, keyword map, 3 filed findings | 2 `[[TODO]]` |
| `07-growth/positioning.md` | one-liner, ICP, alternatives, objections, voice rules | 0 |
| `07-growth/landing-copy.md` | paste-ready page + claim-to-source appendix | 12 `[[TODO]]` — pricing and lockout must not ship blank |
| `07-growth/launch-plan.md` | asset checklist, channel sequence, week-one metrics | 9 `[[TODO]]` |
| `07-growth/social-calendar.md` | 30 days, 23 posts | 8 `[[TODO]]` |
| `07-growth/posts/` | 23 real drafts (X 12, LinkedIn 6, Reddit 2, HN 1, IH 1) | 35 `[[TODO]]` |

**66 `[[TODO]]`s total**, plus 7 screenshots/recordings the user must produce.
Every one marks a fact only the user has — no placeholder was filled with a
plausible invention.

There is also no public landing route: `/` redirects to `/dashboard`. The
landing copy exists; the page to put it on does not.

## What to do next

1. **Fix T-029**, then deploy per the runbook. The copy and the calendar are
   waiting on a live URL.
2. **Build the public landing page** at `/` and paste in `landing-copy.md`. The
   SEO brief calls this worth more than all the metadata combined, and it's right.
3. **Fill the two blocking TODOs** — pricing, and what happens to a locked-out
   account — before anyone else sees the copy.
4. **Close SEC-001 and SEC-002** before launch day points five platforms at the
   sign-in form.

## How to pick this up later

Everything is on disk. `.oma/` holds the reasoning, not just the output:
requirements in `01-discovery/`, decisions in `02-architecture/adr/`, the design
system and runnable mockups in `03-design/`, verification evidence in
`05-qa/reports/`, the security review in `06-devops/`, and the complete
inter-agent history in `log/handoffs.jsonl` — 28 records, every dispatch.

`/oma:status` reconstructs the whole picture in a fresh session.
