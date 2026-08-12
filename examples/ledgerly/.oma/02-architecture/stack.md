# Stack — Ledgerly (resolved)

> Resolved by oma-architect on 2026-08-12 from profile `web-app-default` +
> override `db: sqlite`. This file is authoritative. Dev agents build against
> THIS file, not the profile. Deviation requires a change request through
> `/oma:change` — not a judgment call in a task branch.

## Resolution summary

| Concern | Profile said | Override | Resolved |
|---|---|---|---|
| Database | PostgreSQL via Prisma | `db: sqlite` | **SQLite via Prisma** (better-sqlite3 driver adapter), file at `./data/ledgerly.db` |
| Everything else | — | none | Profile stands as written |

The SQLite choice is local/demo-driven; ADR-001 records the portability
guardrails that keep a v2 Postgres move to a driver-adapter + migration swap
(answers open question Q-001).

## Pinned versions

Verified against the npm registry this session (`npm view <pkg> version`,
2026-08-12). Install these exact versions; no `^`/`~` ranges in package.json.

### Runtime

| Package | Version | Role |
|---|---|---|
| `next` | 16.3.0 | Framework, App Router |
| `react` | 19.2.8 | UI runtime |
| `react-dom` | 19.2.8 | UI runtime |
| `@prisma/client` | 7.9.1 | DB client |
| `@prisma/adapter-better-sqlite3` | 7.9.1 | Prisma driver adapter for SQLite |
| `better-sqlite3` | 13.0.3 | SQLite driver |
| `zod` | 4.4.3 | Validation at every trust boundary |
| `@node-rs/argon2` | 2.0.2 | argon2id password hashing |
| `tailwindcss` | 4.3.3 | Styling |
| `framer-motion` | 13.1.0 | Motion (values from motion-spec.md only) |
| `lenis` | 1.3.26 | Smooth scroll (respect `prefers-reduced-motion`) |

### Dev / tooling

| Package | Version | Role |
|---|---|---|
| `typescript` | 6.0.3 | `strict: true`; no `any` without inline justification |
| `prisma` | 7.9.1 | CLI, migrations |
| `vitest` | 4.1.10 | Unit tests |
| `@playwright/test` | 1.62.1 | E2E — auth + core loop (create invoice → send-ready → mark paid) only |
| `eslint` | 9.39.5 | Lint |
| `eslint-config-next` | 16.3.0 | Next lint rules |
| `prettier` | 3.9.6 | Format, never argued with |
| `@types/node` | 26.2.0 | Types |
| `@types/react` | 19.2.18 | Types |
| `@types/react-dom` | 19.2.4 | Types |
| `@types/better-sqlite3` | 9.6.0 | Types |

Node.js: use the active LTS available in CI; engines field `>=22`.

## Database specifics (sqlite override)

- Prisma datasource `provider = "sqlite"`, connected through
  `@prisma/adapter-better-sqlite3` in `src/server/db.ts`. The adapter is the
  ONLY place the concrete database is named — services see `PrismaClient` only.
- DB file: `./data/ledgerly.db` (gitignored; `data/` created at boot).
  `DATABASE_URL="file:./data/ledgerly.db"` validated in `src/server/env.ts`.
- **Portability guardrails (ADR-001, binding on Backend):**
  - No raw SQL (`$queryRaw`/`$executeRaw`). Prisma Client API only.
  - No SQLite pragmas or SQLite-only column tricks in app code, except WAL
    mode set once inside `db.ts` (adapter setup — the file that changes in v2).
  - IDs are app-generated `cuid(2)` strings — no `AUTOINCREMENT`, no rowid
    dependence.
  - Money/quantities are integers (ADR-003); dates are UTC `DateTime` —
    nothing relies on SQLite's loose typing.
  - Enum-like fields (invoice status) are strings constrained by Zod at the
    boundary and by the service layer (SQLite lacks enums; Postgres v2 may add
    a CHECK/enum in a migration).
- Concurrency: better-sqlite3 is synchronous single-writer; fine for a
  single-user demo. Do not add connection pooling knobs — that's v2/Postgres.

## Auth (as it actually works — see ADR-002)

- Cookie: `ledgerly_session`, httpOnly, `SameSite=Lax`, `Secure` in
  production, `Path=/`. Value is an opaque 256-bit random token (base64url),
  NOT a JWT.
- Server-side `Session` row keyed by the SHA-256 of the token; 30-day sliding
  expiry (refreshed on use at most once/24h). Sign-out deletes the row and
  clears the cookie.
- Passwords: argon2id via `@node-rs/argon2`, library defaults (m=19456 KiB,
  t=2, p=1 class). Emails lowercased before uniqueness check and lookup.

## Directory contract

```
src/
├── app/                  # routes (App Router) — Frontend territory
├── components/           # shared UI — Frontend territory
├── server/               # services, data access — Backend territory
│   ├── services/         # ALL Prisma access lives here
│   ├── db.ts             # PrismaClient + sqlite adapter (only db-aware file)
│   └── env.ts            # Zod-validated env; app refuses to start half-configured
├── shared/               # types + Zod schemas — Backend writes, both read
│   └── schemas/
prisma/                   # schema + migrations — Backend territory
data/                     # sqlite file, gitignored
e2e/                      # Playwright — QA territory
```

Frontend never imports from `server/`. Backend never imports from `app/` or
`components/`. Both import freely from `shared/`.

## Conventions (binding)

- API routes return the uniform envelope: `{ data }` on success,
  `{ error: { code, message, details? } }` on failure. Codes are
  SCREAMING_SNAKE and enumerated in `api-contract.yaml` — no ad-hoc codes.
- Server code never throws raw — services return typed results; route
  handlers map them to the envelope.
- Database access only through `src/server/services/` — no Prisma calls in
  route handlers or components.
- Dates in UTC in the database; date-only values (issue/due/paid dates) are
  `YYYY-MM-DD` strings at the API boundary, formatted for display at the edge.
- All monetary amounts are integer cents end-to-end (ADR-003); the ONLY place
  dollars appear is display formatting.
- Every migration is additive during v1; destructive migrations need an ADR.
- CI (GitHub Actions): install → typecheck → lint → test → build.
- Container: multi-stage Dockerfile, non-root user, `.dockerignore` day one;
  `data/` mounted as a volume.

## Compatibility proof (added post-pin, 2026-08-12)

Original pins failed to compose twice: typescript@7.0.2 (typescript-eslint
unsupported) and eslint@10.8.1 (eslint-plugin-react in eslint-config-next
crashes). Stepped back to typescript@6.0.3 + eslint@9.39.5.
Proof on the real repo: install=0, typecheck=0, lint=0, build=0.
