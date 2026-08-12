# Stack profile: web-app-default

The opinionated default. Used unless the user overrides at `/oma:init`. The
Architect resolves this profile plus any user overrides into the project's
authoritative `.oma/02-architecture/stack.md` — agents read THAT file, not this
one, because this one doesn't know about the overrides.

## Core

| Concern | Choice | Notes |
|---|---|---|
| Framework | Next.js (App Router) | Server Components by default; Client Components only where interaction demands |
| Language | TypeScript, `strict: true` | no `any` without an inline justification comment |
| Database | PostgreSQL via Prisma | override `db: sqlite` for local-only/demo projects |
| Auth | Cookie sessions | httpOnly + SameSite=Lax, argon2id hashing; no JWT unless an ADR argues for it |
| Validation | Zod at every trust boundary | schemas in `src/shared/schemas/`, shared client and server |
| Styling | Tailwind CSS | theme extends CSS custom properties generated from `tokens.json` |
| Motion | Framer Motion + Lenis | all values from `.oma/03-design/motion-spec.md`; `prefers-reduced-motion` honored everywhere |
| Testing | Vitest (unit) + Playwright (e2e) | e2e on critical paths only — auth, the core loop, payments if present |
| Lint/format | ESLint + Prettier | enforced in CI, never argued with |
| CI | GitHub Actions | install → typecheck → lint → test → build |
| Container | Multi-stage Dockerfile | non-root user, `.dockerignore` from day one |

## Directory contract

```
src/
├── app/                  # routes (App Router) — Frontend territory
├── components/           # shared UI — Frontend territory
├── server/               # services, data access — Backend territory
│   ├── services/
│   └── db.ts
├── shared/               # types + Zod schemas — Backend writes, both read
│   └── schemas/
prisma/                   # schema + migrations — Backend territory
e2e/                      # Playwright — QA territory
```

Frontend never imports from `server/`. Backend never imports from `app/` or
`components/`. Both import freely from `shared/`. This boundary is what lets
them build in parallel without conflicts.

## Conventions

- API routes return a uniform envelope: `{ data }` on success, `{ error: { code, message } }` on failure. Codes are SCREAMING_SNAKE and enumerated in the API contract.
- Server code never throws raw — every service returns typed results; route handlers map them to the envelope.
- Environment variables validated at boot with Zod (`src/server/env.ts`); the app refuses to start half-configured.
- Database access only through `src/server/services/` — no Prisma calls in route handlers.
- Dates in UTC in the database, formatted at the edge.
- Every migration is additive during v1; destructive migrations need an ADR.

## Version policy

This profile deliberately names no versions — they'd be stale within a month.
The Architect pins exact versions in `stack.md` at architecture time.

**Pin the latest set that composes, not the latest of each package.** These are
not the same thing, and assuming they are is a documented failure mode: pinning
latest-of-everything has produced stacks where the compiler major outran the
linter's plugin support, and where the framework's bundled lint config crashed
on the newest linter major. Neither was visible in registry metadata.

Two rules that follow:

1. **The framework's own toolchain wins.** When the framework ships or peer-depends
   on a lint config, compiler range, or build tool, those constraints outrank
   independently-latest sub-packages. Check the framework's peer dependencies
   before pinning anything it touches.
2. **Prove it before freezing.** The Architect must scaffold a throwaway project
   and run install → typecheck → lint → build green before the pins enter
   `stack.md`. `stack.md` freezes at the Architecture gate, so an unproven pin
   set can only be undone through `/oma:change`.
