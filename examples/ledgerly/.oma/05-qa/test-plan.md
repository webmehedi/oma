# Test plan — Ledgerly

> Authored by oma-qa at QA iteration 1 (2026-08-12). This plan is the standing
> definition of what gets verified and how. Stages come from
> `.oma/02-architecture/stack.md`; acceptance criteria come from
> `.oma/01-discovery/prd.md`; endpoint behaviour is judged against the frozen
> `.oma/02-architecture/api-contract.yaml`, never against what the code does.

## Pipeline commands

Run in this order every QA run. Later stages still run when an earlier one
fails — only a failed `install` blocks the rest.

| Stage | Command | Notes |
|---|---|---|
| install | `npm install` (iteration 1: `rm -rf node_modules` first) | clean install proves the lockfile, not a warm cache |
| typecheck | `npm run typecheck` (`tsc --noEmit`) | TS 6.0.3 strict, per decision D-002 |
| lint | `npm run lint` (`eslint .`) | eslint 9.39.5, per decision D-002 |
| build | `npm run build` (`next build`) | production build; warnings are `warn`, not `fail` |
| unit | `npm test` (`vitest run`) | see "Known gap: no unit suite" below |
| e2e | `npx playwright test` | Playwright 1.62.1, chromium; own `next start` on :3411 |

Beyond the pipeline, each run also performs:

- **Contract conformance** — `curl` probes of the enveloped API: status codes,
  envelope shape, the 8-code error registry, auth rejection without a cookie,
  and cross-account isolation.
- **Requirements sweep** — every `must` REQ's acceptance criteria mapped to a
  test, a command, or a page load; anything unprovable is recorded `untested`.
- **Mockup parity spot-check** — 2–3 built screens against
  `.oma/03-design/mockups/`: do the real states render, are tokens used, does
  motion respect `prefers-reduced-motion`.

## Test harness

- `playwright.config.ts` (repo root) — QA-owned. Single worker (`workers: 1`)
  because SQLite via better-sqlite3 is a synchronous single writer; parallel
  workers would produce write contention that looks like product flake.
  `webServer` runs `npx next start -p 3411` against the existing build, so e2e
  exercises the same artifact the `build` stage produced, not a dev server.
- `e2e/helpers.ts` — per-test account factory. Every test signs up a fresh
  account with a unique email (`qa-<slug>-<timestamp>-<rand>@example.com`), so
  tests share a database file without sharing state. Account isolation is a
  product guarantee (REQ-001) that the suite leans on deliberately: if
  isolation broke, these tests would start interfering, which is itself the
  signal.
- No fixture seeding through Prisma. Tests drive the product through its own
  UI and API, because a fixture that bypasses the service layer verifies a
  database, not an application.

## Critical-path e2e scope

Three specs only. This suite is a smoke test of the paths whose failure means
the product does not work at all — not a coverage instrument. Exhaustive e2e
is explicitly rejected: it is slow, it is the flakiest layer, and it would
duplicate assertions that belong in the unit/integration suite that does not
yet exist.

### `e2e/auth.spec.ts` — REQ-001

| Case | Asserts |
|---|---|
| signed-out redirect | `/dashboard`, `/invoices`, `/clients` all land on `/signin` |
| signup → dashboard | new account signs up and the dashboard renders |
| signout → signin | sign out clears the session; the protected page bounces again |
| signin round-trip | the same credentials sign back in |
| wrong password | inline error banner, still on `/signin`, no session created |

### `e2e/core-loop.spec.ts` — REQ-002, REQ-003, REQ-004, REQ-005, REQ-006

The PRD's one paragraph that matters: create client → create invoice with line
items → view send-ready detail → mark paid.

| Case | Asserts |
|---|---|
| create client | client appears in the list with invoice count 0 |
| create invoice | two line items; the live total updates in the form before save |
| sequential number | the saved invoice carries `INV-0001` |
| send-ready detail | number, dates, client name, both line rows, and the total render |
| print-clean | under `emulateMedia({ media: 'print' })` the app nav and `.no-print` action bar are hidden (REQ-004) |
| mark paid | one click on the detail flips the badge to Paid without a reload, and a paid date appears |
| dashboard reflects | outstanding drops to 0 and paid-this-month carries the invoice total |

### `e2e/paid-lock.spec.ts` — REQ-005, REQ-008

| Case | Asserts |
|---|---|
| edit affordance locked | on a paid invoice the Edit control is `aria-disabled` and the lock reason is shown |
| delete affordance locked | Delete is `aria-disabled`; no confirm dialog opens |
| edit URL locked | navigating directly to `/invoices/{id}/edit` renders the `INVOICE_PAID_LOCKED` message, not a form |
| revert unlocks | marking unpaid restores a working Edit link and clears the paid date |

## REQ → verification map

| REQ | Priority | Verified by |
|---|---|---|
| REQ-001 Authentication | must | `e2e/auth.spec.ts` + curl isolation probes (account B cannot read/mutate account A) |
| REQ-002 Client management | must | `e2e/core-loop.spec.ts` (create, count) + curl (patch, empty-name 400, `CLIENT_HAS_INVOICES`) |
| REQ-003 Invoice creation | must | `e2e/core-loop.spec.ts` (line items, live total, `INV-0001`) + curl (server-computed cents, rounding, zero-items/negative-price rejection) |
| REQ-004 Send-ready view | must | `e2e/core-loop.spec.ts` detail assertions + the print-media assertion |
| REQ-005 Paid/unpaid | must | `e2e/core-loop.spec.ts` mark-paid + `e2e/paid-lock.spec.ts` revert + curl idempotency probe |
| REQ-006 Dashboard | must | `e2e/core-loop.spec.ts` totals + curl `/api/dashboard` arithmetic probe |
| REQ-007 Invoice list filter | should | curl (`?status=`, pagination meta); URL-state filtering is source-inspected, not e2e'd |
| REQ-008 Editing unpaid | should | `e2e/paid-lock.spec.ts` + curl (PATCH/DELETE 409 on paid, number non-reuse) |
| REQ-009 Empty/error states | should | curl error envelopes + source inspection of the empty-state components |
| REQ-010 Responsive | should | source inspection of the stack-mode CSS; **not** e2e'd (see below) |

## Deliberately untested, and why

- **Responsive layout (REQ-010).** Viewport screenshots are the highest-noise,
  lowest-signal e2e a suite can carry, and the criterion ("no horizontal
  scrolling at 375px") is a judgment call a human makes in a second. Spot-check
  by inspection; revisit only if a fix lands in the layout code.
- **Print output fidelity (REQ-004, second half).** The suite proves the print
  stylesheet hides app chrome. Whether the result is *one page per invoice* is
  a rendering property Playwright cannot assert cheaply; it stays a manual
  check.
- **Invoice edit-and-save round-trip (REQ-008 first criterion).** Covered by
  the API probe. Adding it to e2e would double the form's runtime for an
  assertion the contract probe already makes.
- **Pagination UI beyond page 1 (REQ-007).** Seeding 26+ invoices through the
  UI costs more than the criterion is worth; the API's `meta` is probed
  directly instead.
- **Motion values.** Durations and easings are asserted by the design gate, not
  by a test runner. The suite checks only that reduced-motion is honoured
  structurally.

## Known gap: no unit suite

`vitest` is pinned and `npm test` is wired, but the repo contains **zero test
files**. Nine build tasks (T-002 … T-010) name "a vitest integration test" in
their acceptance criteria; all nine were instead proven with `curl` against a
dev server, disclosed honestly in the build handoffs. Those proofs were real,
but they are not repeatable and they do not run in CI — which stack.md
specifies as `install → typecheck → lint → test → build`.

This plan does **not** treat the e2e suite as a substitute. E2E covers three
paths; the missing suite would cover the service-layer edge cases (rounding,
sliding session expiry, ownership checks, month boundaries) that e2e is the
wrong instrument for. The gap is filed as a task, not absorbed here.
