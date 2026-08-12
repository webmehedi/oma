# Design system — Ledgerly

## Personality

Ledgerly looks like a well-kept paper ledger run by someone calm: warm paper
neutrals, ink-dark text, one deep ledger-green accent, and money set in a
monospaced column that always lines up. Nothing bounces for attention — the
product's promise is "the number is right," so the design's job is to make
numbers feel authoritative and statuses unmistakable at a glance. Maya runs the
core loop several times a week on a 13" laptop, so density leans comfortable-
compact on desktop; Tomás returns after a month away, so every screen has
exactly one visually-primary action and empty screens always say what to do
next. Amber means money still owed; green means money arrived; nothing else
gets to use those two hues.

## Type scale

Family: system sans (`ui-sans-serif` stack) for UI; system mono
(`ui-monospace` stack, tabular figures) for **all monetary amounts, invoice
numbers, and dates in tables** — alignment is trust.

| Token | Size/Line | Weight | Usage rule |
|---|---|---|---|
| `type.display` | 32/40 | 650 | The dashboard outstanding figure and page-level money totals only. Never for headings. |
| `type.title` | 24/32 | 650 | One per page: the page title (and the invoice total on the send-ready doc). |
| `type.heading` | 18/26 | 600 | Card titles, section headers, modal titles. |
| `type.body` | 15/22 | 400 | Default UI text, table cells, form inputs. |
| `type.small` | 13/18 | 400 | Secondary metadata (dates in captions, helper text, counts). |
| `type.micro` | 12/16 | 550, uppercase, +0.06em tracking | Labels above form fields, table column headers, badge text, stat-card captions. |

Rules: money always mono with tabular numerals; never bold body text for
emphasis — promote to `heading` or use `textMuted`→`text` contrast instead.

## Color roles

Full values (light + dark) live in `tokens.json`; roles and when to use each:

| Role | Use | Never |
|---|---|---|
| `bg` | Page background (warm paper) | Behind body text blocks — use `surface` |
| `surface` | Cards, tables, forms, nav | — |
| `surfaceSunken` | Table header rows, skeletons, input wells on surface | Text on it below 4.5:1 |
| `border` / `borderStrong` | Hairlines / input borders & hover borders | As text color |
| `text` | Primary content | — |
| `textMuted` | Secondary metadata, labels | For amounts or statuses |
| `accent` / `accentHover` / `onAccent` | The one primary action per screen, links, focus ring, active nav | More than one primary button per view |
| `accentSoft` + `accentSoftText` | **Paid** badge, success confirmations | Generic decoration |
| `warnSoft` + `warnText` | **Unpaid** badge, the outstanding stat accent | Errors (that's danger) |
| `danger` / `onDanger` / `dangerSoft` + `dangerSoftText` | Destructive buttons, validation and server-error text, error banners | Unpaid status (unpaid is normal, not an error) |
| `focus` | 2px outline offset 2px on every focusable element | Being removed |

### Contrast (verified pairs, WCAG AA ≥ 4.5:1)

| Pair | Light | Dark |
|---|---|---|
| text / bg | 14.9:1 | 14.3:1 |
| textMuted / surface | 7.0:1 | 7.0:1 |
| onAccent / accent | 6.1:1 | 7.2:1 |
| accentSoftText / accentSoft (Paid badge) | 8.0:1 | 7.7:1 |
| warnText / warnSoft (Unpaid badge) | 6.2:1 | 7.6:1 |
| danger / surface | 6.5:1 | 5.9:1 |
| accent (as link text) / bg | 5.9:1 | 8.7:1 |

## Spacing rhythm

4px base. Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 (`space.1`–`space.16`).
Rhythm rules: 24px between sections, 16px card padding on mobile / 24px on
desktop, 12px vertical padding in table rows (10px on data-dense invoice
list), 8px label-to-input, 16px between form fields, 32px page-title to
content. Max content width 1120px; the send-ready invoice document is 720px.

## Border, radius, shadow language

- Radius: `sm` 6px (inputs, badges use `full`), `md` 10px (buttons, table
  wrapper), `lg` 14px (cards, modals, the invoice document). Nothing sharper,
  nothing rounder — pills are for badges only.
- Borders are 1px `border` hairlines; inputs use `borderStrong`. Elevation is
  mostly borders, not shadows — paper, not glass.
- Shadows: `shadow.sm` on cards at rest, `shadow.md` on raised interactive
  hover (row hover uses `surfaceSunken` tint instead), `shadow.lg` reserved
  for modals and the fixed state-switcher. No colored glows.

## Interactive states (every interactive element class)

| Element | Hover | Focus-visible | Active | Disabled |
|---|---|---|---|---|
| Primary button | `accentHover` bg | 2px `focus` outline, 2px offset | translateY(1px), `accentHover` | 45% opacity, cursor not-allowed, keep label readable |
| Secondary/ghost button | `surfaceSunken` bg | same outline | same press | same |
| Danger button | `dangerHover` bg | same outline | same press | same |
| Link / nav item | underline (nav: `text` color + active bar in `accent`) | same outline | — | — |
| Input / select / textarea | `borderStrong` border | `accent` border + 2px `focus` outline | — | `surfaceSunken` bg, muted text |
| Table row (linked) | `surfaceSunken` bg, cursor pointer | outline on the row link | — | — |
| Badge / status toggle | toggle button: as secondary button | same outline | — | paid-locked actions: disabled + reason text beside |

Invalid inputs: `danger` border + `dangerSoftText`-on-`dangerSoft` message
directly under the field, linked via `aria-describedby`.

## Voice in UI copy

Plain, short, second person. Errors say what happened and what to do next
("Email or password is incorrect." — from the API's `error.message`, which is
always safe to render). Empty states are one sentence plus one button.
