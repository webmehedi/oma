# PRD — Ledgerly

> Written by oma-project-manager. Requirement IDs are stable for the life of the
> project — never renumber, never reuse. Every task in 04-build/tasks.json must
> cite one of these IDs. A task that cites nothing is scope creep.

## Problem

Solo freelancers need to know who owes them money and how much, but their
tooling is a spreadsheet or a heavyweight accounting suite built for firms.
The spreadsheet loses track of paid/unpaid state; the suite buries the one loop
that matters — create an invoice, get it into a send-ready state, mark it paid —
under features they never touch.

## Solution in one paragraph

Ledgerly is a single-user invoicing web app that does exactly the record-keeping
loop and nothing else: maintain a small client list, compose invoices from line
items against those clients, track each invoice's paid/unpaid status, and see a
dashboard of outstanding totals. It beats the status quo by making the core loop
(create invoice → send-ready state → mark paid) fast and impossible to get wrong,
with no sending, no payment processing, and no multi-user machinery in the way.
Single currency (USD display), responsive web, desktop-first.

## Requirements

### REQ-001 — Account authentication
- **Priority:** must
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want to sign up and sign in with email + password so that my client and invoice data is private to my account.
- **Acceptance:**
  - [ ] A new user can sign up with email + password and lands on the dashboard.
  - [ ] A signed-out request to any app page (dashboard, clients, invoices) redirects to the sign-in page.
  - [ ] Signing in with a wrong password shows an inline error and does not create a session.
  - [ ] User A's session never returns clients or invoices created by user B (verified by creating data under two accounts).
- **Notes:** Email + password only per intake; no OAuth, no password reset flow in v1 (deferred — see scope.md). Password storage mechanics are oma-architect's call.

### REQ-002 — Client management
- **Priority:** must
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want to create and maintain a small client list so that invoices are always attached to a real client record.
- **Acceptance:**
  - [ ] User can create a client with at minimum a name; email and address fields are optional.
  - [ ] User can edit a client's fields; the change is reflected on that client's existing invoices' send-ready views.
  - [ ] Client list page shows all clients with each client's count of invoices.
  - [ ] Creating a client with an empty name is rejected with an inline validation message.
- **Notes:** No client deletion in v1 when invoices reference the client (referential integrity over convenience); a client with zero invoices may be deleted.

### REQ-003 — Invoice creation with line items
- **Priority:** must
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want to create an invoice composed of line items against a client so that the amount owed is computed for me, not by me.
- **Acceptance:**
  - [ ] User can create an invoice by selecting an existing client and adding 1+ line items (description, quantity, unit price).
  - [ ] Line item amount (quantity × unit price) and invoice total are computed and displayed; totals update live as line items are added, edited, or removed in the form.
  - [ ] An invoice cannot be saved with zero line items or without a client; attempting to shows inline validation.
  - [ ] Each invoice gets a unique sequential invoice number visible on the invoice (e.g. INV-0001, INV-0002) per account.
  - [ ] Invoice has an issue date (defaults to today, editable) and an optional due date.
- **Notes:** Amounts display in USD. Quantity accepts decimals (e.g. 7.5 hours). Negative unit prices are rejected.

### REQ-004 — Send-ready invoice view
- **Priority:** must
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want a complete, well-formed presentation of an invoice so that I can print it or share it with my client outside the app.
- **Acceptance:**
  - [ ] Every saved invoice has a detail view showing: invoice number, issue date, due date (if set), client name and details, all line items with quantity/unit price/amount, and the total.
  - [ ] The view is print-clean: browser print (or print-to-PDF) of the page yields a one-page-per-invoice document without app navigation chrome (verified via print stylesheet / print preview).
  - [ ] Paid/unpaid status is visible on the view.
- **Notes:** "Send-ready" per intake means presentation-complete — actual email sending is out of scope for v1.

### REQ-005 — Paid/unpaid status tracking
- **Priority:** must
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want to mark an invoice paid or back to unpaid so that my records reflect reality when money arrives.
- **Acceptance:**
  - [ ] Every invoice is in exactly one of two statuses: unpaid (default on creation) or paid.
  - [ ] User can toggle status from the invoice detail view and from the invoice list in one click each, with the new status visible immediately without a full page reload.
  - [ ] Marking paid records a paid date (defaults to today) shown on the detail view; reverting to unpaid clears it.
  - [ ] Dashboard totals (REQ-006) reflect a status change on next dashboard load.
- **Notes:** Two statuses only in v1 — no draft/sent/overdue states (see scope.md).

### REQ-006 — Outstanding-totals dashboard
- **Priority:** must
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want a dashboard summarizing outstanding money so that I know at a glance who owes me and how much.
- **Acceptance:**
  - [ ] Dashboard shows total outstanding (sum of unpaid invoice totals) as its primary figure.
  - [ ] Dashboard shows total paid for the current calendar month.
  - [ ] Dashboard shows a recent-invoices list (10 most recent by issue date) with invoice number, client, total, and status, each row linking to the invoice detail view.
  - [ ] With zero invoices, the dashboard shows an empty state with a call-to-action linking to invoice creation (ties to REQ-009).
- **Notes:** Per intake: totals + recent list, not charts/analytics.

### REQ-007 — Invoice list with status filter
- **Priority:** should
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want to browse all my invoices and filter by status so that I can chase unpaid ones without scanning everything.
- **Acceptance:**
  - [ ] Invoice list page shows all invoices (newest first) with invoice number, client, issue date, total, and status.
  - [ ] A filter control narrows the list to all / unpaid / paid; the filtered state is reflected in the URL so it survives reload.
  - [ ] Each row links to the invoice's detail view.
- **Notes:** Pagination is not required under 100 invoices; if implemented, page size 25.

### REQ-008 — Editing unpaid invoices
- **Priority:** should
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want to correct an unpaid invoice's line items or dates so that a typo doesn't force me to recreate the invoice.
- **Acceptance:**
  - [ ] An unpaid invoice can be edited (client, dates, line items) with the same validation as creation; totals recompute on save.
  - [ ] A paid invoice's edit affordance is disabled or absent, with the reason shown (revert to unpaid to edit).
  - [ ] An unpaid invoice can be deleted after a confirmation step; its number is not reused.
- **Notes:** Locking paid invoices keeps the paid-total figures trustworthy.

### REQ-009 — Empty and error states
- **Priority:** should
- **Persona:** Maya (solo freelancer); Tomás (moonlighter) feels this hardest on first run
- **Story:** As a first-time user, I want every empty screen to tell me the next step so that I reach my first send-ready invoice without guessing.
- **Acceptance:**
  - [ ] Clients, invoices, and dashboard each show a purposeful empty state (message + call-to-action) when the account has no data.
  - [ ] Every form submission failure (validation or server error) shows an inline, human-readable message; no raw error screens or silent failures.
  - [ ] Navigating to a nonexistent invoice or client id shows a friendly not-found page with a link back to the relevant list.
- **Notes:** Standard product hygiene inferred from "record-keeping loop done excellently" — not new feature surface.

### REQ-010 — Responsive layout
- **Priority:** should
- **Persona:** Maya (solo freelancer)
- **Story:** As a freelancer, I want the app usable on my phone so that I can mark an invoice paid or check outstanding totals away from my desk.
- **Acceptance:**
  - [ ] At 375px viewport width, dashboard, lists, invoice detail, and both create forms render without horizontal scrolling and all actions remain reachable.
  - [ ] At ≥1024px, list pages use the available width (tabular layout, not a stretched mobile column).
- **Notes:** Desktop-first per intake; mobile is read/mark-paid competent, not pixel-perfect.

## Out of scope (v1)

| Not doing | Why not |
|---|---|
| Sending invoices by email | Intake explicitly defines send-ready as presentation-complete only |
| Payment processing (Stripe etc.) | Brief: no payments processing; tracking status is the product |
| Multi-user / teams / client portal | Brief: single-user accounts only |
| Multi-currency | Intake assumption: USD display only in v1 |
| Charts / analytics on dashboard | Intake: totals + recent list, not analytics |
| Monetization (billing, plans) | Intake: none in v1 |
| Draft / sent / overdue invoice statuses | Two-state paid/unpaid keeps the core loop simple; more states are v2 |
| Password reset / email verification | Requires outbound email, which v1 deliberately lacks; deferred |

## Deferred

See scope.md for the full deferred table: recurring invoices, PDF export beyond
browser print, overdue detection from due dates, client-side search, tax and
discount lines, multi-currency, password reset.

## Riskiest assumptions

1. **"Send-ready" = printable/shareable view, not email.** If the user actually
   expects sending, REQ-004 is the wrong shape and an email pipeline enters scope.
   Carried from intake; flagged in the handoff.
2. **Two statuses suffice.** If freelancers need overdue/partial-payment states to
   trust the outstanding total, REQ-005 and REQ-006 both grow.
3. **Paid invoices locked from editing (REQ-008).** Decided alone for data
   integrity; if users routinely fix paid invoices, the revert-to-edit flow may
   feel punitive.
