# ADR-001: SQLite now, with Postgres-portability guardrails

- **Status:** accepted
- **Date:** 2026-08-12
- **Decider:** oma-architect
- **Requirements affected:** REQ-001..REQ-008 (all persistence); resolves open question Q-001

## Context

The brief fixes `db: sqlite` for the local/demo v1, but the stated ambition is
a public-facing SaaS later, which means Postgres. Q-001 (from the PM) asks for
confirmation that nothing in the design bakes in SQLite-only assumptions that
would block that move. Prisma abstracts most of the difference, but three traps
remain: autoincrement/rowid id schemes, raw SQL, and SQLite's loose typing
(no enums, no real decimals).

## Decision

We will use SQLite through Prisma's driver-adapter seam
(`@prisma/adapter-better-sqlite3` in `src/server/db.ts`) and confine every
database-specific fact to that one file, with these binding rules:

- **IDs are app-generated `cuid(2)` strings** for every entity — no
  `AUTOINCREMENT`, no rowid dependence, no id scheme that changes meaning
  across engines. (This ADR is also the project's id-scheme decision.)
- **No raw SQL** (`$queryRaw` / `$executeRaw`) anywhere; Prisma Client API only.
- **No SQLite pragmas in app code** — WAL setup lives inside `db.ts` only.
- **Enum-like columns are strings** (`Invoice.status`) validated by Zod and
  the service layer, since SQLite has no enum type; a Postgres migration may
  add a native enum/CHECK later without an API change.
- **Numbers are integers** (cents/thousandths, ADR-003) and dates are UTC
  `DateTime` — nothing leans on SQLite's NUMERIC affinity.
- Sessions live in the database, not in-process (ADR-002), so auth is already
  multi-instance-safe.

The v2 Postgres move is then: swap the adapter in `db.ts`, change the
datasource provider, regenerate migrations, copy data. No service, route, or
schema-shape changes.

## Alternatives considered

| Option | Why not |
|---|---|
| Postgres now (ignore the override) | Violates the explicit override; adds a server dependency to a local demo for zero v1 benefit |
| SQLite with autoincrement integer ids | Cheapest today, but id semantics and FK values would need rewriting at migration time — the exact trap Q-001 asks us to avoid |
| Dual-provider Prisma schema maintained from day one | Speculative generality; doubles migration maintenance for a future that may not arrive |

## Consequences

- Single-writer SQLite is fine for one user; we deliberately add no pooling or
  concurrency knobs.
- Devs lose raw-SQL escape hatches; any query Prisma can't express forces a
  design conversation instead of a dialect-specific hack — intended.
- Status integrity relies on the service layer until Postgres adds a CHECK.
- **Undo cost:** low by construction — the decision's whole point is that
  reversing (moving to Postgres) touches one file, the Prisma datasource, and
  a data copy script. Abandoning cuid2 ids later, by contrast, would be a
  full-table rewrite; we accept that lock-in.
