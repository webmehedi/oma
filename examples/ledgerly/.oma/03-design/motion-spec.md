# Motion spec — Ledgerly

> FROZEN at the Design gate. Both the HTML mockups (Lenis + Motion) and the
> production build (Lenis + Framer Motion) read their values from this file.
> This is what keeps "the mockup felt great, the build feels wrong" from
> happening: motion is tokens, not per-implementation taste.

## Principles

1. Motion explains causality — things enter from where they came, exit toward
   where they went. Never decoration for its own sake.
2. Fast is polite. Nothing the user waits on runs longer than 320ms. Ledgerly
   is a record-keeping tool Maya runs weekly; motion confirms actions
   (status flipped, total recomputed, row removed) and otherwise stays out of
   the way. Numbers never animate their digits — a money figure appears at its
   final value (a rolling total is a rounding error waiting to be mistrusted).
3. `prefers-reduced-motion: reduce` collapses all durations to 0ms and replaces
   transforms with opacity-only. **This is not optional and is never gated.**
   Lenis is not initialized under reduced motion.
4. The single `emphasis` spring is reserved for the one moment that deserves
   delight: an invoice flipping to Paid. Nothing else uses it.

## Duration & easing tokens

| Token | Duration | Easing | Use |
|---|---|---|---|
| `enter.fast` | 180ms | cubic-bezier(.2, 0, 0, 1) | tooltips, dropdowns, menu items, inline validation messages |
| `enter.default` | 320ms | cubic-bezier(.2, 0, 0, 1) | cards, modals, panels, state-panel swaps |
| `exit.fast` | 120ms | cubic-bezier(.4, 0, 1, 1) | tooltip/menu dismissal, inline message clear |
| `exit.default` | 200ms | cubic-bezier(.4, 0, 1, 1) | modal/panel dismissal, line-item row removal |
| `move.default` | 260ms | cubic-bezier(.4, 0, .2, 1) | layout shifts, filter-tab indicator, line-item reflow, badge color swap |
| `emphasis` | 400ms | spring(1, 80, 12) | Paid confirmation only (badge + paid-date pop on the toggled invoice) |

## Stagger tokens

| Token | Value | Use |
|---|---|---|
| `stagger.list` | 40ms | table-row / card cascade on load, max 8 items then batch the rest |
| `stagger.hero` | 90ms | dashboard first paint: stat cards → recent list header → rows |

## Scroll tokens

| Token | Value | Use |
|---|---|---|
| `scroll.lerp` | 0.1 | Lenis smoothing factor |
| `scroll.reveal.offset` | 15% | viewport intersection before reveal fires |
| `scroll.reveal.distance` | 24px | translateY of scroll-in elements |

## Page transitions

Hard cut between routes in v1 (View Transitions API is a progressive
enhancement, not specced). No shared-element morphs: pages are short and the
app is desktop-first CRUD — a 320ms content `enter.default` fade+rise on the
main region after navigation is the entire transition. The invoice document on
the detail page enters as one block, never line-by-line.

## Per-screen choreography

Only deviations from defaults; everything else uses the tokens above.

| Screen | Moment | Spec |
|---|---|---|
| Dashboard | first paint | `stagger.hero` across: outstanding stat → paid-this-month stat → recent-invoices card; rows inside use `stagger.list` |
| Dashboard / Invoice list / Invoice detail | mark paid | badge swaps color over `move.default`, then scales 1 → 1.06 → 1 with `emphasis`; paid date fades in `enter.fast`. Revert to unpaid uses `move.default` only — no spring for taking money back off the books |
| Invoice form | add line item | new row enters `enter.fast` (fade + 8px rise); totals region re-renders instantly (no number tween), its container pulses background `surfaceSunken` → `surface` over `move.default` to point the eye |
| Invoice form | remove line item | row exits `exit.default` (fade + height collapse); rows below reflow `move.default` |
| Invoice list | filter change | rows crossfade `exit.fast` → `enter.fast` with `stagger.list`; tab indicator slides `move.default` |
| Auth | error | error banner enters `enter.fast`; the card does **not** shake (shame is not a motion token) |
| Invoice detail | print | all motion suppressed in print media; document renders static |

## Reduced-motion behavior (normative)

- All durations → 0ms; transforms dropped; opacity may snap.
- Lenis not constructed; native scroll.
- Reveal-on-scroll elements are simply visible.
- The `emphasis` paid confirmation becomes an instant badge swap.
