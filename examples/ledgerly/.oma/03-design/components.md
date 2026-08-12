# Component inventory — Ledgerly

> The Frontend agent builds exactly this list. A component not in this
> inventory doesn't get built; a screen needing a new one is a design change.
> Props typed informally. All colors/spacing/type via tokens.json; all motion
> via motion-spec.md tokens.

## Layout

### AppShell
- **Props:** `activeNav: 'dashboard' | 'invoices' | 'clients'`, `userEmail: string`, `children`
- **Owns:** top nav (brand, Dashboard/Invoices/Clients links with active bar, user email + Sign out button), 1120px content container, `no-print` chrome behavior.
- **States:** active link (accent bar + `text` color), hover, focus-visible. Collapses to brand + horizontal scroll-safe nav row under 640px.
- **Used by:** dashboard, invoices, invoice-form, invoice-detail, clients, not-found.

### PageHeader
- **Props:** `title: string`, `action?: ReactNode` (one primary action max), `meta?: ReactNode`
- **Used by:** dashboard, invoices, clients, invoice-form, invoice-detail.

## Primitives

### Button
- **Props:** `variant: 'primary' | 'secondary' | 'ghost' | 'danger'`, `size: 'md' | 'sm'`, `disabled?: boolean`, `loading?: boolean` (spinner replaces label, width preserved), standard button attrs.
- **Owns:** hover/focus/active/disabled per design-system.md; loading state.
- **Used by:** every screen.

### TextField / TextArea
- **Props:** `label: string`, `name`, `type?`, `required?`, `error?: string`, `hint?: string`, `placeholder?`
- **Owns:** micro-label, input well, invalid state (danger border + message wired via `aria-describedby`), disabled.
- **Used by:** auth, clients (form), invoice-form.

### SelectField
- **Props:** `label`, `options: {value, label}[]`, `error?`, `placeholder?`
- **Owns:** same field chrome as TextField. Native `<select>`.
- **Used by:** invoice-form (client picker).

### DateField
- **Props:** `label`, `value?: 'YYYY-MM-DD'`, `optional?: boolean`, `error?`
- **Owns:** native date input styled to field chrome; renders the API's date-only strings.
- **Used by:** invoice-form (issue/due), mark-paid modal-free default (paidDate defaults to today — no picker in v1 flows).

### StatusBadge
- **Props:** `status: 'paid' | 'unpaid'`, `emphasize?: boolean` (plays `emphasis` once on flip to paid)
- **Owns:** pill (radius.full), `accentSoft`/`accentSoftText` for paid, `warnSoft`/`warnText` for unpaid, micro type.
- **Used by:** dashboard, invoices, invoice-detail.

### StatusToggle
- **Props:** `status`, `onToggle`, `busy?: boolean`
- **Owns:** the one-click "Mark paid"/"Mark unpaid" secondary button (REQ-005), optimistic swap, busy state. Calls `POST /invoices/{id}/status`.
- **Used by:** dashboard rows, invoice list rows, invoice-detail header.

## Data display

### StatCard
- **Props:** `label: string`, `amountCents: number`, `tone: 'warn' | 'accent' | 'neutral'`, `loading?: boolean`
- **Owns:** micro label, display-size mono amount, skeleton variant. Tone tints the label only, never the number.
- **Used by:** dashboard (Outstanding = warn, Paid in <month> = accent).

### DataTable
- **Props:** `columns: {key, label, align?, mono?}[]`, `rows`, `rowHref?: (row) => string`, `loading?: boolean` (skeleton rows), `footer?`
- **Owns:** sunken header row, row hover, linked-row focus, mono/right-aligned money columns, mobile collapse to stacked cards under 640px.
- **Used by:** dashboard (recent invoices), invoices, clients.

### InvoiceDocument
- **Props:** `invoice: Invoice` (full aggregate from `GET /invoices/{id}`)
- **Owns:** the send-ready sheet (REQ-004): brand-light header, displayNumber, issue/due/paid dates, client block (name, email, address with preserved newlines), line-item table (description, qty, unit price, amount), total row, status stamp. Print-clean: fits one page, no chrome. Omits null dueDate/email/address rows gracefully.
- **Used by:** invoice-detail.

### Pagination
- **Props:** `page`, `pageSize: 25`, `total`, `onPage`
- **Owns:** "1–25 of 32" caption + prev/next; hidden entirely when `total <= pageSize`.
- **Used by:** invoices.

### FilterTabs
- **Props:** `value: 'all' | 'unpaid' | 'paid'`, `counts?: Record<string, number>`, `onChange` (writes `?status=` to URL, REQ-007)
- **Owns:** segmented control, sliding active indicator (`move.default`), focus states.
- **Used by:** invoices.

## Feedback

### EmptyState
- **Props:** `title: string`, `body: string`, `action: {label, href}`
- **Owns:** centered block with ledger-line glyph (inline SVG using currentColor), one CTA (REQ-009).
- **Used by:** dashboard, invoices, clients.

### Banner
- **Props:** `tone: 'danger' | 'neutral'`, `message: string`, `retry?: () => void`
- **Owns:** inline page-level error surface with optional Retry button (REQ-009). Renders `error.message` from the envelope verbatim.
- **Used by:** all app screens (error/partial states).

### FieldError
- **Props:** `message: string` — rendered by TextField/SelectField/DateField; maps `error.details[field]` from `VALIDATION_FAILED`.
- **Used by:** auth, clients form, invoice-form.

### ConfirmDialog
- **Props:** `title`, `body`, `confirmLabel`, `tone: 'danger'`, `onConfirm`, `onCancel`
- **Owns:** modal (radius.lg, shadow.lg), backdrop, `enter.default`/`exit.default`, focus trap, Escape to cancel. v1 uses: delete unpaid invoice (REQ-008), delete zero-invoice client (REQ-002).
- **Used by:** invoices/invoice-detail (delete invoice), clients (delete client).

### Skeleton
- **Props:** `variant: 'text' | 'stat' | 'row' | 'doc'`
- **Owns:** `surfaceSunken` shimmer blocks sized to the resolved layout (no layout shift on resolve).
- **Used by:** all app screens (loading states).

## Forms (composed)

### ClientForm
- **Props:** `mode: 'create' | 'edit'`, `client?: Client`, `onSaved`, `onCancel`
- **Owns:** name (required), email (optional), address (optional textarea) fields; maps `VALIDATION_FAILED.details` to FieldErrors; inline panel on the clients screen (REQ-002) — not a separate route.
- **Used by:** clients.

### LineItemEditor
- **Props:** `items: {description, quantity, unitPriceCents}[]`, `onChange`, `errors?: Record<index, {field: message}>`
- **Owns:** editable rows (description / qty / unit price / computed amount), remove-row button, "Add line item" ghost button, live per-row amount and running order. Enforces min 1 row visually (last row's remove is disabled with reason). Row enter/exit per motion-spec.
- **Used by:** invoice-form.

### InvoiceTotals
- **Props:** `lineItems`, computes and displays the live invoice total (client-side mirror of server math: round-half-up per line, then sum — ADR-003)
- **Owns:** total row typography (title-size mono), the `move.default` container pulse on recompute.
- **Used by:** invoice-form.

## Mockup-only (not built in production)

### StateSwitcher
- Fixed bottom-right control on every mockup page toggling the five demo
  states (loading / empty / ideal / error / partial). Exists so reviewers and
  the Frontend agent can see every state without a backend. Marked `no-print`.
