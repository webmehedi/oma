# Screen — Invoice detail (send-ready view)

- **Route:** `/invoices/{id}`
- **Requirements:** REQ-004, REQ-005, REQ-008, REQ-009
- **Mockup:** ../mockups/invoice-detail.html
- **Personas:** Maya printing/PDF-ing for a client (the "send-ready" moment) and marking paid when money lands; Tomás checking whether last month's invoice was paid.

## Purpose

Present the complete, professional invoice document — printable as-is — with the status controls beside it, never on it (data: `GET /invoices/{id}`).

## Layout

AppShell (no-print) → action bar (no-print): back link "← Invoices",
StatusBadge + StatusToggle, Edit (secondary; disabled with visible reason
"Paid — revert to unpaid to edit" when paid), Delete (ghost danger; same
lock), Print (secondary, triggers `window.print()`). Below: InvoiceDocument
(720px sheet on `surface`, radius.lg, shadow.sm): header row (wordmark-light
"Ledgerly" + displayNumber INV-0002 in mono title), meta grid (Issued
Aug 10, 2026 · Due Sep 9, 2026 · Paid date when set), "Billed to" client block
(name, email, address with preserved line breaks; null fields omitted),
line-item table (Description / Qty / Unit price / Amount — mono, right-aligned
numerics), total row (title-size mono), and a status stamp (Paid: accentSoft;
Unpaid: warnSoft) in the document corner so the printout carries status
(REQ-004 acceptance).

Print stylesheet: hides all `no-print` chrome and the state switcher, white
background, no shadows, document fills the page — one page per invoice.

## States

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | doc-shaped Skeleton (header bar, meta lines, 3 row lines, total block) | same geometry |
| **Empty** | Minimal-data variant: INV-0001, paid Aug 8, 2026, **no due date**, single line item — shows graceful omission of null dueDate and the paid-locked Edit/Delete affordances | "empty" = optional fields absent |
| **Ideal** | INV-0002 for Acme Design Co, unpaid, 2 line items, total $2,625.00 | contract's exact example aggregate |
| **Error** | Friendly panel: "This invoice couldn't be loaded." + Retry + "← All invoices" | server failure (INTERNAL) |
| **Partial** | Document loaded; status toggle failed → Banner "Couldn't update status. Try again." badge reverted | REQ-005 without reload |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| Invoice document | page load | `enter.default` (one block — never line-by-line) |
| StatusToggle → badge + stamp | mark paid | `move.default` swap + `emphasis`; paid date `enter.fast` |
| StatusToggle | mark unpaid | `move.default` only |
| ConfirmDialog (delete) | delete click on unpaid | `enter.default` / `exit.default` |
| Print | Print button | all motion suppressed in print media |

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Action bar wraps (back link on own line); document padding `space.4`; line-item table keeps 4 columns at `small` size — no horizontal scroll at 375px |
| 640–1024 | 720px document centered |
| > 1024 | Same; action bar single row |

## Accessibility

- Focus order: back link → status toggle → Edit → Delete → Print → document (readable, not interactive).
- Announcements: status change `aria-live="polite"` ("Marked paid, paid Aug 12, 2026").
- Contrast: document text `text` on `surface` 14.9:1; stamp pairs ≥ 6.2:1.
- Reduced motion: document appears instantly; badge swap instant.
