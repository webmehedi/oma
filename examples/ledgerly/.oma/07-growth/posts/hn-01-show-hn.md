<!-- Pillar: Build in public (launch)
     Day 1 · Hacker News · Show HN
     Rests on: the shipped feature set in .oma/01-discovery/prd.md (REQ-001..010, all
       28 tasks done in .oma/04-build/tasks.json); stack from .oma/02-architecture/stack.md;
       the two named defects are real — ADR-006 / T-026 (32-bit money columns) and
       T-028 / QA run-3 F-8 (dashboard vs Number.MAX_SAFE_INTEGER).
     Asset: none (HN posts do not take images). A2 + A12 for the comments if asked.
     Drafted by OMA. Nothing is posted for you. Edit into your own voice first. -->

# Show HN — day 1

## Title (HN caps titles at 80 characters)

`launch-plan.md` already proposes a title, and it is the better one — it leads
with the subtraction, which is the whole launch argument:

```
Show HN: Ledgerly – invoicing for freelancers with no sending and no payments
```

Alternate, if you want the solo angle in the title instead:

```
Show HN: Ledgerly – invoice tracking for one freelancer, no payments, no email
```

Both are plain and factual. Do not add an adjective to either.

## Body

```
I'm a solo [[TODO: your actual work — designer, developer, consultant]] and my
invoice tracking was a spreadsheet I had stopped trusting.

Ledgerly does four things: a client list, invoices built from line items, a
paid/unpaid toggle, and a dashboard whose primary figure is one number — total
outstanding. That is the entire product.

What it deliberately does not do: no payments, no emailing invoices, no PDF
export library, no multi-user, no multi-currency, no draft/sent/overdue
statuses. "Send-ready" here means the invoice detail view prints cleanly — the
print stylesheet strips every nav element and button, so the browser's own
print-to-PDF hands you the document and nothing else. A one-line invoice is one
page. That was cheaper than a PDF pipeline and the output is the same file.

Stack: Next.js App Router, SQLite through Prisma's better-sqlite3 driver
adapter, argon2id passwords, an opaque 256-bit session token in an httpOnly
cookie (not a JWT — the session row is keyed by the token's SHA-256), Zod at
every trust boundary. Money is integer cents end to end; dollars exist only in
display formatting. Quantities are stored as thousandths, so 7.5 hours is
exactly 7.5 hours.

Two things I got wrong that are worth naming:

The money columns started as 32-bit integers, which caps an invoice total near
$21.5M. No freelancer will ever hit that — but I had written down "this can move
to Postgres later", and 32-bit money made that promise quietly false. Migrated
them to BIGINT.

Above Number.MAX_SAFE_INTEGER, the dashboard failed outright while the list and
detail screens rendered the same invoice fine. A response-validation schema was
stricter than the API contract it was mirroring, so one screen died instead of
degrading. Fixed — but "the same data renders in two places and bricks a third"
is now the first failure mode I look for in anything.

Known limitations today: no password reset (there is no outbound email anywhere
in the app, so there is nowhere to send one), USD only, and invoice totals above
roughly $90 trillion lose precision as JSON numbers on the wire. That last one is
written down rather than fixed; the fix is an invoice-total bound and it is a
v1.1 item.

[[TODO: public URL — the deploy runbook targets https://ledgerly.fly.dev.
Confirm it is actually live and that signup works from a clean browser before
you post.]]

[[TODO: is the source public? You will be asked this in the first three
comments. Decide before posting, not after.]]
```

## Your own first comment (post it yourself, immediately after submitting)

`launch-plan.md` asks for a first comment that explains the subtraction and names
the open security items. Naming them yourself is both the honest move and the
one that pre-empts the worst thread you could get.

```
Author here. Two things I'd rather say than have found.

The subtraction is the product. Every feature I left out — sending, payments,
tax lines, multi-currency, draft/sent/overdue statuses, teams — was left out so
that the loop I run every week (make the invoice, print it, mark it paid) has
nothing in front of it. If you need any of those, an accounting suite is the
right answer and I'd rather you used one.

Second, the security posture, stated plainly rather than discovered: passwords
are argon2id, sessions are opaque tokens in an httpOnly SameSite cookie (not
JWTs), account separation is enforced in the data layer and was probed with a
second account against the first account's data — eleven operations, all
refused. There's no analytics, no third-party script, no tracker, and the server
makes no outbound requests. Dependency audit is clean.

Open, and rated medium: [[TODO: update this list to what is ACTUALLY still open
on the day you post — as of the security review it was: no rate limit or lockout
on sign-in, a sign-in timing difference that reveals whether an email is
registered, and a Content-Security-Policy shipping in report-only rather than
enforced. If you closed them before launch, say "closed before launch" instead
of listing them — but do not list them as closed unless they are.]]

Happy to go into any of it.
```

## Asset

None. HN is text.

## Before you publish

- **The launch-plan checklist gates this post.** In particular SEC-001 (no
  sign-in rate limit) and SEC-002 (sign-in timing oracle) were open at the time
  this calendar was written. Putting a sign-in form in front of Hacker News with
  no throttle is the single most predictable way to have a bad day-one.
- **You get one Show HN.** Post it when you can sit with the thread for three or
  four hours and reply to everything. A Show HN you abandon is worse than one you
  postpone. `launch-plan.md` puts this at 07:00–09:00 your time; the comments are
  the actual work of launch day.
- Put the demo recording (A12) and screenshots above the fold on the landing
  page — HN dislikes a hard signup wall.
- Expect "this is just a spreadsheet". Answer it well and that thread becomes
  your best copy.
- Marketing voice is actively punished here. If a sentence in the draft reads
  like a landing page, cut it — the limitations paragraph is the part that earns
  the rest.
- Do not add a metric. There isn't one yet, and HN will find that out.
- Read HN's own Show HN rules before submitting; they change and I can't check
  them from here. [[TODO: verify at news.ycombinator.com/showhn.html]]
