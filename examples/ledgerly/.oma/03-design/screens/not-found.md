# Screen — Not found

- **Route:** catch-all 404, plus `NOT_FOUND` responses for `/invoices/{id}` and `/clients/{id}` (unknown OR another account's id — the API never distinguishes)
- **Requirements:** REQ-009, REQ-001 (isolation presents as not-found)
- **Mockup:** ../mockups/not-found.html
- **Personas:** Tomás following a stale bookmark; anyone mistyping a URL. Must be a friendly turn-around, not a dead end.

## Purpose

Tell the user the thing isn't here and hand them the one link back to the relevant list.

## Layout

AppShell (nav stays — the user is signed in and should not feel ejected) →
centered EmptyState-style block, 480px max: ledger-line glyph, heading, one
sentence, one primary link back to the relevant list (invoices / clients /
dashboard depending on which route missed).

## States

This page is static (no async data), so the five mockup states demonstrate its
three content variants plus its degenerate cases:

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | Brief content Skeleton | only while route resolution confirms the 404 (edit-URL probe) |
| **Empty** | Generic variant: "This page doesn't exist." + "Go to dashboard" | unmatched route |
| **Ideal** | Invoice variant: "This invoice doesn't exist — it may have been deleted." + "← All invoices" | `NOT_FOUND` on `GET /invoices/{id}` |
| **Error** | Server-failure variant (`INTERNAL`): "Something went wrong on our side." + Retry | distinct copy from 404 — different cause, different action |
| **Partial** | Client variant: "This client doesn't exist." + "← All clients" | `NOT_FOUND` on `GET /clients/{id}` |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| Content block | page load | `enter.default` |

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Full-width with gutters |
| 640–1024 | Centered 480px |
| > 1024 | Same |

## Accessibility

- Focus order: nav → the single CTA link.
- Announcements: heading is the page `<h1>`; no live regions needed.
- Contrast: standard token pairs.
- Reduced motion: block appears instantly.
