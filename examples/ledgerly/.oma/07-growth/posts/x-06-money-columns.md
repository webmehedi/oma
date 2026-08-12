<!-- Pillar: Build in public (things that broke)
     Day 4 · X/Twitter · single post
     Rests on: T-026 / D-003 / ADR-006 — Prisma Int money columns capped totalCents near
       $21.5M and broke the ADR-001 Postgres-portability promise; migrated to BigInt and
       QA verified the migration data-preserving and the emitted Postgres DDL as BIGINT.
     Asset: A10 (screenshot of the migration diff, or the schema before/after).
     Drafted by OMA. Nothing is posted for you. -->

# X — day 4

## Post — attach asset A10

```
The money columns in my invoicing app were 32-bit ints. Max invoice total: about
$21.5M.

No freelancer will ever hit that. But I'd written down "this can move to
Postgres later", and 32-bit money made that quietly false.

Migrated to BIGINT. The bug was the promise, not the ceiling.
```

Fits 280 as written; recount if you edit.

## Asset

**A10** — the migration, or the two schema lines side by side. A code screenshot
is fine here; make sure it's legible at feed size, which usually means eight
lines maximum.

## Before you publish

- The point of this post is the last line, and it generalises past invoicing:
  the defect was a documented guarantee going silently untrue, not the number.
  If you shorten anything, don't shorten that.
- Don't claim you caught it in review if you didn't. [[TODO: how did you
  actually find it? If it was a test or a QA pass, say so — "my own test caught
  it" is a more useful post than "I noticed".]]
