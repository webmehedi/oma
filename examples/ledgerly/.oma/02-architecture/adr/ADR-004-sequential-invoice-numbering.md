# ADR-004: Per-account invoice numbering via a counter column

- **Status:** accepted
- **Date:** 2026-08-12
- **Decider:** oma-architect
- **Requirements affected:** REQ-003, REQ-008

## Context

REQ-003 requires unique sequential per-account invoice numbers (INV-0001
style); REQ-008 requires that a deleted invoice's number is never reused.
Numbers must be gapless-looking under normal use but survive deletions
without renumbering. Candidate mechanisms: database autoincrement, MAX(n)+1
at insert time, or an explicit per-user counter.

## Decision

We will keep a `nextInvoiceNumber Int` counter on the User row. Invoice
creation runs one transaction that reads the counter, assigns it to the new
invoice's `number`, and increments it. The counter never decrements —
deleting an invoice retires its number permanently. `(userId, number)` is
unique in the database as the integrity backstop. Display form is `INV-` +
number zero-padded to 4 digits (grows naturally past 9999), derived — never
stored.

## Alternatives considered

| Option | Why not |
|---|---|
| DB autoincrement id as the number | Global, not per-account (user B would see gaps from user A's activity); also rowid-coupled, violating ADR-001 portability |
| `MAX(number)+1` at insert | Reuses a deleted highest number, violating REQ-008; racy without a lock even in theory |
| Separate `Counter` table | Same semantics as the column with an extra join; the column is simpler and the User row is already in the transaction |
| UUID/random numbers | Fails the REQ outright — freelancers' clients expect sequential invoice numbers |

## Consequences

- Number assignment is trivially correct on SQLite (single writer) and stays
  correct on Postgres because the counter update is a row-level-locked
  read-modify-write in a transaction (ADR-001 portability holds).
- Deleting invoice N leaves a visible gap (…N-1, N+1…). This is standard
  bookkeeping behavior and the PRD explicitly accepts it.
- Invoice creation serializes per user on the User row — irrelevant at
  single-user scale, and the correct behavior at any scale.
- **Undo cost:** low-to-moderate — switching mechanisms later (e.g. a
  sequences table per account) preserves all existing numbers because they
  are stored denormalized on each invoice; only the assignment code changes.
