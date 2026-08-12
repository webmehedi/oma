# Scope — Ledgerly v1

## In scope

| REQ | Title | Priority |
|---|---|---|
| REQ-001 | Account authentication | must |
| REQ-002 | Client management | must |
| REQ-003 | Invoice creation with line items | must |
| REQ-004 | Send-ready invoice view | must |
| REQ-005 | Paid/unpaid status tracking | must |
| REQ-006 | Outstanding-totals dashboard | must |
| REQ-007 | Invoice list with status filter | should |
| REQ-008 | Editing unpaid invoices | should |
| REQ-009 | Empty and error states | should |
| REQ-010 | Responsive layout | should |

10 requirements total (6 must, 4 should) — within the ~12 ceiling for a v1.

## Out of scope (v1)

| Not doing | Why not |
|---|---|
| Sending invoices by email | Intake defines send-ready as presentation-complete; no outbound email in v1 |
| Payment processing / online payment links | Brief explicitly excludes payments processing |
| Multi-user, teams, or client-facing portal | Brief: single-user accounts only |
| Multi-currency | Intake assumption: single currency, USD display |
| Charts / analytics dashboards | Intake: dashboard is totals + recent list only |
| Monetization (plans, billing, trials) | Intake: none in v1 |
| Draft / sent / overdue statuses | Two-state model keeps the core loop simple and demo-able |
| Password reset & email verification | Depends on outbound email, which v1 deliberately lacks |
| Client deletion when invoices exist | Referential integrity beats convenience at this size |
| Native mobile app | Platform decision at intake: responsive web, desktop-first |

## Deferred to v2

| Idea | Trigger to revisit |
|---|---|
| Overdue detection from due dates (auto-flag, dashboard count) | First user complaint that outstanding total hides late invoices |
| Recurring invoices | Users recreating the same invoice monthly |
| Dedicated PDF export (beyond browser print-to-PDF) | Print output proves insufficient for real client sharing |
| Tax lines and discounts on invoices | Any user in a jurisdiction requiring tax on invoices |
| Search across clients/invoices | Accounts exceeding ~50 clients or ~200 invoices |
| Multi-currency | First non-USD user request |
| Password reset via email | The moment outbound email enters the stack for any reason |
| Partial payments | Users marking invoices paid before full payment arrives |
