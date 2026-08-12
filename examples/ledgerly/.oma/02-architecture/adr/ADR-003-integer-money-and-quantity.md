# ADR-003: Money as integer cents, quantity as integer thousandths

- **Status:** accepted
- **Date:** 2026-08-12
- **Decider:** oma-architect
- **Requirements affected:** REQ-003, REQ-005, REQ-006, REQ-008

## Context

Invoice totals are the product's trust anchor — the dashboard's outstanding
figure must be exactly right (REQ-006), and line amounts are quantity × unit
price with decimal quantities like 7.5 hours (REQ-003). IEEE floats cannot
represent most decimal fractions, SQLite has no true DECIMAL type (NUMERIC
affinity silently degrades to float), and Prisma's `Decimal` on SQLite rides
on that same affinity. Single currency (USD) is fixed for v1.

## Decision

We will represent all monetary values as integer cents and all quantities as
integer thousandths, end to end:

- DB: `unitPriceCents Int`, `amountCents Int`, `totalCents Int`,
  `quantityThousandths Int`.
- API: `*Cents` fields are integers; `quantity` is a JSON number with at most
  3 decimals (`multipleOf 0.001`), converted to/from thousandths at the Zod
  boundary.
- Computation happens server-side only:
  `amountCents = round(quantityThousandths × unitPriceCents / 1000)`;
  `totalCents = Σ amountCents`. Client-submitted totals are ignored.
- Dollars exist only in display formatting (`$2,625.00`), Frontend's job.

## Alternatives considered

| Option | Why not |
|---|---|
| Float dollars | `0.1 + 0.2 !== 0.3`; totals drift and the dashboard becomes untrustworthy — the one unforgivable bug in this product |
| Prisma `Decimal` | On SQLite it degrades to NUMERIC/float affinity; also complicates the v2 Postgres copy (ADR-001) |
| String-encoded decimals | Pushes parsing/rounding policy to every consumer; two agents would round differently |
| Integer cents but float quantity | Reintroduces float error inside the one multiplication that produces money |

## Consequences

- Arithmetic is exact and portable across SQLite and Postgres; all values fit
  comfortably in 64-bit (and within JS safe integers at enforced maxima).
- Everyone must remember the ×100/×1000 conventions; the Zod schemas in
  `src/shared/schemas/` are the single place conversion is allowed, which
  keeps the rule mechanical.
- Rounding policy (round-half-up per line, then sum) is fixed and documented;
  per-line rounding matches what a client recomputing by hand would get.
- **Undo cost:** high — changing representation later means migrating every
  monetary column and every API field simultaneously; effectively a v2
  contract break. We accept this because integers-for-money is the
  industry-boring choice.
