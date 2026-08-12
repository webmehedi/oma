# ADR-005: Hard deletes with a paid-lock, no soft-delete machinery

- **Status:** accepted
- **Date:** 2026-08-12
- **Decider:** oma-architect
- **Requirements affected:** REQ-002, REQ-005, REQ-008

## Context

The project needs a deletion stance per entity. The PRD allows deleting
unpaid invoices (number never reused, REQ-008) and zero-invoice clients
(REQ-002); paid invoices are locked from editing to keep paid totals
trustworthy. Soft delete (a `deletedAt` column) is the usual reflex, but
every query in the system would then need a `deletedAt IS NULL` filter that
two parallel dev agents could each forget independently.

## Decision

We will hard-delete, guarded by state checks, with no `deletedAt` columns
anywhere:

- **Unpaid invoice:** hard delete allowed; line items cascade
  (`onDelete: Cascade`); the number is retired (ADR-004). Confirmation is a
  UI step, not an API handshake.
- **Paid invoice:** delete AND edit rejected with `INVOICE_PAID_LOCKED`; the
  only mutation allowed is status reversion to unpaid (which clears `paidAt`
  and unlocks it). Lock enforced in the invoice service, the single Prisma
  gateway.
- **Client:** hard delete only when its invoice count is 0, else
  `CLIENT_HAS_INVOICES`; the `onDelete: Restrict` FK is the DB backstop.
- **User / Session:** users are never deleted in v1; sessions hard-delete on
  signout/expiry.

## Alternatives considered

| Option | Why not |
|---|---|
| Soft delete everywhere | Every list, count, sum, and uniqueness check must filter tombstones; one missed filter corrupts the dashboard totals — highest-blast-radius bug class for zero v1 requirement (no undo/trash REQ exists) |
| Soft delete for invoices only | Same filter tax on the hottest queries (dashboard sums, lists); REQ-008's "number not reused" is already satisfied by the counter, not by keeping the row |
| No deletion at all | Fails REQ-008 (delete unpaid invoice) and REQ-002 (delete zero-invoice client) |
| Audit/event log instead of tombstones | Speculative — no REQ asks for history; adds write-path complexity to every mutation |

## Consequences

- Queries stay simple and totals stay trivially correct — no tombstone
  filtering anywhere, which is worth more than recoverability v1 doesn't
  promise.
- Deleted data is genuinely gone; the UI confirmation step (REQ-008) is the
  only safety net. Acceptable for a local/demo v1.
- The paid-lock lives in one service, so Frontend can trust that a `paid`
  invoice's edit affordance being absent matches server behavior exactly.
- **Undo cost:** moderate — introducing soft delete later (e.g. a v2 trash
  feature) is an additive migration (`deletedAt` column + query filters), but
  data hard-deleted before that point is unrecoverable by design.
