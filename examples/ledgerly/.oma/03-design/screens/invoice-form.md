# Screen — Invoice form (create / edit)

- **Route:** `/invoices/new` and `/invoices/{id}/edit` (same screen, mode prop)
- **Requirements:** REQ-003, REQ-008, REQ-009
- **Mockup:** ../mockups/invoice-form.html
- **Personas:** Maya, 5–15 times a month — this screen's speed decides whether Ledgerly beats her spreadsheet. Under two minutes from blank to saved.

## Purpose

Compose an invoice from a client + line items with the total computed live — the user never does arithmetic (data: `POST /invoices`, `GET/PATCH /invoices/{id}`).

## Layout

AppShell → PageHeader ("New invoice" / "Edit INV-0007"). Single-column form,
720px max: SelectField Client (required, options from `GET /clients`, with an
inline "Add a client first" link to clients when the list is empty) → DateField
row: Issue date (default today 2026-08-12, editable) + Due date (optional) →
LineItemEditor (description / qty / unit price / computed amount per row;
Add line item; last row's remove disabled) → InvoiceTotals (live total, mono
title size) → footer: Save invoice (primary) + Cancel (ghost, back to list).
Edit mode is reachable only for unpaid invoices; a paid invoice's edit URL
shows the `INVOICE_PAID_LOCKED` Banner with "Revert to unpaid to edit."

## States

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | Edit mode: field + row Skeletons in form geometry | create mode never loads |
| **Empty** | Create mode pristine: client placeholder "Choose a client…", today's date filled, one blank line-item row, total $0.00, Save disabled until valid | defaults per REQ-003 |
| **Ideal** | Edit of INV-0007 (Acme): 2 line items, live total $1,875.00 | amounts recompute on every keystroke |
| **Error** | Save failed (`INTERNAL`) → danger Banner "Something went wrong saving this invoice. Your entries are still here — try again." + Retry; entries preserved | |
| **Partial** | `VALIDATION_FAILED` mapped per field: no client ("Choose a client."), empty description, negative unit price ("Price can't be negative."), zero line items ("Add at least one line item.") | REQ-003 acceptance |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| New line-item row | Add line item | `enter.fast` (fade + 8px rise) |
| Row removal | remove button | `exit.default` collapse + `move.default` reflow |
| Totals container | any amount change | background pulse `move.default` (numbers never tween — motion-spec) |
| FieldError | validation | `enter.fast` |
| Form card | page load | `enter.default` |

Amount math mirrors ADR-003: per-line `round(qty × unitPrice)` half-up, then
sum; qty accepts up to 3 decimals (7.5 hours); unit price entered in dollars,
stored as cents.

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Line-item rows stack (description full-width; qty/price/amount in one row below); dates stack; sticky Save bar at bottom |
| 640–1024 | Grid rows as designed |
| > 1024 | Same, centered 720px |

## Accessibility

- Focus order: client → issue date → due date → row fields left-to-right per row → add line → save. New rows receive focus on their description.
- Announcements: total changes `aria-live="polite"` ("Total $1,875.00"); errors `role="alert"`.
- Contrast: computed amount cells `text` on `surface`; disabled Save keeps readable label.
- Reduced motion: rows appear/remove instantly, no pulse.
