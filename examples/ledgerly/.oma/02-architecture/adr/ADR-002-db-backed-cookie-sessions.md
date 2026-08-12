# ADR-002: Database-backed cookie sessions with argon2id

- **Status:** accepted
- **Date:** 2026-08-12
- **Decider:** oma-architect
- **Requirements affected:** REQ-001

## Context

REQ-001 needs email+password auth with strict per-account data isolation and
an inline wrong-password error. The stack profile mandates cookie sessions
(httpOnly, SameSite=Lax, argon2id) and forbids JWT without an ADR arguing for
it. The remaining choice is where session state lives: stateless (signed
cookie) vs server-side (database row). Q-001's portability concern applies
here too — auth must not assume a single local process.

## Decision

We will store sessions as database rows and hand the browser only an opaque
token: cookie `ledgerly_session` (httpOnly, SameSite=Lax, Secure in prod,
Path=/) carries a 256-bit random base64url token; the `Session` table stores
its SHA-256 (`tokenHash`, unique) with `userId` and `expiresAt`. Expiry is
30-day sliding, refreshed on use at most once per 24h. Sign-out deletes the
row. Passwords are hashed with argon2id via `@node-rs/argon2` (library
defaults); emails are lowercased before uniqueness and lookup. Sign-in
failures return one code (`INVALID_CREDENTIALS`) for both bad email and bad
password — no account enumeration.

## Alternatives considered

| Option | Why not |
|---|---|
| JWT in cookie | No revocation without a denylist (which is just a session table with extra steps); profile forbids it by default |
| Signed/encrypted stateless cookie (iron-session style) | Sign-out and "session never survives credential concerns" become best-effort; a session table is trivial at this scale and revocation is exact |
| Auth library (NextAuth/Lucia) | v1 needs exactly signup/signin/signout; a framework brings config surface and upgrade churn larger than the ~150 lines it replaces |
| Storing raw token in DB | A DB read (backup, log leak) would yield live session credentials; hashing costs one SHA-256 per request |

## Consequences

- Every authenticated request costs one indexed session lookup — negligible on
  SQLite, and the same pattern works unchanged on Postgres (multi-instance
  safe, answering Q-001 for auth).
- Revocation is exact: delete the row and the session is dead everywhere.
- We own ~150 lines of auth code and its tests; Playwright covers the auth
  path per the profile.
- **Undo cost:** moderate — moving to JWT or an auth framework later means
  rewriting the auth service and invalidating all sessions (users re-sign-in),
  but no data-model damage beyond dropping the Session table.
