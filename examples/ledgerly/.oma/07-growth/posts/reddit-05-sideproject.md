<!-- Pillar: Build in public
     Day 1 (launch morning, right after the Show HN) · Reddit · r/SideProject
     Sequenced per launch-plan.md, which puts r/SideProject on Day 0 same morning.
     Rests on: shipped scope (scope.md), the two real defects (ADR-006, QA run-3 F-8),
       and the stack in stack.md.
     Asset: A2 (invoice list, unpaid filter, URL visible) — Reddit image post or i.redd.it
       link in the body.
     Drafted by OMA. Nothing is posted for you. -->

# Reddit — r/SideProject — day 1, launch morning

## Subreddit and its self-promotion rule

r/SideProject exists specifically for people showing their own projects, which
makes it one of the few subreddits where this post is on-topic rather than
tolerated. The rules that matter in practice: it must be your own project, the
post must have substance beyond a link, and low-effort "check out my app" posts
get removed.

**[[TODO: re-read the sidebar rules the morning you post.** Subreddit rules
change and I cannot verify the current text from here. If the rules have moved
to a weekly showcase thread, use the thread — a removed post costs you the
account's standing in that community.**]]**

Reply to every comment. On Reddit the comments are the post.

## Title

```
I built an invoicing app that deliberately can't send invoices
```

## Body

```
Ledgerly. It's a single-user invoicing tracker: a client list, invoices built
from line items, a paid/unpaid toggle, and a dashboard showing total
outstanding.

The "can't send invoices" part is the design, not a missing feature. Send-ready
here means the invoice detail page prints cleanly — the print stylesheet strips
every nav element and button, so browser print-to-PDF gives you the document and
nothing else. One-line invoice, one page. I didn't add a PDF library and I don't
plan to. Emailing it is your mail client's job and it's better at it than I
would be.

Other deliberate absences: no payments, no multi-user, no multi-currency, and
exactly two statuses — unpaid and paid. No draft/sent/overdue. Two states means
the outstanding number on the dashboard has one definition and I never have to
explain it.

Stack: Next.js App Router, SQLite via Prisma's better-sqlite3 adapter, argon2id
passwords, opaque session tokens in an httpOnly cookie rather than JWTs, Zod at
every boundary. Money is integer cents everywhere; quantities are stored as
thousandths so 7.5 hours doesn't drift.

The two bugs that taught me the most:

1. Money columns were 32-bit ints, capping an invoice total around $21.5M. No
   freelancer hits that — but I'd committed on paper to "this can move to
   Postgres later", and 32-bit money made that quietly untrue. Migrated to
   BIGINT.

2. Past a certain size, the dashboard failed completely while the list and
   detail pages rendered the same invoice fine. The dashboard was validating its
   own response against a schema stricter than the API contract it mirrored.
   One screen dying instead of degrading is a much worse failure than the size
   limit that triggered it.

Two things I'd genuinely like opinions on:

- Paid invoices are locked from editing. You have to flip one back to unpaid to
  correct it. I did that so the "paid this month" figure can't be quietly
  rewritten — but I'm not sure it isn't just annoying. Which way would you want
  it?

- There's no overdue state. Due dates exist on invoices, but nothing flags a
  late one. Would you want the dashboard to break out overdue separately, or is
  "unpaid" enough?

[[TODO: URL]]
[[TODO: is the repo public? If yes, link it here — it changes how this post
lands in this sub.]]
```

## Asset

**A2** — invoice list with the unpaid filter active and the URL bar visible.

## Before you publish

- The two questions at the end are what make this a contribution rather than an
  ad. Don't cut them for length, and answer the replies properly.
- Do not post this and the r/webdev post (day 14) in the same week. Cross-posting
  the same project to several subs in quick succession is what gets accounts
  flagged.
