# Screen — Auth (sign in / create account)

- **Route:** `/signin` (and `/signup` — same screen, mode toggle)
- **Requirements:** REQ-001, REQ-009
- **Mockup:** ../mockups/auth.html
- **Personas:** Maya signing in mid-week (wants speed); Tomás after a month away (must not have to think). Signed-out visits to any app page land here.

## Purpose

Get an existing user into the app, or create the account — nothing else lives here.

## Layout

Centered single card (max 400px) on `bg`; brand wordmark above. Card contains
a two-tab mode toggle (Sign in / Create account), then TextField (email),
TextField (password, with the 8-char minimum as hint text in signup mode), one
primary Button full-width. No nav chrome — AppShell is absent. Below the card:
a `small` muted line noting password reset is not available in v1 ("Contact
support to recover access") so the dead end is honest, not silent.

## States

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | Submit button in `loading` state (spinner, width preserved), fields disabled | no layout shift on resolve |
| **Empty** | Pristine form, email field focused, Sign in tab active | first-run / signed-out redirect landing |
| **Ideal** | Filled valid form ready to submit; on success client redirects to `/dashboard` | |
| **Error** | Banner in-card: `INVALID_CREDENTIALS` → "Email or password is incorrect."; signup `EMAIL_TAKEN` → "An account with this email already exists." + a link that switches to the Sign in tab | fields keep values; password keeps focus |
| **Partial** | `VALIDATION_FAILED`: per-field FieldErrors from `error.details` (e.g. password under 8 chars in signup) | only invalid fields marked |

## Interactions & motion

| Element | Trigger | Motion token |
|---|---|---|
| Auth card | page load | `enter.default` |
| Mode toggle indicator | tab change | `move.default` |
| Error banner / FieldError | server or validation failure | `enter.fast` (no shake — see motion-spec) |
| Banner dismissal on retype | input event | `exit.fast` |

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | Card goes full-width with `space.4` gutters; tap targets stay 40px |
| 640–1024 | Centered 400px card |
| > 1024 | Same; generous vertical centering |

## Accessibility

- Focus order: mode tab → email → password → submit. Autofocus email.
- Announcements: error Banner is `role="alert"`; FieldErrors via `aria-describedby`.
- Contrast: all pairs from tokens (≥ 4.5:1); placeholder text is never the label.
- Reduced motion: card and banner appear instantly; tab indicator jumps.
