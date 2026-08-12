# Brief — Ledgerly

## The idea, in the user's words

> "Tiny invoicing app for freelancers: create clients, create invoices with
> line items, mark invoices paid/unpaid, see a simple dashboard of outstanding
> totals."

## Normalized restatement

Ledgerly is a single-user invoicing web app for solo freelancers. A freelancer
signs in, maintains a small client list, creates invoices composed of line
items against those clients, tracks each invoice's paid/unpaid status, and
sees a dashboard summarizing outstanding money. Deliberately tiny: no sending,
no payments processing, no multi-user — v1 is the record-keeping loop done
excellently.

## Decisions at intake

| Question | Answer |
|---|---|
| Audience | Solo freelancers; public-facing SaaS, but v1 is single-user accounts |
| Auth | Email + password; data is private per account |
| Core loop (must be excellent) | Create invoice → send-ready state → mark paid |
| Platform | Responsive web, desktop-first |
| Monetization | None in v1 |
| Stack | Default profile (Next.js + TS + Prisma + Tailwind), override: **db = sqlite** (local demo) |
| Name | Ledgerly |
| Git | Yes — initialized at intake |

## Assumptions made for the user

- "Send-ready state" means an invoice has a well-formed, complete presentation
  (printable/shareable view) — actual email sending is out of scope for v1.
- Currency: single currency (USD display) in v1; multi-currency deferred.
- "Dashboard of outstanding totals" = total outstanding, total paid (period),
  and a recent-invoices list — not charts/analytics.
