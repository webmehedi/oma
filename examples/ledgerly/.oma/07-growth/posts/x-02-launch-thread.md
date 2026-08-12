<!-- Pillar: Build in public (launch)
     Day 1 · X/Twitter · 5-post thread
     Rests on: REQ-003/004/005/006 shipped; print stylesheet verified in QA run-3
       ("under print media the visible nav/button/a set is empty; 1-line invoice = 1 page");
       integer-cents rule from ADR-003 + stack.md; quantityThousandths from the data model.
     Asset: A1 (dashboard screenshot) on post 1, A6 (print preview) on post 3.
     Drafted by OMA. Nothing is posted for you. -->

# X thread — launch day

Post 1 stands alone as a complete thought — assume most people see only it.
Each post fits 280 characters as written; recount if you edit.

## Post 1/5 — attach asset A1

```
My invoice tracking was a spreadsheet I'd stopped trusting.

So I built Ledgerly: a client list, line-item invoices, a paid/unpaid toggle,
and a dashboard whose primary figure is one number — what I'm actually owed.

[[TODO: URL]]
```

## Post 2/5

```
It doesn't send email. It doesn't take payments. It has two invoice statuses,
not five.

Every one of those is a deliberate no. The loop I run every week is: create,
print, mark paid. Everything else was in the way of it.
```

## Post 3/5 — attach asset A6

```
"Send-ready" means the detail view prints clean.

Under print media the page has no nav, no buttons, no links — just the invoice.
Ctrl+P gives you the document. No PDF library involved.

A one-line invoice is one page.
```

## Post 4/5

```
Money is integer cents end to end. Dollars only exist in the formatting layer.

Quantities are stored as thousandths, so 7.5 hours is 7500 — exactly 7.5 hours,
not 7.499999999999999.

Nobody notices this until the day they do.
```

## Post 5/5

```
Built by one person, over [[TODO: how long it actually took]].

It's free right now because I haven't built billing — not because I've promised
anything about later.

If you invoice clients and keep losing track of who's paid: [[TODO: URL]]
```

## Assets

- **A1** — dashboard screenshot (post 1)
- **A6** — print preview beside the on-screen invoice (post 3)

## Before you publish

- No hashtags. They cost reach on X now and they read as a press release.
- Post 5's "how long it actually took" is the one number in this thread. Use the
  real one or delete the clause — a rounded-up build time is the cheapest
  credibility you will ever spend.
- If the URL isn't live and signup-tested from a logged-out browser, don't post.
