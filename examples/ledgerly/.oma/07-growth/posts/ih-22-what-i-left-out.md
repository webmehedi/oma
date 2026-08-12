<!-- Pillar: Build in public
     Day 1, afternoon · Indie Hackers
     Sequenced per launch-plan.md, Day 0 afternoon row: a "built this, here's what I left
       out" post — "this audience rewards the decisions, not the app".
     Rests on: scope.md's out-of-scope and deferred tables (with their real revisit
       triggers), ADR-003/ADR-005/ADR-006, and QA run-3's verified behaviour.
     Asset: A12 (the 45s loop recording) embedded, or A1.
     Drafted by OMA. Nothing is posted for you. -->

# Indie Hackers — day 1, afternoon

A pure launch announcement sinks here. The post that works is about the
decisions, so this draft leads with the cuts and mentions the product almost in
passing.

## Title

```
I cut sending, payments, tax and three invoice statuses. Here's what was left.
```

## Body

```
I shipped a freelance invoicing app today. The interesting part isn't that it
exists — it's the list of things I decided not to build, and what each decision
cost.

**Sending.** An invoicing app that can't email an invoice sounds like a joke.
But the moment you add outbound email you own deliverability, bounce handling, a
sending domain, and a support burden where "did my client get it?" is now your
problem rather than your mail client's. What I built instead: the invoice detail
page prints clean — the print stylesheet drops every nav element and button, so
the browser's own print-to-PDF gives you the document and nothing else. One-line
invoice, one page. You attach it to the email you were writing anyway.
Cost: this will be the most common complaint I get. I'm fairly sure it's still
right, and I'll know within a month.

**Payments.** Cutting this removes the entire compliance surface, the whole
category of "the money left but didn't arrive" support, and any reason to touch
card data. It also removes the most obvious way to charge for the product, which
I noticed afterwards rather than before.

**Three of the five invoice statuses.** Draft, sent and overdue are gone;
unpaid and paid remain. This is the one I'd defend hardest. Two states means the
dashboard's outstanding figure has exactly one definition, and I never have to
explain to anyone — including myself in six months — whether "sent" counts.
Cost: no overdue flag. Due dates exist, nothing marks one late. That's the first
thing I'll add if someone tells me the outstanding total is hiding a problem.

**Multi-user.** Single-user accounts, no sharing, no roles. This one was free.
It halved the data model and it means every isolation question has the same
answer.

What I did spend the time on instead:

- Money is integer cents end to end. Quantities are stored as thousandths, so
  7.5 hours is exact. Totals compute in the form as you type, and are recomputed
  server-side on save — the number stored is never the number the browser sent.
- Paid invoices lock. You revert one to unpaid before you can edit it, so the
  "paid this month" figure can't be quietly rewritten.
- Invoice numbers are sequential per account and never reused, even after a
  delete.

Two bugs worth the price of admission:

The money columns were 32-bit integers, capping invoice totals near $21.5M.
Irrelevant for freelancing — but I'd written down "this can move to Postgres
later" and 32-bit money made that promise quietly false. The defect was the
promise going untrue, not the ceiling.

And past a certain invoice size the dashboard failed outright while the list and
detail pages rendered the same invoice fine, because the dashboard validated its
own response against a schema stricter than the API contract it mirrored. "The
same data renders in two places and bricks a third" is now the first thing I
look for anywhere.

[[TODO: what it cost you in hours or weeks — launch-plan.md asks for this
explicitly and it's the number this audience actually engages with. Real figure
or delete the sentence.]]

[[TODO: URL]]

The question I'd genuinely like argued with: is two invoice statuses too few?
```

## Asset

**A12** — the 45-second loop recording, embedded.

## Before you publish

- If you can only do three things well on launch day, this is the one to drop
  first — the HN thread and its comments matter more, and this post keeps
  perfectly well until day 2 or 3.
- Don't restate the landing page here. Every paragraph should be a decision with
  a cost attached, which is the format this community rewards.
- The closing question is real. Two statuses is the assumption the PRD itself
  flags as riskiest.
