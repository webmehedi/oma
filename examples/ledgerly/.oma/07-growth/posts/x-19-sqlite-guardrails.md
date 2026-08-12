<!-- Pillar: Useful & unrelated
     Day 26 · X/Twitter · 2-post thread
     Rests on: ADR-001's portability guardrails as written in stack.md (no raw SQL, no
       SQLite pragmas in app code beyond the adapter file, app-generated cuid2 ids,
       integer money, UTC dates, enum-likes constrained at the boundary) and QA run-3's
       check: swapping only the datasource provider emitted BIGINT Postgres DDL.
     Asset: none, or A10 (the four-line guardrail list as a code screenshot).
     Drafted by OMA. Nothing is posted for you. -->

# X — day 26

## Post 1/2

```
Running SQLite in production for a single-user app is fine. Keeping the option
to leave is the actual work.

Four rules I held to:

— no raw SQL, ever
— app-generated ids, no AUTOINCREMENT
— integer money, UTC dates
— exactly one file knows which database this is
```

## Post 2/2

```
The test isn't "would it work on Postgres". It's: change the provider, generate
the DDL, read it.

Mine came out with BIGINT columns and every index intact, which is the only
version of "portable" that isn't a promise to future me.
```

Both fit 280 as written; recount if you edit.

## Asset

Optional — **A10**-style code screenshot of the emitted DDL. The BIGINT lines
are the payload.

## Before you publish

- This is a genuinely useful post for other developers and it does not need a
  product link. Leave it out; the account benefits more from a post people save
  than from one more click.
- "Exactly one file knows which database this is" will get a "what about
  migrations" reply. It's a fair catch — migrations are dialect-specific and get
  regenerated. Concede it rather than arguing; the concession is what makes the
  rest believable.
- Don't imply you've run this on Postgres in production. You generated the DDL
  and read it. That's what the post says — keep it that way.
