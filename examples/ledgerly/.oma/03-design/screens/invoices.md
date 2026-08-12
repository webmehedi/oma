# Screen — Invoice list

- **Route:** `/invoices` (filter state in URL: `?status=unpaid|paid`, `?page=N`)
- **Requirements:** REQ-007, REQ-005 (row toggle), REQ-008 (delete entry point), REQ-009
- **Mockup:** ../mockups/invoices.html
- **Personas:** Maya chasing unpaid invoices (filter → unpaid in one click); Tomás looking for last month's invoice to check if it was paid.

## Purpose

Browse every invoice, newest first, and narrow to unpaid/paid without losing the state on reload (data: `GET /invoices?status=&page=`).

## Layout

AppShell → PageHeader ("Invoices", primary "New invoice" → invoice-form).
FilterTabs (All / Unpaid / Paid) directly above a DataTable: number (mono),
client, issue date, total (mono, right), StatusBadge, StatusToggle, overflow
row actions (Edit → invoice-form, Delete → ConfirmDialog; both disabled with
"Paid — locked" reason on paid rows per REQ-008). Rows link to invoice-detail.
Pagination footer appears only past 25 rows (fixed page size — contract).

## States

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | FilterTabs + 6 row Skeletons | tabs stay interactive |
| **Empty** | Account has zero invoices → EmptyState "No invoices yet…" + "Create your first invoice". Filtered-empty is different copy: "No paid invoices yet." (no CTA, filter is the fix) | both shown in mockup |
| **Ideal** | 7 rows, newest first (INV-0007 → INV-0001); URL shown reflecting `?status=` | dataset consistent app-wide |
| **Error** | danger Banner "Couldn't load invoices." + Retry | tabs remain |
| **Partial** | List loaded; a row's status toggle failed → inline Banner "Couldn't update INV-0003. Try again." row reverts to previous badge | optimistic UI rolled back |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| Rows | first paint / filter change | `stagger.list` (crossfade `exit.fast` → `enter.fast`) |
| FilterTabs indicator | tab change | `move.default` |
| StatusToggle → badge | mark paid | `move.default` + `emphasis`; unpaid revert `move.default` only |
| Row removal (delete confirmed) | ConfirmDialog confirm | `exit.default` + `move.default` reflow |

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Rows collapse to stacked cards: number + badge on line 1, client + date line 2, total + toggle line 3; tabs full-width segmented |
| 640–1024 | Table without row-action overflow (actions live on detail) |
| > 1024 | Full tabular layout using available width (REQ-010) |

## Accessibility

- Focus order: New invoice → tabs (arrow-key group) → row link → toggle → row actions.
- Announcements: filter result count (`aria-live="polite"`: "4 unpaid invoices"); toggle results as on dashboard.
- Contrast: badges and muted dates per token pairs.
- Reduced motion: filter swaps content instantly; no stagger.
