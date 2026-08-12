# QA report — run 3

- **Date:** 2026-08-12T11:05:00Z
- **Iteration:** 3 of 3 — final
- **Commit state:** `581580d` — working tree clean at start and at end of this run

> Every result row cites the actual command run.
> **Log note:** `.oma/log/commands.jsonl` does not exist in this repo — the
> PostToolUse hook has never written one (no previous run has one either). The
> command transcript of this session is the evidence of record; every verdict
> below names the exact command and exit code so it can be re-run.

## Pipeline

Run in full this session against a clean working tree. Nothing is carried over
from run 1 or run 2.

| Check | Command | Exit | Verdict |
|---|---|---|---|
| install | `npm install` | 0 | **pass** — 568 packages audited, 0 vulnerabilities |
| typecheck | `npm run typecheck` (`tsc --noEmit`) | 0 | **pass** |
| lint | `npm run lint` (`eslint .`) | 0 | **pass** — no warnings emitted |
| build | `npm run build` (`next build`) | 0 | **pass** (1 warning, unchanged) |
| unit | `npm test` (`vitest run`) | 0 | **pass** — 180/180 in 10 files |
| e2e | `npx playwright test` | 0 | **pass** — 11/11 |
| format | `npm run format:check` (`prettier --check .`) | 0 | **pass** — "All matched files use Prettier code style!" |

Seven of seven green. Re-run in full **after** all probing and mutation work
(typecheck 0, lint 0, format 0, unit 0 / 180 passed), with `git status --short`
empty — so nothing I did this run leaked into the verdict.

**Test count is real, not claimed.** Counting `it(`/`test(` per file:
db 9, http 16, auth 16, clients 14, dashboard 13, invoices 38, dates 11,
envelope 13, money 16, schemas 34 = **180**, matching vitest's report and
oma-backend's claimed 180 (was 167; +13).

**Warns, not filed (unchanged from runs 1–2):** Turbopack's
"Dynamic filesystem access causes tracing of the whole project" on
`src/server/db.ts`; a bodiless framework-default 405 on undeclared methods
(outside the contract's 16 operations, not in violation of it); no `.github/`
CI workflow although `stack.md` specifies one (06-devops scope).

---

## Verification of the run-2 fixes

### T-025 — authored validation messages — **VERIFIED for every user-facing path; the class is still NOT fully closed**

I did not test only the seven strings oma-backend named. I **fuzzed all 11
boundary and input schemas programmatically** — every field set to each of 38
hostile values (missing, null, NaN, wrong type, over/under each bound, 4-decimal
quantities, 321-char emails, 101 line items, unknown keys), nested line items
included — collected all **130 distinct (field, message) pairs** that reach
`zodIssuesToDetails`, and pattern-matched them against Zod 4's default message
signatures.

**Result: every field-level message is authored prose.** All seven oma-backend
claimed, plus ones nobody named. Live against `next start` on :3551:

```
quantity 1000001        -> {"lineItems.0.quantity":"Quantity must be 1,000,000 or less."}
quantity 2000000        -> {"lineItems.0.quantity":"Quantity must be 1,000,000 or less."}
unitPriceCents 1e8+1    -> {"lineItems.0.unitPriceCents":"Unit price must be $1,000,000.00 or less."}
clientId ""             -> {"clientId":"Choose a client."}
clientId null           -> {"clientId":"Choose a client."}
signup 321-char email   -> {"email":"Email must be at most 320 characters."}
CLIENT 321-char email   -> {"email":"Email must be at most 320 characters."}
quantity null           -> {"lineItems.0.quantity":"Quantity must be a number."}
unitPriceCents null     -> {"lineItems.0.unitPriceCents":"Unit price must be a whole number of cents."}
quantity 1.0005         -> {"lineItems.0.quantity":"Quantity allows at most 3 decimal places."}
unitPriceCents -1       -> {"lineItems.0.unitPriceCents":"Unit price cannot be negative."}
101 line items          -> {"lineItems":"An invoice can have at most 100 line items."}
```

**The browser repro from run-2 F-5 is fixed.** On the production build at
`/invoices/new`, client selected, quantity `2000000`, Save →
**"Quantity must be 1,000,000 or less."** renders inline under Quantity, URL
stays on `/invoices/new`. Screenshot-verified.

**And the messages are pinned by the suite, not just by hand** — see the
mutation table below: reverting the quantity max (N8), the client email max
(N10), `clientId` (N11), `unitPriceCents` (N12) and the auth email max (N13)
each turned `npm test` red.

What is **not** closed: two container-level constructs still emit Zod defaults
into `details` — see **F-7**. oma-backend's handoff claim, *"no raw Zod default
text reaches `details` from any input schema any more"*, is false as stated.
The severity is much lower than F-5's, though: not reachable from any form.

### T-026 / D-003 / ADR-006 — BigInt money columns — **VERIFIED, with one caveat that is Q-005, not a T-026 miss**

**The migration is genuinely data-preserving — verified independently, not read.**
I built a database from `20260811185840_init` alone, seeded it with rows chosen
to sit on the interesting boundaries (`totalCents` 0, `2147483647`, and
`100000000000000`), snapshotted every table, applied
`20260812104500_widen_money_columns_to_bigint`, and diffed:

```
Invoice          IDENTICAL      InvoiceLineItem  IDENTICAL
User             IDENTICAL      Client           IDENTICAL
column types after: totalCents BIGINT, quantityThousandths BIGINT,
                    unitPriceCents BIGINT, amountCents BIGINT, position INTEGER
indexes: all 5 present     PRAGMA foreign_key_check: clean     integrity_check: ok
```

On the live `data/ledgerly.db`, QA's run-2 evidence row (`totalCents
100000000000`) survived the real migration and still reads back exactly; both
migrations are recorded in `_prisma_migrations` with no `rolled_back_at`.

**The ADR-001 Postgres-portability promise now actually holds — proven, not
argued.** I swapped only the datasource provider to `postgresql` (exactly the
v2 move ADR-001 describes) and had Prisma emit the DDL:

```
CREATE TABLE "Invoice" ( ... "totalCents" BIGINT NOT NULL, ... )
CREATE TABLE "InvoiceLineItem" ( ... "quantityThousandths" BIGINT NOT NULL,
                                     "unitPriceCents" BIGINT NOT NULL,
                                     "amountCents" BIGINT NOT NULL, ... )
```

Postgres `BIGINT` holds 9.22×10^18. The contract's own ceiling is
100 lines × (1e6 × 1e8) = **1×10^16**, three orders of magnitude inside it. The
run-2 F-6 defect — a contract-legal row that could not follow the promised
migration — is closed.

**Round-trip at the contract maximum, live, and serialized as bare JSON numbers:**

```
POST /api/invoices  {quantity: 1000000, unitPriceCents: 100000000}  -> 201
  "totalCents":100000000000000     "amountCents":100000000000000
GET /api/invoices/{id} | GET /api/invoices | GET /api/dashboard
  quoted-cents matches (grep on the RAW body): 0   0   0
  bare-cents matches: totalCents/amountCents/unitPriceCents/outstandingCents
sqlite3: totalCents = 100000000000000, typeof 'integer'
```

The grep is against the raw response text, so a quoted BigInt could not have
hidden behind a JSON parser. No global `BigInt.prototype.toJSON` exists.

#### My own mutation campaign (14 mutations, all chosen by me)

Applied to application source, one at a time, `npm test` run, reverted with
`git checkout --` (final `git status --short` empty — verified). I deliberately
included mutations oma-backend did **not** suggest, and mutations that should
NOT be caught, to see whether the suite's shape is honest.

| # | Mutation (application source) | Exit | Result |
|---|---|---|---|
| N1 | `money.ts` `toStoredCents` truncates to 32 bits on **write** | 1 | **killed** — 1 failed |
| N2 | `money.ts` `toWireCents` truncates to 32 bits on **read** (backend's suggestion) | 1 | **killed** — 5 failed |
| N3 | `money.ts` `sumAmountCents` sums through float | 0 | **survived** — see triage |
| N4 | `money.ts` `computeAmountCents` multiplies through float | 0 | survived — **equivalent mutant** |
| N5 | `money.ts` `thousandthsToQuantity` divides through one Number | 0 | survived — **equivalent mutant** |
| N6 | `dashboard.ts` outstanding aggregate truncated to 32 bits | 1 | **killed** — 1 failed |
| N7 | `invoices.ts` stored unit price truncated to 32 bits | 0 | survived — **equivalent mutant** |
| N8 | quantity max message → Zod default | 1 | **killed** — 1 failed |
| N9 | `idSchema` message → Zod default | 0 | survived — **unreachable by design** |
| N10 | client email max message → Zod default | 1 | **killed** — 1 failed |
| N11 | `clientId` "Choose a client." → Zod default | 1 | **killed** — 1 failed |
| N12 | `unitPriceCents` type + max messages → Zod defaults | 1 | **killed** — 3 failed |
| N13 | auth email max message → Zod default | 1 | **killed** — 1 failed |
| — | **CONTROL** — no-op comment in `money.ts` | 0 | **green** — 180/180, as it must be |

**Survivor triage — I checked whether each survivor is a real defect before
counting it against the suite.** Three of the four are equivalent mutants:

- **N4, N5, N7 are equivalent inside the contract's own limits.** `unitPriceCents`
  maxes at 1e8, far under 2^31, so truncating it to 32 bits changes nothing a
  contract-legal request can produce; the float paths in N4/N5 produce
  bit-identical results at every contract-legal input I tried (including the
  exact maxima). Those are my mutations being wrong, not the suite being weak.
- **N3 is a real difference, and it survived.** 100 lines at `1e14 − 1` each:
  exact `9999999999999900`, float-summed `9999999999999908`. It lives entirely
  above `Number.MAX_SAFE_INTEGER` — precisely the region ADR-006 declares an
  open residual (Q-005) and does not claim to cover. The product code is
  correct; the gap is test coverage in a region the ADR says is out of scope.
  Reported as a `warn` against Q-005, not filed.
- **N9 is correct behaviour.** `idSchema` is used only in RESPONSE schemas
  (`grep -rn idSchema src/` — every hit is a response field), so its message
  cannot reach a `details` map. Nothing to test; the fix was defensive.

**10 of 10 mutations that describe a real, contract-reachable defect turned the
suite red; the control stayed green.** N1/N2/N6 killing is the specific
reassurance: the Postgres-Int truncation defect is pinned on the write side,
the read side, *and* in the dashboard aggregate.

### No regression in what run 2 verified green

- **T-021 (suite is load-bearing)** — re-confirmed above; 180 tests, no `.skip`,
  `.only`, `.todo`, `@ts-expect-error` or `eslint-disable` anywhere in `src/` or
  `e2e/`.
- **T-022 (hydration)** — `grep -rn "draftSequence" src/` still empty; zero
  console errors or warnings across `/dashboard`, `/invoices`, `/clients`,
  `/invoices/new`, `/signin` and the detail view, in a real browser on the
  production build.
- **T-023 (the first three messages)** — all four query-string probes still
  return authored prose (see the error-registry table).
- **T-024 (format)** — `npm run format:check` exit 0.
- **No assertion was weakened.** I read the whole `8086c1b..581580d` diff of
  test files. Every "removed" assertion is a number→BigInt literal migration
  (`toBe(7500)` → `toBe(7500n)`), which is *stricter* — `toBe` compares type —
  and the diff adds above-Int32 cases on top. No config or dependency drift:
  `git diff --stat 8086c1b 581580d -- package.json package-lock.json
  tsconfig.json eslint.config.mjs next.config.ts vitest.config.ts
  playwright.config.ts prisma.config.ts .prettierrc.json` is **empty**.
- **All four frozen contracts hash-verified this run** — api-contract v1.0
  `98f0cc93…`, data-model **v1.1** `e6054a3d…`, tokens v1.0 `08c5cb2f…`,
  motion v1.0 `30e25267…` — **4/4 MATCH** against `state.json`.

---

## Failures

### F-7: raw Zod default text still reaches `details` on container type mismatches

- **Where:** the top-level `z.object(...)` of every input schema
  (`src/shared/schemas/auth.ts`, `clients.ts`, `invoices.ts`), and
  `lineItemsInputSchema` (`src/shared/schemas/invoices.ts:62`).
- **Repro:** `curl` against `next start` on :3551.
- **Output:** 11 distinct probes, all 400 `VALIDATION_FAILED`:
  ```
  POST /clients            body "hello"  -> {"_":"Invalid input: expected object, received string"}
  POST /clients            body 5        -> {"_":"Invalid input: expected object, received number"}
  POST /clients            body null     -> {"_":"Invalid input: expected object, received null"}
  POST /clients            body []       -> {"_":"Invalid input: expected object, received array"}
  POST /auth/signup        body []       -> {"_":"Invalid input: expected object, received array"}
  POST /invoices/{id}/status body "paid" -> {"_":"Invalid input: expected object, received string"}
  PATCH /clients/{id}      body 1        -> {"_":"Invalid input: expected object, received number"}
  POST /invoices  lineItems "nope"       -> {"lineItems":"Invalid input: expected array, received string"}
  POST /invoices  lineItems 5 / {}       -> {"lineItems":"Invalid input: expected array, received number|object"}
  POST /invoices  lineItems OMITTED      -> {"lineItems":"Invalid input: expected array, received undefined"}
  ```
- **Why it matters, and how much:** REQ-009 and the contract both call `details`
  values human-readable and safe to render inline. **But none of these is
  reachable from the app's own forms** — the invoice form always posts a
  well-shaped object with a `lineItems` array. This is the same severity class
  as run-1's F-3 (API-surface only), *not* run-2's F-5 (which a person reached
  by typing). The most plausible one is the omitted `lineItems`: an ordinary
  API-client mistake.
- **Probable owner:** oma-backend — `src/shared/schemas/` is backend-written
  per `stack.md`'s directory contract, and these are the same files as T-025.
- **Filed as:** T-027

### F-8: the dashboard fails completely for contract-legal invoice totals above `Number.MAX_SAFE_INTEGER`

- **Where:** `src/shared/schemas/common.ts:29` —
  `centsSchema = z.number().int().min(0)`. In Zod 4, `.int()` is a **safe-integer**
  check.
- **Repro:** one `POST /api/invoices` with 100 line items at the contract maxima
  (`quantity: 1000000`, `unitPriceCents: 100000000`), then load `/dashboard`.
- **Output:**
  ```
  POST /api/invoices -> 201, "totalCents":10000000000000000   (contract-legal; nothing exceeded)
  sqlite3            -> totalCents = 10000000000000000        (exact)
  GET /api/dashboard -> 200, "outstandingCents":10000000000000000

  zod 4.4.3, z.number().int().min(0).safeParse(10000000000000000)
    -> REJECTED: "Too big: expected int to be <=9007199254740991"

  browser, production build:
    /invoices          renders  $100,000,000,000,000.00      ✔
    /invoices/{id}     renders  every line + total           ✔
    /dashboard         renders  "Couldn't load your dashboard."   ✘  (screenshot)
  ```
- **Why it matters:** the frozen contract declares
  `totalCents: { type: integer, minimum: 0 }` with **no maximum**, so
  `centsSchema` is stricter than the contract it mirrors, and the dashboard's
  `totalsSchema.safeParse` turns that into a whole-screen failure rather than a
  degraded figure. The same break hits `outstandingCents`, which is a **sum over
  all unpaid invoices** and has no contract bound at all. The list and detail
  screens are unaffected, which is what makes it a defect rather than a policy:
  the same data renders in two places and bricks a third.
- **Not a regression from T-026.** SQLite's INTEGER was already 64-bit in v1, so
  this predates ADR-006; run 2 simply never created a total this large (its
  largest was 1e11).
- **Relationship to Q-005:** adjacent, not identical. Q-005 is about JSON-number
  *precision* and needs an api-contract change. F-8 is a code-side schema
  contradicting the frozen contract and is fixable without touching any frozen
  artifact.
- **Probable owner:** oma-backend — `src/shared/schemas/` is backend territory;
  oma-frontend may reasonably argue the subject is the error-state policy in
  `screens/dashboard.md` instead.
- **Filed as:** T-028

---

## Contract conformance spot-check

Probed against `next start` on :3551 (the production build), four accounts,
`curl` with cookie jars, against the frozen `api-contract.yaml`.

**Auth rejection — 9 probes, no cookie:** `GET /dashboard`, `/clients`,
`/invoices`, `/auth/me`, `/invoices/{id}`; `POST /auth/signout`,
`/invoices/{id}/status`; `PATCH /clients/{id}`; `DELETE /invoices/{id}` →
**9/9** `401 UNAUTHENTICATED` + `"Sign in to continue."` ✔

**Error registry — all 8 codes exercised, all conformant:**

| Probe | Expected | Got |
|---|---|---|
| duplicate email, case-differing (`qa-r3a@EXAMPLE.com`) | 409 `EMAIL_TAKEN` | 409 ✔ — server-side lowercasing confirmed |
| signin wrong password | 401 `INVALID_CREDENTIALS` | 401 ✔ |
| no cookie | 401 `UNAUTHENTICATED` | 401 ✔ |
| `POST /clients` name `"   "` | 400 `VALIDATION_FAILED` | 400, `details.name` = "Name is required." ✔ |
| `POST /invoices` unknown `clientId` | 404 `NOT_FOUND` "Client not found." | 404, exact message ✔ |
| `GET /invoices/{unknown}` | 404 `NOT_FOUND` | 404 ✔ |
| `DELETE /clients/{id}` with invoices | 409 `CLIENT_HAS_INVOICES` | 409 ✔ |
| `PATCH` and `DELETE` on a paid invoice | 409 `INVOICE_PAID_LOCKED` | 409 ✔ (both) |
| `PATCH /clients/{id}` with `{}` (minProperties: 1) | 400 | "Provide at least one field to update." ✔ |
| `?status=bogus` / `?page=0` / `?page=abc` / `?page=1.5` | 400 authored prose | ✔ (4/4, T-023 holding) |

`INTERNAL` (500) is the only code not provoked — no safe way to force it from
outside without editing application code, which is not mine to edit.

**Shape and arithmetic:** `POST /invoices` with the contract's own example
figures returned the contract's own numbers — `amountCents` 150000 + 112500,
`totalCents` **262500**, `displayNumber` `"INV-0001"`, `status` `"unpaid"`,
`issueDate` defaulted to `2026-08-12` (today UTC), quantity `7.5` round-tripped.
`GET /invoices` returned `meta: {page:1, pageSize:25, total:N}` with `pageSize`
at the contract's `const: 25`; `?status=paid` / `?status=unpaid` partitioned the
set correctly (1 + 3 = 4).

**Account isolation (REQ-001), two fresh accounts this run — 11/11:**

| B → A's resource | Expected | Got |
|---|---|---|
| `GET`, `PATCH`, `DELETE` on A's client | 404 (never 403 — no existence leak) | 404 ✔ (3/3) |
| `GET`, `PATCH`, `DELETE`, `POST .../status` on A's invoice | 404 | 404 ✔ (4/4) |
| `POST /invoices` using A's `clientId` | 404 "Client not found." | 404 ✔ |
| `GET /invoices` / `GET /clients` (B) | `[]`, total 0 | ✔ |
| `GET /dashboard` (B) | all zeroes | ✔ |

## Mockup parity spot-check

Loaded in a real browser against the production build, plus the frozen mockups
served side by side for comparison.

- **Tokens resolve at runtime, dark palette this time** (run 2 checked light):
  `--color-bg #131511`, `--color-surface #1B1E1A`, `--color-text #EDECE4`,
  `--color-accent #55C495`, `--color-danger #E5766B`, `--radius-md 10px`,
  `--space-4 16px` — every value byte-matches `tokens.json`'s `color.dark`
  block, and `body` computes to `rgb(19,21,17)`, i.e. the token is what paints.
  83 custom properties defined. Frozen `tokens.json` hash unchanged.
- **Empty states are real content on all three surfaces** (fresh account):
  dashboard *"No invoices yet — Create your first invoice and Ledgerly starts
  tracking who owes you."* + CTA; clients *"No clients yet — Add your first
  client — invoices always attach to a client."* + CTA; invoices *"No invoices
  yet — Your first invoice takes about a minute…"* + CTA.
- **Not-found:** `/invoices/doesnotexist123` → *"This invoice doesn't exist — It
  may have been deleted, or the link is wrong."* + "← All invoices".
- **Reduced motion honoured:** under `prefers-reduced-motion: reduce`, every
  non-zero duration under `main` collapses to `1e-06s` (transitions and
  animations both) — clamped, not merely shortened.
- **Print:** under `media: print`, the set of visible `nav` / `button` / `a` /
  `.no-print` elements is **empty** — the printed sheet is the invoice document
  and nothing else. Print-to-PDF of a 1-line invoice is **1 page**.
- **Zero console errors or warnings** across all screens on the production build.
- **Nit (`warn`, not filed):** on the invoice form at desktop width, the inline
  field error under Quantity is constrained to the narrow QTY column, so
  "Quantity must be 1,000,000 or less." wraps to four lines. Legible, not a
  spec violation — the mockup has no error-state rendering at that width to
  compare against.

---

## Verdicts on the three open non-blocking questions

### Q-003 (oma-frontend) — the two <640px deviations — **verdict: accept both; the mockups are wrong, the build is right**

I reproduced both at 375px, mockup and build side by side.

- **(a) invoice form line-item row.** `mockups/invoice-form.html:21` sets
  `.li-row { grid-template-columns: 1fr 1fr 40px }` below 640px with the
  description spanning all tracks — four remaining cells (qty, price, amount,
  remove) into three tracks. Rendered, the mockup shows the computed amount
  **printed on top of the unit-price input** (`1250.00 $1,250.00` overlapping)
  and the remove `×` bumped to its own row. The build's
  `space-16 1fr auto 40px` puts qty/price/amount/remove on one clean row —
  exactly what `screens/invoice-form.md` asks for in prose.
- **(b) invoice document numeric columns.** `mockups/tokens.css:406` gives
  `.doc-table td` `padding: var(--space-3) 0` — zero horizontal padding. The
  mockup renders **`$1,500.00$1,500.00`** and **`TOTAL$2,625.00`** with no gap,
  at every width and on the printed sheet. The build adds `padding-left:
  space-4` (space-3 below 640) on `.num` cells only; the rendered detail page is
  clean at 375px and in print.

Both deviations fix defects that exist in the frozen mockups; neither touches a
token or a frozen artifact. **Recommend: approve, and record them as
mockup errata so a future agent doesn't "restore" them.**

### Q-005 (oma-architect) — totals above `Number.MAX_SAFE_INTEGER` — **verdict: it is real, it is now reproduced, and it is worse than "rounding"**

The architect and backend both described this as theoretical. **It is not.** I
produced the wire/database divergence with one contract-legal POST — 99 lines at
the maxima plus a one-cent line:

```
database totalCents : 9900000000000001
JSON wire totalCents: 9900000000000000     ← one cent lost, silently, rounding DOWN
```

And it is not only single monster invoices: `outstandingCents` is an unbounded
**sum** over unpaid invoices, so the wire figure degrades sooner than any
per-invoice limit implies. On my probe account it read `29999999900000000`.

Two things follow that the user should weigh separately:

1. **Closing Q-005 needs an api-contract change** (an invoice-total bound, or
   lower per-line maxima) — unchanged, and I agree with that framing.
2. **F-8 / T-028 does not.** The dashboard currently *fails outright* in this
   region because of a code-side schema that is stricter than the contract; that
   is fixable today without unfreezing anything, and should be, regardless of
   what the user decides about Q-005.

**Recommend: fix T-028 now; treat Q-005 itself as a documented v1 limitation
unless the user wants an invoice-total bound in v1.1.** The values involved
(a $100-trillion invoice) are absurd for freelance invoicing, which is why the
bound is cheap to add and cheap to defer — but "silently loses a cent above a
threshold nobody wrote in the API docs" is the kind of thing that should be
written down, and right now it is only in an ADR, not in the contract.

### Q-002 (oma-frontend) — dashboard stat captions — **verdict: real, reproduced at both ends; smallest honest fix is a contract addition, and it can wait**

`mockups/dashboard.html:50,55` show a caption under each figure — *"4 unpaid
invoices"*, *"3 invoices paid this month"*. The frozen `/dashboard` shape gives
`outstandingCents`, `paidThisMonthCents`, `invoiceCount`, `recentInvoices[≤10]`
and **no per-status counts**, so the frontend derives the captions from the
recent list and suppresses them when it can't be truthful. Reproduced live:

```
account with  4 invoices -> "OUTSTANDING $4,000.00" + "4 unpaid invoices"   (matches mockup)
account with 12 invoices -> "OUTSTANDING $12,000.00" + no caption            (deviates)
```

The suppression is the right call — a wrong count under the primary figure is
worse than no count. But the deviation appears exactly when an account starts
being used in earnest, which is the opposite of when you want it.

**Recommend: accept as-is for v1 and log it as a v1.1 contract addition**
(`unpaidCount` + `paidThisMonthCount` on `/dashboard`, two integers, no
behaviour change elsewhere). Not worth unfreezing the contract now; do not let
it be "fixed" by inventing a count the API cannot support.

---

## Requirements coverage

Every row verified **this session**. `untested` rows are honest.

| REQ | Acceptance criteria | Verified by | Status |
|---|---|---|---|
| REQ-001 (must) | Signup lands on dashboard | `e2e/auth.spec.ts` (11/11 this run) | ✔ |
| REQ-001 | Signed-out request to any app page redirects to sign-in | `e2e/auth.spec.ts` (dashboard, invoices, clients) | ✔ |
| REQ-001 | Wrong password shows inline error, creates no session | `e2e/auth.spec.ts` + curl 401 `INVALID_CREDENTIALS` + `auth.test.ts` | ✔ |
| REQ-001 | User A's session never returns user B's data | 11-probe isolation matrix, two fresh accounts, this run | ✔ |
| REQ-002 (must) | Create client with name only; email/address optional | curl 201 + `clients.test.ts` + `e2e/core-loop.spec.ts` | ✔ |
| REQ-002 | Edit reflects on existing invoices' send-ready views | live: renamed client → `GET /invoices/{id}` returned the new name/email | ✔ |
| REQ-002 | Client list shows each client's invoice count | live: `GET /clients` → `("Caption Co (renamed)", 12)` | ✔ |
| REQ-002 | Empty name rejected with inline validation | curl → 400 `details.name` "Name is required." | ✔ |
| REQ-003 (must) | Create invoice: select client + 1..n line items | curl 201 + `e2e/core-loop.spec.ts` + `invoices.test.ts` | ✔ |
| REQ-003 | Amounts and total computed, live-updating in the form | `e2e` ($1,500.00 → $2,625.00 pre-save); browser: total updated to $200,000,000.00 as I typed | ✔ |
| REQ-003 | Cannot save with zero line items or no client | `e2e` validation test + curl 400 (both) | ✔ |
| REQ-003 | Unique sequential number per account, visible | live: INV-0001…INV-0012; delete then create → INV-0002 not reused | ✔ |
| REQ-003 | Issue date defaults to today, editable; due date optional | curl: omitted `issueDate` → `2026-08-12`; form shows 12/08/2026 + optional Due | ✔ |
| REQ-003 | Decimal quantities; negative unit prices rejected | 7.5 → 112500 cents live; curl `unitPriceCents:-1` → 400 authored; `money.test.ts` | ✔ |
| REQ-004 (must) | Detail view shows number, dates, client, all line items, total | `e2e/core-loop.spec.ts` + loaded live (1-line and 100-line invoices) | ✔ |
| REQ-004 | Print-clean: no app chrome | print-media probe: **zero** visible nav/button/link elements; body text is the document only | ✔ |
| REQ-004 | Paid/unpaid status visible on the view | `e2e` + live detail shows UNPAID / PAID stamp | ✔ |
| REQ-004 | Print yields *one page per invoice* | print-to-PDF: 1-line invoice = **1 page** | ✔ (a 100-line invoice spans 5 pages — physically unavoidable, not a defect) |
| REQ-005 (must) | Exactly two statuses, unpaid on creation | contract enum + every create returned `"unpaid"` | ✔ |
| REQ-005 | One-click toggle from detail **and** list, no full reload | detail: `e2e`; **list: driven in a browser this run** — row went UNPAID→PAID and a `window` marker survived, proving no full reload | ✔ |
| REQ-005 | Marking paid records a paid date; reverting clears it | curl: paid → `paidDate 2026-08-12`; unpaid → `paidDate null` | ✔ |
| REQ-005 | Dashboard totals reflect the change on next load | curl: outstanding 262500→0 / paidThisMonth 0→262500, and back | ✔ |
| REQ-006 (must) | Outstanding total is the primary figure | live `/dashboard` + exact arithmetic + `dashboard.test.ts` | ✔ |
| REQ-006 | Total paid for current calendar month | curl round-trip above + `dashboard.test.ts` UTC month-boundary cases | ✔ |
| REQ-006 | 10 most recent invoices, each linking to detail | live: 12 invoices → `recentInvoices` length 10, rows link to detail | ✔ |
| REQ-006 | Zero invoices → empty state with CTA | loaded live on a fresh account | ✔ |
| REQ-006 | *(defect found)* dashboard renders for any contract-legal total | — | **✘ F-8 / T-028** — whole screen fails above `Number.MAX_SAFE_INTEGER` |
| REQ-007 (should) | List shows all invoices newest-first with the 5 columns | live list + `invoices.test.ts` ordering cases | ✔ |
| REQ-007 | Filter all/unpaid/paid, reflected in the URL | **driven in a browser this run**: clicking Unpaid → `/invoices?status=unpaid`, no full reload; `?status=paid` on reload filtered correctly | ✔ |
| REQ-007 | Each row links to detail | live: every row's `href` is `/invoices/{id}`, followed one | ✔ |
| REQ-008 (should) | Unpaid invoice editable, totals recompute on save | `invoices.test.ts` PATCH cases + `e2e/paid-lock.spec.ts` | ✔ |
| REQ-008 | Paid invoice's edit affordance disabled, reason shown | `e2e/paid-lock.spec.ts` + curl 409 on PATCH and DELETE | ✔ |
| REQ-008 | Unpaid invoice deletable after confirmation; number not reused | `e2e` confirm-dialog delete + live: deleted INV-0001, next create was INV-0002 | ✔ |
| REQ-009 (should) | Purposeful empty states on clients, invoices, dashboard | all three loaded live on a fresh account, real copy + CTA | ✔ |
| REQ-009 | Every submission failure shows an inline human-readable message | 130-pair schema fuzz: **all field-level messages authored**; browser repro fixed | ✔ for every form-reachable path — **✘ for API-only container type errors (F-7 / T-027)** |
| REQ-009 | Nonexistent invoice/client id → friendly not-found with a link back | loaded live: "This invoice doesn't exist" + "← All invoices" | ✔ |
| REQ-010 (should) | 375px: no horizontal scroll, all actions reachable | **tested this run** (was untested in runs 1–2): `/dashboard`, `/invoices`, `/clients`, `/invoices/new`, `/signin` all `scrollWidth == clientWidth == 375`, zero overflowing elements; row-cards, filter tabs, toggles and the sticky Save bar all present and tappable | ✔ |
| REQ-010 | ≥1024px: list pages use a tabular layout | **tested this run**: `/invoices`, `/clients`, `/dashboard` each render a real `<table>` with `display: table-row` rows and the specified headers | ✔ |

Every `must` REQ (001–006) is verified, with **one defect against REQ-006**
(F-8). REQ-009 is verified for every path a form can reach, with an API-only
gap (F-7). REQ-010 moves from `untested` to verified — the two rows run 1 and
run 2 both left open are now closed. **No `untested` rows remain.**

---

## Verdict

**Pipeline fully green — install 0, typecheck 0, lint 0, build 0, unit 0
(180/180), e2e 0 (11/11), format:check 0. Both run-2 fixes verified real under
my own probing: T-025's authored messages survive a 130-pair schema fuzz and 5
independent message mutations; T-026's migration is provably data-preserving,
the Postgres DDL now emits BIGINT, and 3 of my own truncation mutations turn the
suite red. No regression in anything run 2 verified, no weakened assertion, no
config drift, 4/4 frozen contracts hash-intact. 2 new failures filed as T-027
and T-028. Loop iteration 3 of 3 — final.**

I do not decide ship/no-ship; the user gates. My read:

**Ship — with T-028 fixed first.** The core loop is solid and has now been
verified end to end three different ways (unit, e2e, and by hand through the
real UI and the real API). Nothing in this run touched the paths a freelancer
actually walks. Specifically:

- **T-028 is the only finding I would hold the gate for**, and only just. A
  whole screen failing is a bad failure mode, the trigger is inside the
  contract's own stated limits, and the fix is one schema line plus a test —
  minutes, no frozen artifact involved. Leaving it in means shipping a screen
  that dies rather than degrades, on data the API itself hands it.
- **T-027 is not worth holding the gate for.** No form can reach it; it is
  polish on the API surface. Fix it in the same pass as T-028 if you're touching
  those files anyway.
- **Q-003: approve both deviations** and record them as mockup errata.
- **Q-002: accept for v1**, log the two count fields as a v1.1 contract addition.
- **Q-005: decide, don't necessarily implement.** I reproduced a real one-cent
  wire/database divergence, so it is no longer hypothetical — but it needs a
  $99-trillion invoice to appear. Writing the limitation into the contract is
  the honest minimum; bounding invoice totals is the fix, and it can be v1.1.

The thing worth stating plainly, because it is what this loop was for: across
three runs, **24 mutations of my own choosing** have been applied to this
codebase, and every one that describes a real, contract-reachable defect turned
the suite red, with a no-op control green each time. This suite is not
decoration, and the two fix rounds arrived without a single relaxed assertion.

## Housekeeping

- **Servers stopped.** `next start` :3551 and the static mockup server :3552
  both killed; ports 3551, 3552, 3411, 3521, 3531, 3541 all confirmed down.
- **Working tree clean** (`git status --short` empty at end of run). All 14
  mutations reverted with `git checkout --`; the scratch probe directory I used
  for the schema fuzz and the browser probes was deleted, and the full pipeline
  was re-run afterwards to prove the green verdicts belong to the committed
  tree, not to my scratch.
- **No application file was modified by QA this run.** `e2e/` is unchanged from
  run 1.
- **Probe data left in the gitignored `data/ledgerly.db`:** accounts
  `qa-r3a@example.com`, `qa-r3b/c/d@example.test` and their invoices, including
  the F-8 evidence invoice (`totalCents 10000000000000000`, account
  `qa-r3c@example.test`) and the Q-005 evidence invoice (`totalCents
  9900000000000001`, account `qa-r3a@example.com`). Both are the evidence behind
  this report — delete the file to reset.
