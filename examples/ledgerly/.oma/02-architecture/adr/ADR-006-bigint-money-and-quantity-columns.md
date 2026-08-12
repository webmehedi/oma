# ADR-006: 64-bit `BigInt` columns for money and quantity

- **Status:** accepted
- **Date:** 2026-08-12
- **Decider:** oma-architect (change request; decision D-003 approved by user via `/oma:change`)
- **Requirements affected:** REQ-003, REQ-006, REQ-008 (money storage); ADR-001's portability guarantee
- **Supersedes:** the column widths in ADR-003, not its representation. Money is
  still integer cents and quantity still integer thousandths — only the width changes.

## Context

QA run 2 (finding F-6, task T-026) proved a contradiction between two frozen
artifacts, under a guarantee a third one makes:

- `api-contract.yaml` `LineItemInput` allows `quantity` ≤ 1,000,000 and
  `unitPriceCents` ≤ 100,000,000, with `maxItems: 100` line items. The legal
  maximum `amountCents` is therefore 10^14, and `totalCents` 10^16.
- `data-model.md` declared `totalCents`, `amountCents`, `unitPriceCents` and
  `quantityThousandths` as `Int`. Prisma `Int` is a 4-byte `INTEGER` on
  PostgreSQL — max 2,147,483,647.
- ADR-001 makes the v2 Postgres move "swap the adapter, change the provider,
  regenerate migrations, copy data. No service, route, or schema-shape
  changes." That promise is the entire justification for accepting the
  `db: sqlite` override.

On the shipped stack there is **no v1 malfunction**. SQLite's INTEGER is
64-bit; QA wrote a live invoice at `totalCents` 100,000,000,000 and read it
back exactly through the API, the list and the dashboard. That is precisely
what makes this dangerous: SQLite silently accepts rows that a Postgres
`integer` column would reject, so the defect is invisible until migration day,
when it appears as failed inserts or silent truncation of customers' invoice
totals. Backend's Q-004 reported a "$21.5M cap" in v1; QA disproved the
premise and located the real defect one layer down.

The contract's wire format is unaffected either way — JSON has one numeric
type, and `*Cents` values are already plain JSON numbers.

## Decision

We will widen every monetary and quantity column to 64-bit `BigInt`:
`Invoice.totalCents`, `InvoiceLineItem.amountCents`,
`InvoiceLineItem.unitPriceCents`, `InvoiceLineItem.quantityThousandths`.

- `data-model.md` is amended (this change request's only contract edit). The
  **API contract is untouched and stays frozen** — no wire-format change, no
  new version, no Frontend impact.
- `unitPriceCents` and `quantityThousandths` fit 32 bits at contract maxima and
  are widened anyway, so that the entire `amountCents = round(qty × price /
  1000)` multiplication lives in one numeric domain. A mixed-width money model
  invites exactly the reasoning error that produced Q-004.
- Counters and ordinals — `User.nextInvoiceNumber`, `Invoice.number`,
  `InvoiceLineItem.position` — stay `Int`. They are bounded by human behaviour,
  not by money, and widening them would blur what the type is signalling.
- Backend implements the Prisma schema change and an additive migration next;
  `BigInt`→JSON `number` serialization rules are specified in data-model.md's
  "Numeric column widths and the API boundary" section.

## Alternatives considered

| Option | Why not |
|---|---|
| Tighten `api-contract.yaml` maxima so the product fits 32 bits | Requires unfreezing and re-versioning the public contract, and narrowing a promise already made to two agents built against it. It also caps a single line item near $21M, which a real freelancer invoicing a large project could plausibly exceed — we would be shrinking the product to fit a column. |
| Do nothing; document the ceiling as a known v1 limit | Leaves ADR-001's portability guarantee false in writing. The failure surfaces at migration time on real customer data, which is the worst possible moment to discover it. The user rejected this (D-003). |
| Prisma `Decimal` for money | Already rejected by ADR-003 for the reason that still holds: on SQLite it degrades to NUMERIC/float affinity. Re-opening it here would reverse the sound decision to fix the unsound one. |
| Widen only `totalCents` and `amountCents` (the two that actually overflow) | Minimal, but leaves the money model split across two widths with no principle a reader can apply. The saving is a few bytes per row on a single-user app. |

## Consequences

- ADR-001's portability guarantee becomes **true again**: every contract-legal
  row now fits Postgres `bigint`, and the v2 move stays an adapter-and-provider
  swap with no data surgery.
- ADR-003 is **reinforced, not weakened**. Integer-cents representation is
  unchanged; the conversion seam in `src/shared/schemas/` remains the single
  place decimals become integers. Only the storage width moves.
- Prisma surfaces these fields as JS `BigInt`, so the service layer must
  convert at the response boundary and in test fixtures. This is mechanical but
  touches every invoice-shaped assertion — Backend and QA should expect the
  test suite to need updating, not just the schema.
- Storage cost is 4 extra bytes per column per row. Irrelevant here.
- **Known residual, not closed by this ADR:** the contract's absolute worst
  case (100 lines at maximum values) gives `totalCents` = 10^16, above
  JavaScript's `Number.MAX_SAFE_INTEGER` (~9.007×10^15). The database is exact;
  JSON serialization would not be. Closing it requires an invoice-total bound
  or lower per-line maxima in the frozen contract — a separate change request,
  deliberately not bundled into this one. It is far outside plausible freelance
  invoicing, whereas the 32-bit ceiling this ADR fixes was reachable with a
  single line item.
- **Undo cost: low, and asymmetric on purpose.** Reverting `BigInt`→`Int` is one
  migration, but only while no row exceeds 2,147,483,647; past that, reverting
  means truncating money, which is not a reversal any migration can honestly
  perform. Doing this *now*, before real data exists, is what keeps the cost
  low — the same change after launch would be a downtime migration over the
  invoice table. Contrast ADR-003's undo cost (high): changing money
  *representation* remains a full contract break. Width is cheap; representation
  is not.
