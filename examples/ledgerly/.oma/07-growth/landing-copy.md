<!-- Written by oma-marketer. Lives at .oma/07-growth/landing-copy.md
     Paste-ready. Every feature claim maps to a shipped REQ / `done` task —
     see positioning.md for the receipts. Nothing here is published by OMA.

     There is no invented social proof anywhere in this file: no testimonial,
     no user count, no rating, no logo strip, not even as an example. If you
     want one, get a real one first.

     A double-bracketed TODO marks something only you can decide.
     There are 12 in this file. Two of them — pricing, and what happens when
     someone is locked out — must not ship blank. -->

# Landing page copy — Ledgerly

**Voice check before you edit:** name the limit beside the feature; use the
app's own words (*Outstanding*, *Mark paid*, *New invoice*); never write
*seamless* or *effortless*. Full rules in `positioning.md`.

---

## 1 · Hero

*Purpose: in five seconds, tell a freelancer what this is and who it isn't for.*

> # Know exactly who owes you what.
>
> Ledgerly is a tiny invoicing app for solo freelancers. Keep a client list,
> build invoices from line items, mark them paid, and see one honest
> outstanding total. No sending, no payment processing — just a ledger that
> stays right.
>
> **[ Create an account ]** `[[TODO: sign-up URL — the deployed app's /signup]]`
>
> Six screens, one job. Sign up with an email and a password and you land on
> the dashboard — nothing to configure before your first invoice.

**Hero image:** the dashboard with real-looking data — the *Outstanding* figure,
*Paid in August*, and the recent-invoices table. Not a stock photo of a laptop.
`[[TODO: capture this screenshot from your own deployed instance]]`

---

## 2 · The problem

*Purpose: the reader recognises themselves. Written in their words, not the
product's.*

> ## You know roughly who owes you. Roughly isn't good enough.
>
> The invoice went out three weeks ago. You think it's unpaid. The spreadsheet
> says unpaid — but the spreadsheet also said that about the one that cleared in
> March, because marking it paid was a cell nobody remembered to change.
>
> So you scroll your bank statement, then your sent mail, and you rebuild the
> answer from scratch. Again. And you still don't chase the one that's actually
> late, because you're not certain enough to send that email.
>
> The work isn't invoicing. The work is not trusting your own records.

---

## 3 · How it works

*Purpose: prove the loop is three steps. These are the real screens, in order.*

> ## Three steps, and you've already seen two of them
>
> ### 1. Add a client
> A name is the only thing required — email and address are optional and you can
> fill them in later. Change a client's details any time and their existing
> invoices update with them.
>
> ### 2. Build the invoice from line items
> Pick the client, then add lines: description, quantity, unit price. The line
> amount and the invoice total compute as you type, and are recomputed on the
> server when you save — so the total is never something you typed. Quantities
> take decimals, so 7.5 hours is 7.5 hours. Ledgerly numbers it for you:
> INV-0001, INV-0002, and on. The issue date defaults to today; a due date is
> optional.
>
> ### 3. Send it your way, then mark it paid
> Open the invoice and you get a clean document — number, dates, client, every
> line, the total. Print it, or print-to-PDF, and the app's navigation
> disappears from the page. Attach it to the email you were writing anyway.
> When the money lands, **Mark paid** — one click, from the invoice or straight
> from the list — and the Outstanding figure on your dashboard follows.

**Section image:** three narrow screenshots side by side — clients, the invoice
form mid-edit with a live total, the invoice document.
`[[TODO: capture these three screenshots]]`

---

## 4 · Features

*Purpose: the honest, complete list. Left column is what it does; right column
is why a freelancer cares. Everything here shipped — nothing aspirational.*

> ## What's in it
>
> | What it does | What that means for you |
> |---|---|
> | **Outstanding total** as the dashboard's main figure, plus **Paid in \<this month\>** and your 10 most recent invoices | One screen answers "how much am I owed right now" without you adding anything up |
> | **Line-item invoices** with live totals, decimal quantities and server-computed amounts in whole cents | The arithmetic isn't yours to get wrong — and it isn't a floating-point guess |
> | **Sequential invoice numbers per account**, and a deleted invoice's number is never reused | Your numbering stays defensible if anyone ever asks |
> | **A print-clean invoice view** — browser print or print-to-PDF drops all app navigation | The document you hand a client looks like a document, not like a web page |
> | **Two statuses, unpaid and paid**, toggled in one click from the invoice *or* the list, with no page reload | Marking three invoices paid takes three clicks and no waiting |
> | **A paid date**, recorded when you mark it paid and cleared if you revert | You can answer "when did that clear?" without the bank statement |
> | **Paid invoices lock** — revert to unpaid before editing or deleting, and the app says so | Your paid totals can't drift because of an idle edit |
> | **Client list with invoice counts**; a client with invoices can't be deleted | No invoice ever ends up pointing at a client that vanished |
> | **Invoice list, newest first**, filtered to all / unpaid / paid — the filter lives in the URL | Bookmark "my unpaid invoices" and reload straight into it |
> | **Works on a phone** (375px), as well as full-width on a desktop | Check the outstanding total and mark something paid from the sofa |
> | **Follows your system light/dark setting**, and honours reduced-motion | It looks like the rest of your machine, and it doesn't animate at you |
> | **Your data is yours alone** — every account's clients and invoices are isolated at the database layer, and this was probed with a second account | Nobody else's session can reach your ledger |
> | **No trackers, no analytics, no third-party scripts** | The page you're reading and the app you'd use are not watching you |
>
> **Amounts are in US dollars.** One currency, everywhere, in v1.

---

## 5 · FAQ

*Purpose: answer the six questions a real evaluator asks — including the two
most landing pages go quiet on, price and data.*

> ## Questions people actually ask
>
> ### What does it cost?
> `[[TODO: your pricing. There is no billing, no plans and no card handling
> anywhere in the app — so today the only true answers are "free" or "free while
> it's in beta". If you intend to charge later, say that here now; charging
> people who joined on "free" is how you lose the first hundred users. Do not
> publish this page with this box unfilled.]]`
>
> ### Can Ledgerly email the invoice to my client?
> No. Ledgerly has no outbound email at all — that's a deliberate v1 decision,
> not a missing integration. You open the invoice, print it or save it as a PDF
> from your browser, and send it the way you already send things.
>
> One consequence worth knowing before you sign up: **there is no password reset**,
> because a reset needs an email Ledgerly can't send. Use a password manager.
> If you're locked out, `[[TODO: say what you'll do — e.g. "email support and I'll
> verify you by hand", or "I can't recover accounts". Either is fine. Silence is not.]]`
>
> ### Can my clients pay through it?
> No. There's no payment processing, no card fields, no payment links, and none
> planned for v1. Ledgerly records that you were paid; it doesn't move money.
> If "client clicks a button and pays" is what you need, you need a different
> product, and you should stop reading here.
>
> ### Where does my data live, and can I get it out?
> Your clients and invoices live in one database on `[[TODO: name where you host
> it, e.g. "a server in <region> that I run"]]`. Every account is isolated at the
> database layer — verified by running a second account's session against the
> first account's invoices and clients across eleven operations, all of which
> came back "not found".
>
> Getting data out, honestly: **any single invoice, yes** — print or save it as a
> PDF from the invoice page, any time. **A bulk export, no** — there is no
> CSV or JSON export in v1. That's the sharpest limitation on this page and it's
> the one to fix first if you need it.
> `[[TODO: state your backup schedule and whether a user can request a copy of
> their raw data — and how fast.]]`
>
> ### Is it secure?
> Here's the honest state, from a security review of the code
> `[[TODO: link the review or a summary of it if you want to publish it]]`:
> zero critical and zero high findings; three medium ones, listed below because
> you should know them.
>
> **What's true:** passwords are stored with argon2id, not reversible. Sessions
> use an HttpOnly, SameSite cookie and a new token on every sign-in. Account
> separation is enforced in the data layer and was probed with a real second
> account. There is no third-party script, no tracker, and the server makes no
> outbound requests at all. Dependency audit: zero known vulnerabilities.
>
> **What isn't done yet:** sign-in has no rate limit or lockout, so nothing slows
> down repeated password guesses. Sign-in's response time reveals whether an
> email address has an account. And the Content-Security-Policy currently runs in
> report-only mode rather than being enforced.
> `[[TODO: fix the first two before you put this on the public internet, then
> rewrite this paragraph. If you launch with them open, leave this text exactly
> as it is — it is the truth, and it is better than the alternative.]]`
>
> No compliance claims are made here, because none would be true.
>
> ### What can't it do?
> The complete list, so you don't find out in month two: no tax or VAT lines, no
> discounts, no currencies other than USD, no recurring or retainer invoices, no
> automatic overdue flagging (a due date is stored and shown, but nothing turns
> red), no search, no bulk export, no teams or multiple users, no client portal,
> no draft/sent statuses — an invoice is unpaid or paid. Lists page at 25
> invoices at a time.
>
> If several of those are dealbreakers, a full accounting suite is the right
> answer and it's worth the monthly fee. Ledgerly is for the freelancer who
> wanted the other 90% removed.

---

## 6 · Final CTA

*Purpose: close on the promise the product actually keeps.*

> ## One number you can trust
>
> Add your clients once, invoice from line items, mark them paid as the money
> arrives. That's the whole app — and that's the point.
>
> **[ Create an account ]** `[[TODO: sign-up URL]]`
>
> `[[TODO: one-line pricing, copied word for word from the FAQ answer above so
> the two can never contradict each other]]` · Nothing to install · USD only.
>
> Questions: `[[TODO: support email address]]`

---

## 7 · Meta title and description

*For `<title>` and `<meta name="description">`.*

**Title** (57 chars):

```
Ledgerly — simple invoicing for solo freelancers
```

**Description** (152 chars):

```
A tiny invoicing app for solo freelancers: keep a client list, build invoices from line items, mark them paid, and see exactly how much you're owed.
```

> **Reconciliation note:** `oma-seo` was running concurrently with me and had not
> written to `.oma/07-growth/` when this file was finished. If an SEO brief now
> exists with different target terms, **the SEO brief wins on the title tag and
> the description** — rewrite these two blocks to match its terms, but keep the
> body copy above unchanged unless a claim itself changes. Nothing on this page
> may become less true to fit a keyword.

---

## Appendix — claim-to-source map

Kept so anyone can re-check the page instead of trusting it. Every row was
verified against `.oma/05-qa/reports/run-3.md` (all 28 tasks `done`, pipeline
green, 191 unit + 11 e2e tests).

| Claim on the page | Source |
|---|---|
| Six screens | `.oma/03-design/screens/` (7 files, one is the not-found page) |
| Sign up with email + password, land on dashboard | REQ-001, T-004/T-013 |
| Client name required; email/address optional | REQ-002, T-005/T-018 |
| Client edits reach existing invoices | REQ-002, QA verified live |
| Client with invoices can't be deleted | REQ-002, 409 `CLIENT_HAS_INVOICES` verified |
| Live totals; server recomputes on save; whole cents | REQ-003, ADR-003, ADR-006, T-006/T-016 |
| Decimal quantities (7.5 hours) | REQ-003, verified: 7.5 → 112500 cents |
| Sequential INV-0001…; number never reused | REQ-003, REQ-008, verified live |
| Issue date defaults to today; due date optional | REQ-003, verified |
| Print-clean document, no app chrome | REQ-004, T-017; QA print-media probe found zero visible nav/button/link elements |
| Two statuses; one-click toggle from list and detail, no reload | REQ-005, T-009/T-015; QA drove both in a browser |
| Paid date recorded, cleared on revert | REQ-005, verified |
| Paid invoices lock for edit and delete | REQ-008, ADR-005, 409 `INVOICE_PAID_LOCKED` on both |
| Outstanding + Paid-this-month + 10 recent | REQ-006, T-010/T-014 |
| Filter all/unpaid/paid, persisted in the URL; 25 per page | REQ-007, T-007/T-015 |
| Works at 375px, tabular at ≥1024px | REQ-010, T-020; QA measured `scrollWidth == 375` on five screens |
| Follows system light/dark; honours reduced motion | `globals.css` `prefers-color-scheme` / `prefers-reduced-motion`; QA verified both |
| Account isolation, eleven probes | `.oma/06-devops/security-review.md`, QA run-3 isolation matrix |
| argon2id; HttpOnly SameSite cookie; new token per sign-in | security review, "Checked and clean" |
| No trackers, no third-party scripts, no outbound requests | security review (SSRF row: none; no `NEXT_PUBLIC_*`) |
| Zero dependency vulnerabilities | `npm audit` → 0 across 685 packages |
| The three open medium findings | SEC-001, SEC-002, SEC-003 (CSP is report-only) |
| USD only; no tax, recurring, search, export, teams, portal, drafts | `.oma/01-discovery/scope.md` out-of-scope + deferred tables |
