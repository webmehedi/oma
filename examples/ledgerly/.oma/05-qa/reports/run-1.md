# QA report — run 1

- **Date:** 2026-08-12T09:30:00Z
- **Iteration:** 1 of 3
- **Commit state:** `1d32827`

> Every result row cites the actual command run. Claims without a corresponding
> entry in `.oma/log/commands.jsonl` are fabrications — the log is the authority.

## Pipeline

| Check | Command | Exit | Verdict |
|---|---|---|---|
| install | `rm -rf node_modules && npm install` | 0 | **pass** — 567 packages, 0 vulnerabilities |
| typecheck | `npm run typecheck` (`tsc --noEmit`) | 0 | **pass** |
| lint | `npm run lint` (`eslint .`) | 0 | **pass** — no warnings emitted |
| build | `npm run build` (`next build`) | 0 | **pass** (1 warning, see below) |
| unit | `npm test` (`vitest run`) | 1 | **fail** — 0/0; "No test files found" |
| e2e | `npx playwright test` | 0 | **pass** — 11/11 |

Typecheck and lint were re-run after the new `e2e/` files and
`playwright.config.ts` landed (tsconfig's `**/*.ts` include covers them); both
still exit 0.

**Build warning (`warn`, not filed):** Turbopack reports that a dynamic
filesystem path in `src/server/db.ts` causes whole-project tracing, which
bloats a deployed server bundle. It does not fail the build and has no runtime
effect on this SQLite-file deployment. Worth a look if this is ever
containerised, but it is not a spec violation.

**E2E authoring note (transparency):** the suite failed on its first two runs.
All three initial failures were bugs in the tests I had just written, not in
the product — an unscoped `getByRole('alert')` colliding with Next's route
announcer, a Playwright actionability refusal on an `aria-disabled` button,
and a helper regex where `/invoices/<id>` also matched `/invoices/new` and
captured the literal id `"new"`. Each was fixed in test code only; no
application file was touched. The third run passed 11/11 clean. Recording this
because a suite that only ever went green on the first try is the kind of
claim worth being able to check.

## Failures

### F-1: no unit or integration test suite exists at all
- **Where:** repo-wide; `npm test`
- **Repro:** `npm test`
- **Output:**
  ```
  RUN  v4.1.10 .../oma-e2e
  No test files found, exiting with code 1
  include: **/*.{test,spec}.?(c|m)[jt]s?(x)
  exclude:  **/node_modules/**, **/.git/**
  ```
  `find src prisma -name "*.test.*" -o -name "*.spec.*"` returns nothing.
- **Why it matters:** nine build tasks (T-002 … T-010) name "a vitest
  integration test" in their acceptance criteria and were marked `done`. None
  exists. The build agents disclosed this honestly in handoffs seq 6, 8, 10 and
  12 and substituted `curl` proofs against a dev server — real verification,
  but not repeatable and not in CI. `stack.md` specifies CI as
  `install → typecheck → lint → test → build`, so this stage fails every run.
  I re-proved the underlying behaviour by curl this session (all green, see
  below), so this is a missing regression net rather than a suspected bug.
- **Probable owner:** oma-backend — all nine tasks are backend-owned and the
  uncovered surface is the service layer.
- **Filed as:** T-021

### F-2: React hydration mismatch from a module-level counter in LineItemEditor
- **Where:** `src/components/LineItemEditor.tsx:26-32` (`let draftSequence = 0`),
  consumed as `data-li-key` at line 133 and as a `querySelector` focus target at
  line 88
- **Repro:** `npx next dev -p 3421`, then load `/invoices/new` **twice**
- **Output:**
  ```
  [error] A tree hydrated but some attributes of the server rendered HTML
  didn't match the client properties. This won't be patched up.
    <div className="LineItemEditor-module___tPJ2W__row"
  +   data-li-key="li-1"
  -   data-li-key="li-2"
  ```
- **Mechanism:** the counter lives in module scope. The server module instance
  persists across requests and keeps incrementing; the client module starts
  fresh at 0. First load matches by luck; the second diverges.
- **Honest scope:** this does **not** reproduce against the production build —
  `/invoices/new` is statically prerendered, so the server value is frozen and
  my probe saw `li-1` with a clean console on three consecutive loads. The
  defect is latent, not active. It still deserves the fix: React states the
  attribute "won't be patched up", and a stale `data-li-key` silently breaks the
  focus-after-add-row behaviour that queries on it.
- **Probable owner:** oma-frontend — `src/components/` is frontend territory and
  they flagged it themselves in handoff seq 15 asking for this ticket.
- **Filed as:** T-022

### F-3: raw Zod default text leaks into VALIDATION_FAILED details
- **Where:** `src/shared/schemas/common.ts:25` (`invoiceStatusSchema`);
  `src/shared/schemas/invoices.ts:127` (`page`)
- **Repro:** `curl -b cookies "http://localhost:3401/api/invoices?status=bogus"`
- **Output:**
  ```
  {"details":{"status":"Invalid option: expected one of \"unpaid\"|\"paid\""}}
  {"details":{"page":"Too small: expected number to be >=1"}}
  {"details":{"page":"Invalid input: expected number, received NaN"}}
  ```
  Compare the authored style used everywhere else in the same sweep:
  `"Description is required."`, `"Quantity must be greater than zero."`,
  `"Enter a date as YYYY-MM-DD."`, `"Enter a valid email address."`
- **Why it matters:** REQ-009 requires human-readable inline messages, and the
  contract describes `details` as field → message safe to render. Three strings
  out of a codebase-wide convention of authored prose — an oversight, not a
  design choice. Low severity: the UI never submits these values, so they
  surface only on a hand-edited URL.
- **Probable owner:** oma-backend — `src/shared/schemas/` is backend-written.
- **Filed as:** T-023

### F-4: `prettier --check` fails on 28 pre-existing files
- **Where:** repo-wide
- **Repro:** `npm run format:check`
- **Output:**
  ```
  [warn] Code style issues found in 30 files. Run Prettier with --write to fix.
  ```
  30 at the moment of measurement, 2 of which were my own new `e2e/` files; I
  formatted mine, leaving **28 pre-existing**: `CLAUDE.md`, `package.json`,
  6 under `src/app`, 13 under `src/components`, `src/server/env.ts`, 3 under
  `src/server/services`, 3 under `src/shared`.
- **Why it matters, mildly:** `stack.md` pins prettier as "format, never argued
  with" and ships a `format:check` script, but it is **not** in the CI chain
  `stack.md` specifies, so nothing gates it. oma-frontend deferred it
  deliberately in handoff seq 15 to keep the T-020 diff readable. This is that
  deferred pass, not a new complaint.
- **Probable owner:** oma-frontend — most files are frontend territory, though
  `src/server/*` and `src/shared/*` are backend's; `npm run format` fixes all of
  it in one command.
- **Filed as:** T-024

### Assumptions hunted and cleared (no task filed)

The build handoffs' `assumptions` lists were the hunting ground. These were
checked and found correct, so they are recorded rather than filed:

- **"tasks.json says 422, the contract says 400; the contract wins"** (seq 6, 8,
  10). Correct call — the frozen registry maps `VALIDATION_FAILED` to 400, and
  every probe returned 400. The stale `422` wording survives in T-005/006/007/
  008/009 acceptance text; T-021's acceptance says to assert 400.
- **Paid→paid idempotency does not move `paidDate`** (seq 8). Verified: a repeat
  call carrying `2026-01-01` left `paidDate` at `2026-08-12`.
- **Status endpoint intentionally has no paid-lock** (seq 8). Correct per
  REQ-005 — reverting is how an invoice unlocks; verified end to end.
- **Deleted invoice numbers are never reused** (seq 10, ADR-004). Verified:
  deleted INV-0002, next create was INV-0003.
- **Signout is guarded and returns 401 without a cookie** (seq 6). Verified.
  Note the contract documents only a 200 for `/auth/signout`; the global
  `security` block and the prose ("all endpoints except signup/signin") make
  401 correct. A documentation gap in the contract, not a code defect — not
  filed, since the contract is frozen and the behaviour matches its prose.
- **No assertion was weakened to pass.** `git log` shows no test files ever
  existed to weaken, and no `.skip`/`.only`/`@ts-expect-error`/`eslint-disable`
  appears in `src/`. Nothing to report under this heading.

## Contract conformance spot-check

Probed against `next start` on :3401 (the production build), two accounts,
`curl` with cookie jars. All against the frozen `api-contract.yaml`.

**Envelope and error registry — all 8 codes exercised, all conformant:**

| Probe | Expected | Got |
|---|---|---|
| `GET /dashboard`, `/clients`, `/invoices`, `/auth/me`, `POST /auth/signout` without cookie | 401 `UNAUTHENTICATED` | 401 `UNAUTHENTICATED` ✔ (all five) |
| `POST /auth/signup` password `"short"` | 400 `VALIDATION_FAILED` + `details` | 400, `details.password` ✔ |
| `POST /auth/signup` duplicate (case-differing) email | 409 `EMAIL_TAKEN` | 409 ✔ — `QA-Alpha@Example.com` then `qa-alpha@example.com` collided, confirming server-side lowercasing |
| `POST /auth/signin` wrong password | 401 `INVALID_CREDENTIALS` | 401 ✔ |
| `POST /clients` name `"   "` | 400 `VALIDATION_FAILED` | 400, `details.name` ✔ (trim enforced) |
| `DELETE /clients/{id}` with invoices | 409 `CLIENT_HAS_INVOICES` | 409 ✔ |
| `PATCH` / `DELETE /invoices/{id}` on a paid invoice | 409 `INVOICE_PAID_LOCKED` | 409 ✔ (both) |
| `POST /invoices` unknown `clientId` | 404 `NOT_FOUND` "Client not found." | 404, exact message ✔ |

**Shape and arithmetic conformance:**

- `POST /invoices` with the contract's own example body returned the contract's
  own example figures: `amountCents` 150000 + 112500, `totalCents` 262500,
  `displayNumber` `"INV-0001"`, `status` `"unpaid"`, `position` 0/1, embedded
  `client`, `issueDate`/`dueDate` as `YYYY-MM-DD`. Every required field of
  `Invoice` present.
- Round-half-up per line (ADR-003): quantity `0.333` × `999` cents =
  332.667 → **333**. Correct.
- `issueDate` omitted defaulted to today UTC (`2026-08-12`). Correct.
- `GET /invoices` returned `meta: {page:1,pageSize:25,total:N}` — `pageSize` is
  the contract's `const: 25`.
- `GET /dashboard` arithmetic: with one paid invoice (262500) and one unpaid
  (333), returned `outstandingCents: 333`, `paidThisMonthCents: 262500`,
  `invoiceCount: 2`, `recentInvoices` sorted issueDate desc. Exact.
- Status toggle response is an `InvoiceSummary`, not a full `Invoice` — matches
  the contract, and is what lets the UI update without a reload (REQ-005).

**Account isolation (REQ-001), the probe that matters most:** account B, freshly
created, was pointed at every one of account A's resources.

| B → A's resource | Expected | Got |
|---|---|---|
| `GET /clients` | `[]` | `[]` ✔ |
| `GET /invoices` | `[]`, total 0 | ✔ |
| `GET /invoices/{A's id}` | 404 `NOT_FOUND` (never 403 — no existence leak) | 404 ✔ |
| `GET /clients/{A's id}` | 404 | 404 ✔ |
| `POST /invoices/{A's id}/status` | 404 | 404 ✔ |
| `DELETE /invoices/{A's id}` | 404 | 404 ✔ |
| `GET /dashboard` | all zeroes | ✔ |

**Session cookie (ADR-002):** `Set-Cookie` on signup carried `HttpOnly`,
`Path=/`, `Secure` (production build), `Max-Age=2592000` (30 days), and an
opaque 43-char base64url token — not a JWT. Matches `stack.md` exactly.

### Mockup parity spot-check

- **Design tokens — exact parity.** Custom-property names declared in
  `src/app/globals.css` versus `.oma/03-design/mockups/tokens.css`: **81 vs 81,
  set difference empty in both directions.** No token was invented or dropped.
- **No hardcoded colours.** `grep -rnoE '#[0-9a-fA-F]{6}' src` outside
  `globals.css` returns nothing — every colour routes through a token.
- **Empty states are real components, not blank divs.** `EmptyState` is wired on
  all three list surfaces (`clients-screen.tsx:303`, `invoices-screen.tsx:304`,
  `dashboard-screen.tsx:399`). Verified rendering live: a fresh account's
  dashboard shows "No invoices yet" plus a CTA link (asserted in
  `core-loop.spec.ts`), and the clients empty-state CTA is the path the e2e
  helper actually clicks to create the first client.
- **Reduced motion is honoured structurally.** `globals.css:162` clamps
  animation/transition durations under `prefers-reduced-motion: reduce`, and 12
  components consult `useReducedMotion()` to skip transforms rather than merely
  shortening them.
- **Print stylesheet is real and asserted.** `globals.css:471` hides `.no-print`
  and `.app-nav` and strips the document's border/shadow. `core-loop.spec.ts`
  asserts it under `emulateMedia({media:'print'})`: the primary nav and the
  Print button go hidden while the invoice article stays visible (REQ-004).

## Requirements coverage

| REQ | Acceptance criteria | Verified by | Status |
|---|---|---|---|
| REQ-001 | Signup lands on dashboard | `e2e/auth.spec.ts` "signup lands on the dashboard" | ✔ |
| REQ-001 | Signed-out request to any app page redirects to sign-in | `e2e/auth.spec.ts` (dashboard, invoices, clients) | ✔ |
| REQ-001 | Wrong password shows inline error, creates no session | `e2e/auth.spec.ts` "wrong password…" + curl 401 `INVALID_CREDENTIALS` | ✔ |
| REQ-001 | User A's session never returns user B's data | 7-probe isolation matrix above (two real accounts) | ✔ |
| REQ-002 | Create client with name only; email/address optional | `e2e/core-loop.spec.ts` + `POST /clients` | ✔ |
| REQ-002 | Edit reflects on existing invoices' send-ready views | `PATCH /clients/{id}`; contract's `ClientRef` is a live reference (no snapshot) | ✔ |
| REQ-002 | Client list shows each client's invoice count | `e2e/core-loop.spec.ts` asserts count 0; `GET /clients` returns `invoiceCount` | ✔ |
| REQ-002 | Empty name rejected with inline validation | `POST /clients {"name":"   "}` → 400 `details.name` | ✔ |
| REQ-003 | Create invoice: select client + 1..n line items | `e2e/core-loop.spec.ts` (2 items) | ✔ |
| REQ-003 | Amounts and total computed and live-updating in the form | `e2e/core-loop.spec.ts` asserts $1,500.00 then $2,625.00 **before** save | ✔ |
| REQ-003 | Cannot save with zero line items or no client | `e2e/core-loop.spec.ts` validation test + curl 400 (both cases) | ✔ |
| REQ-003 | Unique sequential number per account, visible | `e2e` asserts `INV-0001`; curl showed 0001→0002, and 0003 after deleting 0002 | ✔ |
| REQ-003 | Issue date defaults to today, editable; due date optional | curl: omitted `issueDate` → `2026-08-12`; explicit dates round-trip; `dueDate` null OK | ✔ |
| REQ-003 | Decimal quantities; negative unit prices rejected | 7.5 → 112500 cents; `unitPriceCents:-5` → 400 | ✔ |
| REQ-004 | Detail view shows number, dates, client, all line items, total | `e2e/core-loop.spec.ts` asserts all six on the article | ✔ |
| REQ-004 | Print-clean: no app chrome | `e2e` print-media assertion + `globals.css:471` | ✔ |
| REQ-004 | Paid/unpaid status visible on the view | `e2e` asserts "Unpaid" then "Paid" on the document stamp | ✔ |
| REQ-004 | Print yields *one page per invoice* | — | **untested** — page-count is not cheaply assertable in Playwright; manual check (test-plan.md) |
| REQ-005 | Exactly two statuses, unpaid on creation | contract enum + every create returned `"unpaid"` | ✔ |
| REQ-005 | One-click toggle from detail **and** list, no full reload | detail: `e2e/core-loop.spec.ts`; list: `StatusToggle` is rendered in the list's actions cell (source) + `POST .../status` returns the summary for in-place update | ✔ (list path source-verified, not e2e'd) |
| REQ-005 | Marking paid records a paid date; reverting clears it | curl: paid → `paidDate 2026-08-12`; unpaid → `paidDate null`; `e2e/paid-lock.spec.ts` revert | ✔ |
| REQ-005 | Dashboard totals reflect the change on next load | `e2e/core-loop.spec.ts` (outstanding $0.00, paid-this-month $2,625.00) | ✔ |
| REQ-006 | Outstanding total is the primary figure | `e2e` + `GET /dashboard` exact arithmetic | ✔ |
| REQ-006 | Total paid for current calendar month | `GET /dashboard` `paidThisMonthCents` correct; seq 12 proved the cross-month split | ✔ |
| REQ-006 | 10 most recent invoices, each linking to detail | contract `maxItems: 10`, ordering verified; `e2e` asserts the INV-0001 row renders | ✔ |
| REQ-006 | Zero invoices → empty state with CTA | `e2e/core-loop.spec.ts` "empty account shows the dashboard empty state" | ✔ |
| REQ-007 | List shows all invoices newest-first with the 5 columns | `GET /invoices` sorted issueDate desc, number desc | ✔ |
| REQ-007 | Filter all/unpaid/paid, reflected in the URL | `?status=` filter verified by curl; URL-persistence is source-verified (router.push in `invoices-screen.tsx`) | ✔ (URL state not e2e'd) |
| REQ-007 | Each row links to detail | source + dashboard row assertion | ✔ |
| REQ-008 | Unpaid invoice editable, totals recompute on save | `PATCH /invoices/{id}` replaces line items and recomputes; `e2e/paid-lock.spec.ts` proves the edit form opens after revert | ✔ |
| REQ-008 | Paid invoice's edit affordance disabled, reason shown | `e2e/paid-lock.spec.ts`: `aria-disabled=true`, title, on-page lock note, and the `/edit` URL renders the locked banner with no form | ✔ |
| REQ-008 | Unpaid invoice deletable after confirmation; number not reused | `e2e/paid-lock.spec.ts` confirm-dialog delete; curl proved 0003 after deleting 0002 | ✔ |
| REQ-009 | Purposeful empty states on clients, invoices, dashboard | all three `EmptyState` call sites; dashboard + clients verified live | ✔ |
| REQ-009 | Every submission failure shows an inline human-readable message | authored messages throughout — **except** the 3 raw-Zod strings in F-3 | ✘ (F-3, T-023) |
| REQ-009 | Nonexistent invoice/client id → friendly not-found with a link back | observed live: "This invoice doesn't exist" + "← All invoices" (captured during the F-2 investigation) | ✔ |
| REQ-010 | 375px: no horizontal scroll, all actions reachable | — | **untested** — deliberately not e2e'd (test-plan.md); `DataTable` stack mode + per-screen CSS source-inspected only |
| REQ-010 | ≥1024px: list pages use a tabular layout | — | **untested** — same rationale |

Every `must` REQ (001–006) is verified. The three unverified rows are two
`should`-priority responsive criteria and one print-fidelity criterion, all
flagged `untested` by design rather than by omission.

## Verdict

**4 failures filed as T-021 … T-024. Loop iteration 1 of 3.**

Owners: oma-backend (T-021 missing test suite, T-023 validation copy),
oma-frontend (T-022 hydration mismatch, T-024 Prettier pass).

The judgment worth stating plainly: **the product is in good shape and the
process is not.** Five of six pipeline stages pass, all 11 e2e tests pass, and
every contract probe — including the full 7-probe cross-account isolation
matrix and exact monetary arithmetic — conforms to the frozen contract.
Design-token parity is exact at 81/81. I could not find a functional defect in
the core loop.

The one serious finding is F-1: nine tasks were accepted as `done` against
acceptance criteria naming vitest tests that were never written. The behaviour
those tests would have covered is, as far as I can tell, correct — I re-proved
it by curl this run. But "correct today, verified by hand, unrepeatable
tomorrow" is precisely the gap between a repository that runs and one that
merely looks finished. T-021 closes it. T-022 through T-024 are genuine but
minor: one latent hydration bug, three unpolished strings, one formatting pass.

Not a ship/no-ship call — that is the user's gate. My read: F-1 should be
fixed before this is called done; F-2 to F-4 are safe to schedule.

## Housekeeping

- Servers started this run (`next start` :3401, :3411 via Playwright,
  `next dev` :3421) are all stopped.
- Test accounts created by curl probes (`qa-alpha@example.com`,
  `qa-bravo@example.com`) and by the e2e suite (`qa-<slug>-<ts>-<rand>@…`)
  remain in `data/ledgerly.db`. Left in place deliberately: the DB is
  gitignored local demo state, and the accounts are the evidence behind this
  report. Delete the file to reset.
- New QA-owned files: `playwright.config.ts`, `e2e/helpers.ts`,
  `e2e/auth.spec.ts`, `e2e/core-loop.spec.ts`, `e2e/paid-lock.spec.ts`.
  No application file was modified by QA this run.
