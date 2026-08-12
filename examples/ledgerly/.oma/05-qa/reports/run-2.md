# QA report — run 2

- **Date:** 2026-08-12T10:10:00Z
- **Iteration:** 2 of 3
- **Commit state:** `8086c1b` — working tree clean at start and at end of this run

> Every result row cites the actual command run. Claims without a corresponding
> entry in `.oma/log/commands.jsonl` are fabrications — the log is the authority.

## Pipeline

Re-run in full this session. No verdict is carried over from run 1.

| Check | Command | Exit | Verdict |
|---|---|---|---|
| install | `npm install` | 0 | **pass** — 568 packages audited, 0 vulnerabilities |
| typecheck | `npm run typecheck` (`tsc --noEmit`) | 0 | **pass** |
| lint | `npm run lint` (`eslint .`) | 0 | **pass** — no warnings emitted |
| build | `npm run build` (`next build`) | 0 | **pass** (1 warning, unchanged from run 1) |
| unit | `npm test` (`vitest run`) | 0 | **pass** — 167/167 in 10 files |
| e2e | `npx playwright test` | 0 | **pass** — 11/11 |
| format | `npm run format:check` (`prettier --check .`) | 0 | **pass** — "All matched files use Prettier code style!" |

Six of six pipeline stages green, plus the format gate that was red in run 1.

**Build warning (`warn`, not filed, unchanged):** Turbopack still reports
`Dynamic filesystem access causes tracing of the whole project` for
`src/server/db.ts`. Same non-blocking warning as run 1; no regression, no new
warnings appeared.

## Verification of the four run-1 fixes

### T-021 — vitest suite (F-1) — **VERIFIED, and the suite is load-bearing**

`npm test` exits 0 with 167 tests across 10 files
(money 12, dates 11, envelope 13, schemas 29, db 8, http 16, invoices 36,
clients 14, dashboard 12, auth 16 = 167 — the claimed count is the real count).

Backend claimed they mutation-tested it. I did not take that on trust. **I ran
my own mutation campaign with ten defects they did not name**, chosen to land in
places a hollow suite would sail past, plus a no-op control. Every mutation was
applied to application source with a one-line replacement, `vitest run` was
invoked, and the file was reverted with `git checkout --` (final `git status
--short` clean — verified).

| # | Mutation (application source) | Exit | Result |
|---|---|---|---|
| M1 | `dashboard.ts` — outstanding aggregate drops `status: "unpaid"` | 1 | **killed** — 4 failed / 8 passed |
| M2 | `dashboard.ts` — recents `take: 10` → `take: 3` | 1 | **killed** — 1 failed |
| M3 | `services/auth.ts` — `argon2Verify(...)` → `matches = true` (any password works) | 1 | **killed** — 2 failed |
| M4 | `services/auth.ts` — `normalizeEmail` drops `.toLowerCase()` | 1 | **killed** — 2 failed |
| M5 | `services/auth.ts` — session token stored raw instead of SHA-256 | 1 | **killed** — 4 failed |
| M6 | `services/invoices.ts` — list `orderBy` desc → asc | 1 | **killed** — 1 failed |
| M7 | `money.ts` — `padStart(4,"0")` → `padStart(3,"0")` | 1 | **killed** — 9 failed across 3 files |
| M8 | `money.ts` — `quantityToThousandths` `Math.round` → `Math.floor` | 1 | **killed** — 1 failed |
| M9 | `services/auth.ts` — sliding-expiry refresh never fires | 1 | **killed** — 1 failed |
| M10 | `services/invoices.ts` — `paidAt` not cleared when reverting to unpaid | 1 | **killed** — 1 failed |
| — | **CONTROL** — no-op comment on `money.ts` | 0 | **green** — 167/167, as it must be |

**10 of 10 independent mutations turned the suite red; the control stayed
green.** The suite genuinely exercises the service layer against a real
database, not a mock: M1, M5, M6 and M10 can only die if a Prisma query really
runs. `vitest.config.ts`'s `include: ["src/**/*.test.ts"]` was checked for
hidden files — `find src -name "*.spec.ts" -o -name "*.test.tsx"` returns
nothing, so the narrow glob is not concealing an excluded suite. No `.skip`,
`.only`, `.todo`, `@ts-expect-error` or `eslint-disable` appears in any test
file; the single `toBeTruthy()` (`db.test.ts:167`) is a `rejects.toBeTruthy()`
on a constraint violation, which is a legitimate shape for that assertion.

Backend's own disclosed boundary — route-handler auth guards and cookie flags
are not unit-tested — is accurate and is the right call: I cover that surface
with e2e and curl (five 401 probes below), and unit-testing a mocked
`requireUser` would test the mock.

### T-022 — hydration mismatch (F-2) — **VERIFIED fixed at the cause**

`grep -rn "draftSequence" src/` returns nothing; the module-level counter is
gone, replaced by `useLineItemDrafts()` in `LineItemEditor.tsx:57` with a pure
index-derived `seed(n)` for server-rendered rows and a ref counter for rows
added after mount. No `suppressHydrationWarning` anywhere in `src/`.

Re-ran the exact run-1 repro (`next dev` on :3521, load `/invoices/new`
repeatedly, real browser, console captured):

```
data-li-key across 4 dev loads: ["_R_inebn5rlb_s0","_R_inebn5rlb_s0","_R_inebn5rlb_s0","_R_inebn5rlb_s0"]
focus after add-row: {"name":"description","rowKey":"_R_1etinebn5rlb_a1"}
all row keys: ["_R_inebn5rlb_s0","_R_1etinebn5rlb_a1"]  unique: true
console messages total: 8 — hydration-related: 0
```

Identical key on all four loads (run 1 diverged on the second), zero hydration
messages, and the focus-after-add-row `querySelector` — the behaviour the stale
key silently broke — resolves to the new row. Seed and added keys carry
different `useId` prefixes because the hook is instantiated in both
`invoice-form-screen.tsx` and `LineItemEditor.tsx`; the `s`/`a` suffix
namespaces make collision impossible either way, so this is not a defect.

### T-023 — authored validation messages (F-3) — **fixed for the two strings I
cited, but the underlying defect class is not closed**

The three strings named in run 1 now return authored prose. Live against the
production build on :3531:

```
?status=bogus -> 400 {"details":{"status":"Status must be either unpaid or paid."}}
?page=0       -> 400 {"details":{"page":"Page must be 1 or higher."}}
?page=abc     -> 400 {"details":{"page":"Page must be a whole number."}}
?page=1.5     -> 400 {"details":{"page":"Page must be a whole number."}}
```

And they are pinned by the suite, not just by hand: reverting
`invoiceStatusSchema`'s authored message turned 5 tests red, reverting the page
schema's turned 2 red. The fix cannot silently rot.

**However** — see F-5 — four more raw-Zod strings remain elsewhere in the same
schemas, one of which a user reaches by typing in the invoice form. Run 1 named
three specific strings instead of the class; T-023's acceptance inherited that
scope. That is a miss in my run-1 filing as much as in the fix, and it is filed
now as its own task rather than reopened.

### T-024 — repo-wide Prettier pass (F-4) — **VERIFIED**

`npm run format:check` exits 0: *"All matched files use Prettier code style!"*
(run 1: 28 pre-existing files failing).

**Regression check on the blast radius of a repo-wide `--write`.** This is the
change most capable of quiet collateral damage, so:

- **Frozen contracts are byte-intact.** All four SHA-256 values in
  `state.json` recomputed and matched: api-contract.yaml, data-model.md,
  tokens.json, motion-spec.md — 4/4 **MATCH**. `.prettierignore` lists `.oma/`,
  which is why.
- **No config or dependency drift.** The only change to `package.json` in
  `8086c1b` is a trailing newline; `tsconfig.json`, `eslint.config.mjs`,
  `next.config.ts`, `prisma/` and `.prettierrc.json` are untouched.
- **No assertion was weakened.** My `e2e/` files appear in `8086c1b` as
  `new file mode` (they were authored in run 1 and committed for the first time
  in this commit), so nothing was edited under them. `grep` for
  `test.skip|test.only|test.fixme` in `e2e/` returns nothing, and the suite
  still runs the same 11 tests with the same assertions. Nothing in this run
  looks like a judgment being repaired instead of a bug.

## Failures

### F-5: raw Zod default text still reaches the user — including on a path a real user types

- **Where:** `src/shared/schemas/invoices.ts:26` (`quantity.max(1_000_000)`),
  `:32` (`unitPriceCents.max(100_000_000)`); `src/shared/schemas/common.ts:8`
  (`idSchema = z.string().min(1)`); `src/shared/schemas/auth.ts:7`
  (`email.max(320)`). Four constraints with no authored message.
- **Repro:** `curl` against `next start` on :3531, and the built invoice form
  in a real browser.
- **Output:**
  ```
  POST /api/invoices  quantity: 1000001      -> {"lineItems.0.quantity":"Too big: expected number to be <=1000000"}
  POST /api/invoices  unitPriceCents: 1e8+1  -> {"lineItems.0.unitPriceCents":"Too big: expected number to be <=100000000"}
  POST /api/invoices  clientId: ""           -> {"clientId":"Too small: expected string to have >=1 characters"}
  POST /api/auth/signup  321-char email      -> {"email":"Too big: expected string to have <=320 characters"}
  ```
  In the browser, on `/invoices/new`, selecting a client and typing quantity
  `2000000` then Save renders, inline under the field:
  ```
  Too big: expected number to be <=1000000
  ```
  (URL stays on `/invoices/new`; the message is on the page, not in a log.)
- **Why it matters:** this is materially worse than F-3 was. F-3's three
  strings were only reachable by hand-editing a URL; **this one is reachable by
  a freelancer typing a large quantity into the invoice form.** REQ-009
  requires every submission failure to show a human-readable inline message,
  and the contract describes `details` values as "Human-readable, safe to
  render inline (REQ-009)". Compare the authored style two lines above it in
  the same file: `"Quantity must be greater than zero."`
- **Probable owner:** oma-backend — `src/shared/schemas/` is backend-written,
  same files as T-023.
- **Filed as:** T-025

### F-6: contract-legal invoice amounts exceed the 32-bit `Int` columns the data model declares, silently

- **Where:** `prisma/schema.prisma` — `Invoice.totalCents`,
  `InvoiceLineItem.amountCents` are `Int`; `.oma/02-architecture/api-contract.yaml:805-814`
  — `LineItemInput.quantity` maximum 1,000,000, `unitPriceCents` maximum
  100,000,000.
- **Repro:** one line item at contract-legal values, `quantity: 1000`,
  `unitPriceCents: 100000000` (a $1,000,000.00 unit price × 1000 units).
- **Output:**
  ```
  POST /api/invoices -> HTTP 201
    "totalCents": 100000000000
    lineItems[0].amountCents: 100000000000
  GET  /api/invoices    -> totalCents 100000000000
  GET  /api/dashboard   -> outstandingCents 100000000000
  sqlite3 data/ledgerly.db:
    Invoice  (number=1, totalCents=100000000000, typeof='integer')
    LineItem (amountCents=100000000000, quantityThousandths=1000000, unitPriceCents=100000000)
  ```
- **Assessment of oma-backend's open question (Q-004) — their premise is wrong,
  but there is still a defect underneath it.** They reported a cap "near
  $21.5M". **No such cap exists on the shipped stack.** SQLite's INTEGER is
  64-bit and the Prisma driver adapter passes the value straight through: the
  write succeeds, the read is exact, the dashboard aggregate is exact, and the
  raw column holds `100000000000`. Nothing overflows, truncates or errors at
  any point in v1. Their arithmetic claim is right (`computeAmountCents` is
  BigInt-exact); their storage claim is not, and I could not reproduce a single
  v1-visible symptom.
  The real defect is one layer down. Prisma `Int` on **PostgreSQL** is a 4-byte
  `INTEGER`, max 2,147,483,647. ADR-001 — binding, and the entire justification
  for the SQLite override — promises a v2 Postgres move is "a driver-adapter +
  migration swap". A row this API accepts today cannot be migrated under that
  promise; it would fail on insert or need silent truncation. So the frozen
  api-contract's input maxima and the frozen data-model's column widths are
  **mutually inconsistent under a guarantee ADR-001 makes** — two frozen
  artifacts contradicting each other, which is the one case my role escalates.
  **Verdict: not an acceptable v1 ceiling to leave undocumented, but not a v1
  malfunction either** — it is a latent portability defect with a real trigger
  inside the contract's own stated limits, and it cannot be fixed from inside
  the freeze. Either the data model widens `totalCents`/`amountCents` to
  `BigInt`, or the contract tightens `LineItemInput`'s maxima so the product
  fits 32 bits. Both are change requests.
- **Probable owner:** oma-backend to implement — but **blocked on a decision
  the user/architect must make**, because both remedies edit a frozen artifact.
  Raised as `contract_changes` in the handoff alongside this task.
- **Filed as:** T-026

### Not filed (`warn`)

- **Turbopack whole-project tracing warning** on `src/server/db.ts` — unchanged
  from run 1, non-blocking, matters only if this is containerised.
- **`PUT /api/clients` returns a bodiless 405.** Next's framework default for
  an undeclared method. The contract enumerates 8 error codes and no 405, and
  PUT is not one of its 16 operations, so this is outside the contract rather
  than in violation of it. Every declared operation returns the envelope.
- **No CI workflow exists** (`.github/` absent) although `stack.md` specifies
  `install → typecheck → lint → test → build`. That is 06-devops scope, not a
  build defect; noting it because T-021's value is mostly realised once a
  machine runs it. Now that `npm test` exits 0, the chain is finally runnable
  end to end.

## Contract conformance spot-check

Probed against `next start` on :3531 (the production build), three accounts,
`curl` with cookie jars, against the frozen `api-contract.yaml`.

**Auth rejection — every protected endpoint, no cookie:**

| Probe | Expected | Got |
|---|---|---|
| `GET /dashboard`, `/clients`, `/invoices`, `/auth/me`, `POST /auth/signout` | 401 `UNAUTHENTICATED` | 401 `UNAUTHENTICATED` + `"Sign in to continue."` ✔ (5/5) |

**Error registry — all 8 codes exercised, all conformant:**

| Probe | Expected | Got |
|---|---|---|
| duplicate email, case-differing (`QA-R2A-DUP@Example.com`) | 409 `EMAIL_TAKEN` | 409 ✔ — confirms server-side lowercasing |
| signin wrong password | 401 `INVALID_CREDENTIALS` | 401 ✔ |
| `POST /clients` name `"   "` | 400 `VALIDATION_FAILED` | 400, `details.name` = "Name is required." ✔ |
| `DELETE /clients/{id}` with invoices | 409 `CLIENT_HAS_INVOICES` | 409 ✔ |
| `PATCH` and `DELETE` on a paid invoice | 409 `INVOICE_PAID_LOCKED` | 409 ✔ (both) |
| `POST /invoices` unknown `clientId` | 404 `NOT_FOUND` "Client not found." | 404, exact message ✔ |
| malformed JSON body | 400 `VALIDATION_FAILED` | 400, `details._` = "Request body must be valid JSON." ✔ |
| `PATCH /clients/{id}` with `{}` (minProperties: 1) | 400 `VALIDATION_FAILED` | 400, "Provide at least one field to update." ✔ |

**Shape and arithmetic:** `POST /invoices` with the contract's own example body
returned the contract's own example figures — `amountCents` 150000 + 112500,
`totalCents` 262500, `displayNumber` `"INV-0001"`, `status` `"unpaid"`,
`issueDate` defaulted to `2026-08-12` (today UTC). `GET /invoices` returned
`meta: {page:1, pageSize:25, total:N}` with `pageSize` at the contract's
`const: 25`.

**Account isolation (REQ-001), re-proven with two fresh accounts this run:**

| B → A's resource | Expected | Got |
|---|---|---|
| `GET /invoices/{A}` | 404 (never 403 — no existence leak) | 404 ✔ |
| `GET /clients/{A}` | 404 | 404 ✔ |
| `PATCH /clients/{A}` | 404 | 404 ✔ |
| `POST /invoices/{A}/status` | 404 | 404 ✔ |
| `DELETE /invoices/{A}` | 404 | 404 ✔ |
| `GET /invoices` | `[]`, total 0 | ✔ |
| `GET /dashboard` | all zeroes | ✔ |

### Mockup parity spot-check

Three built screens loaded in a real browser against the production build.

- **Empty states are real content on all three surfaces**, not blank divs:
  dashboard *"No invoices yet — Create your first invoice and Ledgerly starts
  tracking who owes you"* with 3 CTA links; clients *"No clients yet — Add your
  first client, invoices always attach to a client"*; invoices *"No invoices
  yet — Your first invoice takes about a minute…"*.
- **Tokens resolve at runtime**, not just in the stylesheet:
  `--color-bg #f6f5f1`, `--color-text #1c1b17`, `--color-accent #1f6f54`,
  `--radius-md 10px`, `--space-4 16px`, and `body` computes to
  `rgb(246,245,241)` — i.e. the token is actually what paints. (Run 1's
  81/81 custom-property parity against `mockups/tokens.css` still holds; the
  frozen `tokens.json` hash is unchanged.)
- **Reduced motion honoured:** under `prefers-reduced-motion: reduce`, every
  non-zero animation/transition duration in `main` collapses to a single value,
  `1e-06s` — durations are clamped, not merely shortened.
- **Zero console errors** across dashboard, clients, invoices and the invoice
  form on the production build.

## Requirements coverage

| REQ | Acceptance criteria | Verified by | Status |
|---|---|---|---|
| REQ-001 | Signup lands on dashboard | `e2e/auth.spec.ts` | ✔ |
| REQ-001 | Signed-out request to any app page redirects to sign-in | `e2e/auth.spec.ts` (dashboard, invoices, clients) | ✔ |
| REQ-001 | Wrong password shows inline error, creates no session | `e2e/auth.spec.ts` + curl 401 + `services/auth.test.ts` (M3 kills it) | ✔ |
| REQ-001 | User A's session never returns user B's data | 7-probe isolation matrix (fresh accounts) + `invoices.test.ts` isolation cases | ✔ |
| REQ-002 | Create client with name only; email/address optional | `e2e/core-loop.spec.ts` + `clients.test.ts` | ✔ |
| REQ-002 | Edit reflects on existing invoices' send-ready views | `clients.test.ts` CRUD; `ClientRef` is a live reference, no snapshot | ✔ |
| REQ-002 | Client list shows each client's invoice count | `e2e` + `clients.test.ts` `invoiceCount` | ✔ |
| REQ-002 | Empty name rejected with inline validation | curl → 400 `details.name` "Name is required." | ✔ |
| REQ-003 | Create invoice: select client + 1..n line items | `e2e/core-loop.spec.ts` + `invoices.test.ts` | ✔ |
| REQ-003 | Amounts and total computed, live-updating in the form | `e2e` asserts $1,500.00 → $2,625.00 before save | ✔ |
| REQ-003 | Cannot save with zero line items or no client | `e2e` validation test + curl 400 (both) | ✔ |
| REQ-003 | Unique sequential number per account, visible | `e2e` asserts INV-0001; `invoices.test.ts` ADR-004 cases (M-numbering) | ✔ |
| REQ-003 | Issue date defaults to today, editable; due date optional | curl: omitted `issueDate` → `2026-08-12`; `invoices.test.ts` | ✔ |
| REQ-003 | Decimal quantities; negative unit prices rejected | 7.5 → 112500 cents; `money.test.ts` (M8 kills it); curl 400 | ✔ |
| REQ-004 | Detail view shows number, dates, client, all line items, total | `e2e/core-loop.spec.ts` asserts all six | ✔ |
| REQ-004 | Print-clean: no app chrome | `e2e` print-media assertion + `globals.css` print block | ✔ |
| REQ-004 | Paid/unpaid status visible on the view | `e2e` asserts "Unpaid" → "Paid" | ✔ |
| REQ-004 | Print yields *one page per invoice* | — | **untested** — page count not cheaply assertable in Playwright; manual check per test-plan.md |
| REQ-005 | Exactly two statuses, unpaid on creation | contract enum + every create returned `"unpaid"` | ✔ |
| REQ-005 | One-click toggle from detail **and** list, no full reload | detail: `e2e`; list: source + `POST .../status` returns the summary | ✔ (list path source-verified, not e2e'd) |
| REQ-005 | Marking paid records a paid date; reverting clears it | curl paid → `paidDate`; `invoices.test.ts` (M10 kills the revert case) | ✔ |
| REQ-005 | Dashboard totals reflect the change on next load | `e2e` + `dashboard.test.ts` (M1 kills it) | ✔ |
| REQ-006 | Outstanding total is the primary figure | `e2e` + `GET /dashboard` exact arithmetic + `dashboard.test.ts` | ✔ |
| REQ-006 | Total paid for current calendar month | `dashboard.test.ts` UTC month-boundary cases | ✔ |
| REQ-006 | 10 most recent invoices, each linking to detail | `dashboard.test.ts` (M2 kills the `take: 10`) | ✔ |
| REQ-006 | Zero invoices → empty state with CTA | `e2e` + loaded live this run | ✔ |
| REQ-007 | List shows all invoices newest-first with the 5 columns | `GET /invoices` ordering + `invoices.test.ts` (M6 kills it) | ✔ |
| REQ-007 | Filter all/unpaid/paid, reflected in the URL | curl `?status=`; URL persistence source-verified (`router.push`) | ✔ (URL state not e2e'd) |
| REQ-007 | Each row links to detail | source + dashboard row assertion | ✔ |
| REQ-008 | Unpaid invoice editable, totals recompute on save | `invoices.test.ts` PATCH cases; `e2e/paid-lock.spec.ts` | ✔ |
| REQ-008 | Paid invoice's edit affordance disabled, reason shown | `e2e/paid-lock.spec.ts` + curl 409 on PATCH and DELETE | ✔ |
| REQ-008 | Unpaid invoice deletable after confirmation; number not reused | `e2e` confirm-dialog delete + `invoices.test.ts` non-reuse case | ✔ |
| REQ-009 | Purposeful empty states on clients, invoices, dashboard | all three loaded live this run, real copy + CTA | ✔ |
| REQ-009 | Every submission failure shows an inline human-readable message | 3 strings fixed by T-023 — **4 raw-Zod strings remain, one reachable from the invoice form** | ✘ (F-5, T-025) |
| REQ-009 | Nonexistent invoice/client id → friendly not-found with a link back | observed live in run 1; `NOT_FOUND` envelope re-probed this run | ✔ |
| REQ-010 | 375px: no horizontal scroll, all actions reachable | — | **untested** — deliberately not e2e'd (test-plan.md); source-inspected only |
| REQ-010 | ≥1024px: list pages use a tabular layout | — | **untested** — same rationale |

Every `must` REQ (001–006) is verified. REQ-009 (`should`) regresses to ✘ on
one criterion via F-5. The three `untested` rows are unchanged from run 1 and
remain untested by design, not by omission.

## Verdict

**Pipeline is fully green — install 0, typecheck 0, lint 0, build 0, unit 0
(167/167), e2e 0 (11/11), format:check 0. All four run-1 fixes verified real,
with no regression found around any of them. 2 new failures filed as T-025 and
T-026. Loop iteration 2 of 3.**

The claim I was asked to distrust holds up. Backend's test suite is not
decoration: **ten mutations I chose myself, in code they did not name, each
turned it red, and a no-op control stayed green.** M3 (any password accepted)
and M5 (session tokens stored in plaintext) dying is the specific reassurance
worth stating — the security-shaped assertions are real assertions. The run-1
gap between "nine tasks claimed vitest coverage" and "no test file existed" is
genuinely closed, and the fix arrived without a single weakened assertion, a
config change, or a scratch on the four frozen contracts (all SHA-256 verified
this run).

The two new findings are both narrow and neither blocks the core loop:

- **T-025** is the tail of a defect I under-scoped in run 1. I filed three
  strings; the class was four more. One of them — the quantity maximum — is
  reachable by a user typing into the invoice form, which makes it a live
  REQ-009 violation rather than the URL-hacking curiosity F-3 was. Cheap fix,
  same files T-023 already touched.
- **T-026** is the money-column question, and my answer differs from the
  question. There is no $21.5M ceiling: SQLite stores the 64-bit value exactly,
  and I have a live invoice with `totalCents: 100000000000` reading back
  correctly through the API and the dashboard. What is actually broken is the
  promise in ADR-001 — those rows cannot follow a v2 Postgres migration, and
  the contract's own maxima are what let them exist. It needs a decision
  (widen the columns, or tighten the contract) before it needs code, so it is
  escalated as `contract_changes` as well as filed.

Not a ship/no-ship call — that is the user's gate. My read: **T-025 should be
fixed before this is called done** (it is a user-visible violation of a stated
requirement and costs minutes); **T-026 should be decided, not necessarily
implemented, before v1 is called done** — leaving it undecided means shipping a
v2 migration hazard that nobody wrote down.

## Housekeeping

- Servers started this run (`next dev` :3521, `next start` :3531, Playwright's
  :3411) are all stopped — ports confirmed down.
- Working tree clean at end of run (`git status --short` empty). All eleven
  mutations were reverted with `git checkout --`; no application file was
  modified by QA this run.
- Probe accounts (`qa-run2-*`, `qa-r2a-*`, `qa-r2b-*`, `qa-hydration-*`,
  `qa-uiprobe-*`) and the `totalCents: 100000000000` invoice remain in the
  gitignored `data/ledgerly.db` — they are the evidence behind F-6. Delete the
  file to reset.
- No new QA-owned test files this run; `e2e/` is unchanged from run 1.
