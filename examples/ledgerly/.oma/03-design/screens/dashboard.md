# Screen — Dashboard

- **Route:** `/dashboard`
- **Requirements:** REQ-006, REQ-005 (row toggle), REQ-009 (empty state)
- **Mockup:** ../mockups/dashboard.html
- **Personas:** Maya, several times a week, often on her phone after a payment notification — the outstanding number is why she opens the app. Tomás lands here after signup.

## Purpose

Answer "who owes me and how much" in one glance (data: `GET /dashboard`).

## Layout

AppShell → PageHeader ("Dashboard", primary action "New invoice" →
invoice-form). Two StatCards side-by-side (Outstanding, tone warn — the
primary figure; Paid in August, tone accent). Below, a card titled "Recent
invoices" holding a DataTable of the 10 most recent by issue date: number
(mono), client, issue date, total (mono, right), StatusBadge, StatusToggle.
Rows link to invoice-detail. Footer link "All invoices →" to invoices.

## States

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | Two stat Skeletons + 5 row Skeletons in the card | identical geometry to resolved layout |
| **Empty** | `invoiceCount: 0` → stats show $0.00, recent card replaced by EmptyState: "No invoices yet. Create your first invoice and Ledgerly starts tracking who owes you." + "Create your first invoice" → invoice-form | REQ-006/REQ-009 CTA |
| **Ideal** | Outstanding $6,100.00 · Paid in August $3,530.00 · 7 recent rows | dataset per contract shapes |
| **Error** | Stats replaced by danger Banner "Couldn't load your dashboard." + Retry | no stale numbers shown |
| **Partial** | Stats loaded; recent-invoices card shows an inline Banner "Couldn't load recent invoices." + Retry | totals remain usable |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| Stat cards → recent card | first paint | `stagger.hero` |
| Table rows | first paint | `stagger.list` |
| StatusToggle → badge | mark paid | `move.default` color swap + `emphasis` scale; paid date `enter.fast` |
| StatusToggle → badge | mark unpaid | `move.default` only |
| Below-fold content | scroll into view | `scroll.reveal.*` |

Note: totals do NOT recompute optimistically on row toggle — per REQ-006 they
refresh on next dashboard load; the row badge updates immediately.

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Stat cards stack; table collapses to stacked row-cards (number+client / total+badge+toggle); "New invoice" stays in header |
| 640–1024 | Stats side-by-side; table keeps all columns except due-date-free layout |
| > 1024 | Full tabular layout, 1120px container |

## Accessibility

- Focus order: nav → New invoice → stat cards (not focusable) → each row link → its toggle.
- Announcements: toggle result via `aria-live="polite"` ("INV-0002 marked paid"); loading region `aria-busy`.
- Contrast: badge pairs 6.2–8.0:1; display figures `text` on `surface`.
- Reduced motion: no stagger/reveal; badge swaps instantly.
