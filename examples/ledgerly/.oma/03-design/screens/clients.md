# Screen — Clients

- **Route:** `/clients`
- **Requirements:** REQ-002, REQ-009
- **Mockup:** ../mockups/clients.html
- **Personas:** Maya, once during setup (high patience) then rarely; Tomás adding his first client on the way to his first invoice.

## Purpose

Maintain the client list that invoices attach to — list, create, edit, and delete-when-unreferenced (data: `GET/POST /clients`, `PATCH/DELETE /clients/{id}`).

## Layout

AppShell → PageHeader ("Clients", primary action "Add client"). DataTable:
name, email (muted, "—" when null), invoices count (mono), actions (Edit
ghost-button; Delete ghost-danger, only enabled when `invoiceCount` is 0,
otherwise disabled with title/hint "Has invoices — cannot be deleted").
"Add client" and Edit open the same inline ClientForm panel that slides in
above the table (name required, email optional, address optional textarea,
Save primary + Cancel ghost). No separate route — REQ-002 is one screen.

## States

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | 4 row Skeletons | |
| **Empty** | EmptyState: "No clients yet. Add your first client — invoices always attach to a client." + "Add your first client" opens the form panel | Tomás's first step |
| **Ideal** | 4 clients: Acme Design Co (3), Bluebird Cafe (0), Hearthstone Yoga (2), Northwind Press (2); name-ascending | matches `GET /clients` shape |
| **Error** | danger Banner "Couldn't load clients." + Retry | |
| **Partial** | Form panel open with `VALIDATION_FAILED` on empty name ("Name is required.") ; separately a `CLIENT_HAS_INVOICES` Banner shown if a blocked delete is forced | inline, field-level (REQ-002 acceptance) |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| Table rows | first paint | `stagger.list` |
| ClientForm panel | open / close | `enter.default` / `exit.default` |
| FieldError | validation failure | `enter.fast` |
| ConfirmDialog (delete Bluebird Cafe) | delete click | `enter.default` / `exit.default` |
| Row removal after delete | confirm | `exit.default` + `move.default` reflow |

Edited client fields propagate to existing invoices' send-ready views (live
reference — contract `ClientRef`); the form's helper text says so.

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Table → stacked cards (name + count, email below, actions row); form panel full-width |
| 640–1024 | Full table; form panel max 560px |
| > 1024 | Same, 1120px container |

## Accessibility

- Focus order: Add client → rows (Edit → Delete per row). Opening the form moves focus to Name; closing returns it to the invoker.
- Announcements: save/delete results `aria-live="polite"`; disabled Delete carries `aria-disabled` + visible reason on hover/focus.
- Contrast: muted email text 7.0:1 on surface.
- Reduced motion: panel and dialog appear/disappear instantly.
