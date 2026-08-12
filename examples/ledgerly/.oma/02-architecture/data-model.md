# Data model — Ledgerly

> Authoritative entity design. Backend implements this in `prisma/schema.prisma`
> verbatim; Frontend treats the API schemas derived from it as fixed. Every
> entity cites the REQ that demands it. IDs are app-generated `cuid(2)` strings
> everywhere (ADR-001). All `DateTime` values are UTC. Money is integer cents,
> quantity is integer thousandths (ADR-003), and every such column is **64-bit
> `BigInt`** so that contract-legal values survive the v2 Postgres move
> (ADR-006). Counters and ordinals (`nextInvoiceNumber`, `number`, `position`)
> stay 32-bit `Int` — they are not money.

## Entity: User  (REQ-001)

| Field | Type | Null | Default | Notes |
|---|---|---|---|---|
| id | String (cuid2) | no | cuid(2) | PK |
| email | String | no | — | stored lowercased; **unique** |
| passwordHash | String | no | — | argon2id PHC string (ADR-002) |
| nextInvoiceNumber | Int | no | 1 | per-account monotonic counter (ADR-004) |
| createdAt | DateTime | no | now() | |
| updatedAt | DateTime | no | @updatedAt | |

- **Unique:** `email` — sign-in lookup and duplicate-signup rejection.
- **Relations:** 1—N Session, 1—N Client, 1—N Invoice.
- **Delete stance:** no user deletion in v1 (no REQ demands it).

## Entity: Session  (REQ-001)

| Field | Type | Null | Default | Notes |
|---|---|---|---|---|
| id | String (cuid2) | no | cuid(2) | PK |
| tokenHash | String | no | — | SHA-256 of the cookie token; **unique**. Raw token never stored. |
| userId | String | no | — | FK → User, `onDelete: Cascade` |
| expiresAt | DateTime | no | — | 30-day sliding (ADR-002) |
| createdAt | DateTime | no | now() | |

- **Unique:** `tokenHash` — the per-request session lookup.
- **Index:** `userId` — sign-out-everywhere / cleanup by user.
- **Delete stance:** hard delete on sign-out and on expiry sweep.

## Entity: Client  (REQ-002)

| Field | Type | Null | Default | Notes |
|---|---|---|---|---|
| id | String (cuid2) | no | cuid(2) | PK |
| userId | String | no | — | FK → User, `onDelete: Restrict` |
| name | String | no | — | non-empty after trim (Zod; REQ-002 rejects empty) |
| email | String? | yes | null | optional per REQ-002 |
| address | String? | yes | null | free-form multiline text; rendered as-is on send-ready view |
| createdAt | DateTime | no | now() | |
| updatedAt | DateTime | no | @updatedAt | |

- **Index:** `userId` — every client query is account-scoped (REQ-001 isolation).
- **Relations:** 1—N Invoice (`onDelete: Restrict` from Invoice side).
- **Delete stance:** hard delete allowed ONLY when the client has zero
  invoices; service checks count and returns `CLIENT_HAS_INVOICES` otherwise
  (REQ-002 notes, scope.md). The DB `Restrict` FK is the backstop.
- Client edits propagate to invoice views automatically because invoices
  reference the client row rather than snapshotting it (REQ-002: "change is
  reflected on that client's existing invoices' send-ready views").

## Entity: Invoice  (REQ-003, REQ-004, REQ-005, REQ-007, REQ-008)

| Field | Type | Null | Default | Notes |
|---|---|---|---|---|
| id | String (cuid2) | no | cuid(2) | PK |
| userId | String | no | — | FK → User, `onDelete: Restrict` |
| clientId | String | no | — | FK → Client, `onDelete: Restrict` |
| number | Int | no | — | assigned from `User.nextInvoiceNumber` in the create transaction (ADR-004); displayed as `INV-` + zero-padded-4 |
| status | String | no | "unpaid" | `"unpaid" \| "paid"` — Zod-enforced enum; SQLite has no enum type (ADR-001) |
| issueDate | DateTime | no | — | date-only semantics: UTC midnight; defaults to "today" in the service, editable (REQ-003) |
| dueDate | DateTime? | yes | null | date-only semantics; optional (REQ-003) |
| paidAt | DateTime? | yes | null | date-only semantics; set when marked paid (defaults to today, REQ-005); MUST be null when status = unpaid |
| totalCents | BigInt | no | — | denormalized sum of line `amountCents`; recomputed server-side on every create/edit — never trusted from the client (REQ-003, REQ-006). **64-bit** (ADR-006): the frozen contract admits ≤100 lines × 10^14 cents each, far past 32-bit |
| createdAt | DateTime | no | now() | |
| updatedAt | DateTime | no | @updatedAt | |

- **Unique:** `(userId, number)` — per-account sequential numbering integrity
  (REQ-003).
- **Indexes:**
  - `(userId, status)` — dashboard outstanding sum and list status filter
    (REQ-006, REQ-007).
  - `(userId, issueDate)` — newest-first list and 10-most-recent dashboard
    query (REQ-006, REQ-007).
- **Invariants (service-enforced):** ≥1 line item at all times; `status="paid"`
  ⇔ `paidAt` set; paid invoices reject content edits and deletion with
  `INVOICE_PAID_LOCKED` (REQ-008); `totalCents` always equals the sum of its
  line items' `amountCents`.
- **Delete stance:** hard delete of UNPAID invoices only, after client-side
  confirmation (REQ-008); line items cascade. The consumed number is never
  reused (counter never decrements — ADR-004). Paid invoices cannot be deleted
  in v1 (revert to unpaid first — same rule as editing).

## Entity: InvoiceLineItem  (REQ-003)

| Field | Type | Null | Default | Notes |
|---|---|---|---|---|
| id | String (cuid2) | no | cuid(2) | PK |
| invoiceId | String | no | — | FK → Invoice, `onDelete: Cascade` |
| position | Int | no | — | 0-based display order, contiguous per invoice |
| description | String | no | — | non-empty after trim |
| quantityThousandths | BigInt | no | — | quantity × 1000; > 0. `7.5` hours → `7500` (ADR-003). **64-bit** (ADR-006): contract max quantity 10^6 → 10^9 thousandths, inside 32-bit but widened with its siblings so the whole `amountCents` multiplication is one numeric domain |
| unitPriceCents | BigInt | no | — | ≥ 0; negative prices rejected (REQ-003 notes). **64-bit** (ADR-006) — contract max 10^8 fits 32 bits, widened for domain consistency with `amountCents` |
| amountCents | BigInt | no | — | `round(quantityThousandths × unitPriceCents / 1000)`, computed server-side. **64-bit** (ADR-006): contract-legal maximum is 10^14 cents, ~46,000× the 32-bit ceiling |

- **Index:** `invoiceId` — line items are only ever fetched by invoice.
- **Delete stance:** cascades with invoice; on invoice edit the service
  replaces the full line-item set transactionally (simplest correct shape for
  ≤ dozens of lines; no per-line PATCH surface).
- No `userId`: ownership is derived through Invoice; line items are never
  queried outside their aggregate.

## Numeric column widths and the API boundary (ADR-006)

`BigInt` is a **storage and in-service** decision only. The API contract is
frozen and unchanged: `*Cents` fields remain JSON numbers, and `quantity`
remains a JSON number with ≤3 decimals. Nothing on the wire moves.

| Column | Type | Contract-legal max | 32-bit? |
|---|---|---|---|
| `InvoiceLineItem.quantityThousandths` | BigInt | 10^9 (quantity ≤ 10^6) | fits, widened for consistency |
| `InvoiceLineItem.unitPriceCents` | BigInt | 10^8 | fits, widened for consistency |
| `InvoiceLineItem.amountCents` | BigInt | 10^14 | **no** |
| `Invoice.totalCents` | BigInt | 10^16 (100 lines × 10^14) | **no** |
| `User.nextInvoiceNumber`, `Invoice.number`, `InvoiceLineItem.position` | Int | small | yes — deliberately unchanged |

Rules this places on the service layer (Backend implements, QA verifies):

- Prisma surfaces these columns as JS `BigInt`. **Serialize to JSON `number`**
  at the response boundary — never as a string, never via a global
  `BigInt.prototype.toJSON` that would leak `"100"` into unrelated payloads.
  The contract's examples are bare numbers and Frontend parses them as such.
- Zod parses inbound values as `number` (contract shape) and converts to
  `BigInt` in `src/shared/schemas/` — the same single conversion seam ADR-003
  already designates. No conversion anywhere else.
- Aggregates (`SUM` for the dashboard outstanding total) return `BigInt`; keep
  them exact through the sum and convert once, at serialization.
- **Residual, out of scope here:** the frozen contract's own worst case
  (100 lines at maximum values) reaches `totalCents` 10^16, which exceeds
  JavaScript's `Number.MAX_SAFE_INTEGER` (~9.007×10^15) and would lose
  precision *on the wire*, not in the database. Closing that needs a contract
  edit (a total bound or per-line maxima) and is therefore a separate change
  request — recorded in ADR-006, not fixed by it.

## Aggregate lifecycles

### User (aggregate root: User + Sessions)
- **Created by:** `POST /api/auth/signup` — hashes password, creates user +
  first session in one transaction.
- **Mutated by:** `nextInvoiceNumber` increments inside invoice-create
  transactions. No profile editing in v1.
- **Deleted by:** nothing in v1.

### Session
- **Created by:** signup and signin. **Mutated by:** sliding-expiry refresh.
- **Deleted by:** signout (own row), expiry sweep on lookup.

### Client
- **Created by:** `POST /api/clients` (name required).
- **Mutated by:** `PATCH /api/clients/{id}` — edits visible on all existing
  invoice views immediately (live reference, no snapshot).
- **Deleted by:** `DELETE /api/clients/{id}` — only when invoice count = 0.

### Invoice (aggregate root: Invoice + InvoiceLineItems)
- **Created by:** `POST /api/invoices` — one transaction: validate client
  ownership, read-and-increment `User.nextInvoiceNumber`, insert invoice +
  lines, compute `amountCents`/`totalCents` server-side. Status starts
  `unpaid`.
- **Mutated by:**
  - `PATCH /api/invoices/{id}` (unpaid only): client, dates, full line-item
    replacement; totals recomputed (REQ-008).
  - `POST /api/invoices/{id}/status`: unpaid→paid sets `paidAt` (provided
    date or today); paid→unpaid clears `paidAt` and unlocks editing (REQ-005).
- **Deleted by:** `DELETE /api/invoices/{id}` — unpaid only; hard delete,
  lines cascade, number retired forever.

## Query patterns the indexes serve

| Query | REQ | Index used |
|---|---|---|
| Session lookup per request | REQ-001 | Session.tokenHash unique |
| Sign-in by email | REQ-001 | User.email unique |
| Client list + invoice counts | REQ-002 | Client.userId + Invoice count by clientId (via `(userId, status)` prefix is insufficient — Prisma `_count` uses the Invoice.clientId FK; SQLite auto-indexes FKs are NOT automatic, so Backend adds `@@index([clientId])` on Invoice) |
| Outstanding total (sum unpaid) | REQ-006 | Invoice `(userId, status)` |
| Paid this calendar month | REQ-006 | Invoice `(userId, status)` + paidAt range filter |
| Recent 10 by issue date | REQ-006 | Invoice `(userId, issueDate)` |
| List newest-first, status filter | REQ-007 | Invoice `(userId, status)` / `(userId, issueDate)` |

Note the explicit addition: **Invoice also carries `@@index([clientId])`** for
the per-client counts on the client list page.
