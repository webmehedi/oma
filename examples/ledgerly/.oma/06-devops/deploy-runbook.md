<!-- Written by oma-devops. Lives at .oma/06-devops/deploy-runbook.md
     Written for a tired person at 2am. Every command copy-pasteable, every
     expected result stated. OMA never runs any of these — the user does. -->

# Deploy runbook — Ledgerly

**Platform:** Fly.io · **Database:** SQLite file on a Fly volume · **Region:** your nearest (`fly platform regions`)
**Chosen because:** Ledgerly's database is a *file* that one process writes to (stack.md: better-sqlite3, single writer), so it needs a persistent disk and exactly one machine — which is what Fly gives and what Vercel, the usual Next.js answer, cannot: its filesystem is ephemeral and every request may land on a different instance, so the ledger would be silently destroyed on each deploy.

> Nothing in this file has been run against a live environment. OMA writes the
> runbook; you run it, with your credentials. Steps verified locally are marked
> ✅ verified; everything else is marked ⚠️ unverified.

---

## What was actually verified before this was written

Read this first — it tells you which failures below are already ruled out.

| Thing | How | Result |
|---|---|---|
| Full CI sequence, clean install | `npm ci` → `db:generate` → `typecheck` → `lint` → `format:check` → `test` → `build` | ✅ all exit 0; 191/191 unit tests |
| e2e suite | `CI=true npx playwright test` | ✅ exit 0, 11/11 — re-run *after* the `next.config.ts` header change |
| Image builds | `docker build -t ledgerly:local .` | ✅ exit 0 |
| Container boots on an **empty** volume | fresh named volume, `docker run` | ✅ both migrations applied, healthy in 5s |
| Migrations are idempotent on restart | `docker restart` | ✅ "No pending migrations to apply." |
| Data survives a restart | signup, restart, signup again | ✅ `409 EMAIL_TAKEN` — the row was still there |
| Real database round-trip in the container | `POST /api/auth/signup` → `GET /api/dashboard` | ✅ `201` then `200` with real JSON |
| Container runs non-root | `docker exec … id` | ✅ `uid=1000(node) gid=1000(node)` |
| Docker HEALTHCHECK passes | `docker inspect` | ✅ `healthy` |
| Security headers (SEC-003) | `curl -sD -` against the container | ✅ present on `/signin` and `/api/health` |
| `X-Powered-By` gone (SEC-009) | same | ✅ 0 occurrences |

**Never verified:** anything involving Fly.io itself — deploy, volume creation,
rollback, TLS, cold start, pricing. No deploy command was run and none will be.
Those steps are marked ⚠️ below.

---

## Prerequisites

| Need | Version | Install / get it |
|---|---|---|
| Fly.io account | — | https://fly.io/app/sign-up (card required; see **Cost**) |
| `flyctl` | current | `brew install flyctl` (macOS) or `curl -L https://fly.io/install.sh \| sh` |
| Signed in | — | `fly auth login` |
| Docker | any recent | Optional — Fly builds remotely by default. Only needed for `--local-only`. |

Node is **not** a prerequisite for deploying: the image builds Node into itself.

---

## Environment variables

Every variable the application reads. Full descriptions, and the grep that
found them, are in `.oma/06-devops/env.template`.

| Variable | Required | Where the value comes from |
|---|---|---|
| `DATABASE_URL` | **yes** | You choose it. In production it MUST be `file:/data/ledgerly.db` — an absolute path on the mounted volume. |
| `NODE_ENV` | yes | Already `production` in the image's runtime stage. Do not set it by hand. |
| `PORT` | no | Already `3000` in the image. Change it and you must change `EXPOSE`, the healthcheck and `fly.toml` together. |
| `HOSTNAME` | no | Already `0.0.0.0` in the image. It must stay `0.0.0.0` or nothing outside the container can reach the server. |
| `NEXT_TELEMETRY_DISABLED` | no | Already `1` in the image. |
| `CI` | no | Set by GitHub Actions only. Nothing in production reads it. |

**There is no secret in this list.** ADR-002: the session cookie is an opaque
random token and the server stores only its SHA-256, so there is no signing key
to leak or rotate. `DATABASE_URL` is a filesystem path, not a credential — which
is why the step below uses `[env]` in `fly.toml` and not `fly secrets set`.

> **The one expensive mistake.** If `DATABASE_URL` is left relative
> (`file:./data/ledgerly.db`), it resolves inside the container's own
> filesystem instead of the volume, and every deploy silently destroys the
> ledger. The `Dockerfile` already defaults it to the absolute path; the
> `fly.toml` below sets it again on purpose, so it is visible in a file you
> read rather than a default you have to remember.

---

## First deploy

⚠️ **Every command in this section is unverified** — they need your Fly account.

1. **Create the app without deploying it.**
   ```bash
   fly launch --no-deploy --copy-config --name ledgerly --region <your-region>
   ```
   Expect: `Your app is ready! Deploy with flyctl deploy`, and a `fly.toml`
   written into the repo. It will detect the `Dockerfile` and must **not** be
   allowed to add a Postgres or Redis — answer no to both. Ledgerly has no
   Postgres (ADR-001), and offering one is `fly launch` guessing.

2. **Replace the generated `fly.toml` with this.** The generated one will be
   close but will not have the volume mount, the single-machine constraint, or
   the health check path.
   ```toml
   app = "ledgerly"
   primary_region = "<your-region>"

   [build]

   [env]
     # Absolute, on the mount below. See the warning above.
     DATABASE_URL = "file:/data/ledgerly.db"
     PORT = "3000"
     HOSTNAME = "0.0.0.0"

   [[mounts]]
     source = "ledgerly_data"
     destination = "/data"

   [http_service]
     internal_port = 3000
     force_https = true          # HSTS is sent by the app; this makes it honest
     auto_stop_machines = "stop"
     auto_start_machines = true
     min_machines_running = 0    # see Cost — set 1 to avoid cold starts

     [[http_service.checks]]
       grace_period = "20s"
       interval = "30s"
       method = "GET"
       path = "/api/health"
       timeout = "5s"

   [[vm]]
     size = "shared-cpu-1x"
     memory = "512mb"
   ```

   **`min_machines_running` must never exceed 1, and you must never scale this
   app past one machine.** better-sqlite3 is a single writer and a Fly volume
   attaches to one machine at a time (stack.md; ADR-001 explicitly declines
   pooling). Two machines is not "slower" — it is a second machine that either
   cannot boot or writes to a different, diverging database file.

3. **Create the volume.** Must exist before the first deploy, in the same region.
   ```bash
   fly volumes create ledgerly_data --region <your-region> --size 1
   ```
   Expect: a volume ID like `vol_xxxxxxxx` and `Region: <your-region>`. 1 GB is
   far more than this app needs — the whole ledger is one SQLite file.

4. **Deploy.**
   ```bash
   fly deploy
   ```
   Expect: the image builds, then `1 desired, 1 placed, 1 healthy, 0 unhealthy`
   and a URL `https://ledgerly.fly.dev`. First boot runs both migrations against
   the empty volume — that path is ✅ verified locally and takes ~5 seconds.

5. **Verify** — next section. Do not skip it; a machine can be "placed" and
   still be failing its health check.

---

## Migrations

```bash
# You do not run this. It runs itself, at container start.
node migrator/node_modules/prisma/build/index.js migrate deploy
```

Migrations run in `docker-entrypoint.sh`, **at boot, inside the machine that
mounts the volume** — not during `docker build`, and deliberately **not** as a
Fly `release_command`.

**Why not `release_command`, even though that is the standard advice:** a Fly
release command runs in a temporary machine that does *not* mount the app's
volume. For a Postgres app that is fine — the database is over the network. For
Ledgerly the database *is* the volume, so a release command would migrate an
empty throwaway file, report success, and leave the real database untouched.
The only process that can see this database is the one that mounts it.

- `prisma migrate deploy` is idempotent: with nothing pending it prints
  `No pending migrations to apply.` and exits 0. ✅ verified locally by restart.
- If the migration fails, the entrypoint's `set -e` stops the boot and the
  server never starts — the machine fails its health check instead of serving
  against a half-migrated schema. That is the intended behaviour.
- This is safe **only** because there is exactly one machine. See step 2.

**Before any destructive migration** (dropped column, changed type, removed
table — every migration in v1 is additive by stack.md's rule, so this means
v1.1 onward), take a backup first:

```bash
# Preferred: Fly's own volume snapshot — consistent, no downtime, no tooling.
fly volumes list                          # get the vol_... id
fly volumes snapshots create <vol_id>
fly volumes snapshots list <vol_id>       # confirm it exists BEFORE deploying
```

```bash
# File copy alternative — read the warning.
fly machine stop <machine_id>             # stop writes first
fly ssh sftp get /data/ledgerly.db ./ledgerly-backup-$(date +%F).db
fly machine start <machine_id>
```

⚠️ **Do not copy the file off a running machine.** The database runs in WAL mode
(`src/server/db.ts`), so recent commits live in a separate `ledgerly.db-wal`
file. Copying only `ledgerly.db` from a live machine gives you a backup that is
missing whatever was written most recently — and it will look fine when you
open it. Either stop the machine, or use the volume snapshot.

The image contains no `sqlite3` binary, so `.backup` inside the container is not
available. The two options above are the ones that exist.

**Migration lock:** SQLite has no advisory lock to get stuck on, so the Postgres
"migration hangs holding a lock" failure does not apply here. What can happen
instead is a failed migration recorded in `_prisma_migrations` — the boot then
fails every time with `migrate found failed migrations`. Recovery is to restore
the snapshot from the backup step and redeploy the previous image; do not hand-
edit `_prisma_migrations` on a database with real invoices in it.

---

## Verify the deploy worked

```bash
curl -i https://ledgerly.fly.dev/api/health
```

Expect `200` and exactly this shape (✅ this response was verified against the
real container locally):

```
HTTP/2 200
x-frame-options: DENY
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), microphone=(), geolocation=(), interest-cohort=()
content-security-policy-report-only: default-src 'self'; ...
strict-transport-security: max-age=63072000; includeSubDomains

{"data":{"status":"ok","timestamp":"2026-..."}}
```

Three things that response proves at once: the process is serving, the SEC-003
headers are live, and `X-Powered-By` is gone (SEC-009).

**Then prove the database is really connected**, because `/api/health`
deliberately does not touch it:

```bash
curl -i -X POST https://ledgerly.fly.dev/api/auth/signup \
  -H 'content-type: application/json' \
  -d '{"email":"you@example.com","password":"<a real passphrase>"}'
```

Expect `201` and a JSON user with an `id`. A `500` here with a `200` on
`/api/health` means the server is up and the volume is wrong — go to
Troubleshooting row 3. Then sign in through the UI and create one invoice: the
core loop (client → invoice → mark paid → dashboard total) is what e2e covers
and what proves writes are landing on the volume.

**Logs:**
```bash
fly logs
```
The line that proves a clean boot is:
```
[entrypoint] starting Next standalone server on 0.0.0.0:3000
```
immediately preceded by either `All migrations have been successfully applied.`
(first boot) or `No pending migrations to apply.` (every boot after). If you see
`[entrypoint] applying migrations` and then nothing, the migration failed —
read the lines between them.

---

## Rollback

```bash
fly releases                                  # find the previous version number
fly deploy --image <image ref from that release>
```
⚠️ **Unverified — this path was never executed.** Nothing about a Fly rollback
was tested; only the local container's boot, restart and migration behaviour
were. Treat the command as the documented shape, not as something proven here.

Rollback restores the previous **code**. It does not undo an applied migration.

For Ledgerly specifically, that has a sharp edge worth knowing before you need
it: migrations run *at boot from the image you are rolling back to*. Rolling
back to an image whose `prisma/migrations` folder is missing the newest
migration does **not** revert the schema — the volume keeps the newer schema,
and Prisma will report drift against the older client. The two migrations that
exist today (`init`, `widen_money_columns_to_bigint`) are additive and
data-preserving, so a rollback across them is survivable. A future destructive
migration is not: for that one, the recovery path is **restore the volume
snapshot you took in the migrations step, then deploy the old image** — which
is why that backup step is not optional.

Decide which of those two you are doing *before* you start typing.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Build passes locally, fails in CI on `tsc` or `next build` | `generated/` is gitignored and there is no `postinstall`, so a fresh clone has no Prisma client | CI already runs `npm run db:generate` before typecheck. If you add a job, it needs that step too. |
| `fly deploy` build fails compiling `better-sqlite3` | native addon, no prebuild for the target | The `deps` stage already installs `python3 make g++`. If it still fails, the base image tag moved — pin `NODE_VERSION` in the Dockerfile. |
| Boot logs `MODULE_NOT_FOUND` on the release step | Something was pruned out of the Prisma CLI tree in the `migrator` stage | This bug was found and fixed here: the CLI `require`s `@prisma/studio-core` and `@prisma/dev` at load even for `migrate deploy`. The Dockerfile now **proves the prune at build time** by running a real `migrate deploy` in that stage. If you edit that `rm -rf` list, do not remove that proof step. |
| `200` on `/api/health` but every database call `500`s | volume not mounted, or `DATABASE_URL` relative | `fly ssh console -C "ls -la /data"` — you should see `ledgerly.db`. If `/data` is empty or missing, the `[[mounts]]` block is wrong or the volume is in another region. |
| Ledger is empty after a deploy | `DATABASE_URL` resolved inside the container instead of the volume | The data is gone with the old machine; restore a snapshot. Then fix `[env] DATABASE_URL` to the absolute `file:/data/ledgerly.db`. This is the single most expensive mistake available here. |
| App works, then a deploy fails with a volume error | Fly tried to place a second machine on a one-machine volume | `fly scale count 1`. Never scale past 1 — see the note in step 2. |
| First request after idle takes several seconds | `auto_stop_machines` stopped the machine; cold start = boot + migration check | Expected. Set `min_machines_running = 1` to trade money for latency. |
| Health check fails, logs say the server started fine | `HOSTNAME` is not `0.0.0.0`, so it bound an address unreachable from outside the container's network namespace | Set `HOSTNAME = "0.0.0.0"` in `fly.toml`. The image already does; only an override breaks it. |
| `npm start` locally warns `"next start" does not work with "output: standalone"` | `output: "standalone"` is required for the container's runtime stage | Advisory — the e2e suite passes through it (11/11 verified). Locally run `node .next/standalone/server.js` instead, or keep using `npm run dev`. |

---

## Cost

⚠️ **Verify current prices yourself at https://fly.io/docs/about/pricing/ before
deploying — this is the one section that goes stale without anyone noticing, and
a surprise bill is a real outcome for a solo developer.**

Fly.io no longer has the old always-free allowance; new organisations are
pay-as-you-go with a small monthly minimum. As configured above, Ledgerly is
about as cheap as a hosted app gets:

| Item | Config | Rough monthly |
|---|---|---|
| 1 × `shared-cpu-1x` 512 MB | stopped when idle (`auto_stop_machines`) | a few dollars, less if it idles |
| 1 GB volume | always billed, even when the machine is stopped | ~$0.15/GB |
| Bandwidth | negligible for one freelancer's invoices | ~0 |

**The first thing that will exceed it** is not traffic — one user's invoices will
never move the needle. It is **`min_machines_running = 1`**, which stops the
machine from idling and bills it around the clock. That is the knob to check
first if a bill surprises you.

**Watch:** `fly machine list` (how many are running — should be exactly 1 or 0)
and volume size. Set a spending limit in the Fly dashboard on day one.

---

## If you outgrow SQLite — the honest version

ADR-001 promises the Postgres move is cheap, and for **application code** that
is true and was designed for: swap the adapter in `src/server/db.ts`, change
`provider` in `prisma/schema.prisma`. No service, route or schema *shape*
changes — no raw SQL, cuid2 ids, integer money, DB-backed sessions.

What ADR-001 does not cost out, and what you will actually spend a day on:

- **The migration history is not portable.** `prisma/migrations/migration_lock.toml`
  pins `provider = "sqlite"`, and the SQL inside is SQLite-specific — the BigInt
  migration is a `PRAGMA defer_foreign_keys` table-redefine-and-copy that no
  Postgres will run. You delete `prisma/migrations/` and generate one fresh
  baseline migration against Postgres.
- **The data has to be copied by a script you write.** There is no `pg_restore`
  path from a SQLite file. It is a read-all/write-all script through Prisma —
  small at this data size, but it is work, and it must preserve every cuid2 id
  because they are the foreign keys.
- **The deploy topology changes, mostly for the better.** `DATABASE_URL` becomes
  a real credential (`fly secrets set`, not `[env]`), the volume and the
  one-machine constraint both go away, and migrations move to a proper Fly
  `release_command` — the thing that is wrong today becomes right.
- **`docker-entrypoint.sh` gets simpler**: boot-time migration exists only
  because of the volume. Delete it with the volume.
- **Type changes to check:** BigInt columns become `bigint` and Prisma returns
  them as JS `BigInt` on Postgres in some paths where SQLite returned numbers.
  Q-005 (JSON precision above `Number.MAX_SAFE_INTEGER`) is still open and
  becomes more visible, not less.

Budget a day, not an hour. Nothing here is a blocker — the ADR's guardrails did
their job — but "swap the adapter" is the last step, not the whole list.

---

## Security findings addressed here

Two findings from `.oma/06-devops/security-review.md` were config, so they were
closed in `next.config.ts` (configuration — no application logic was touched):

- **SEC-003** (medium, no security headers) — `X-Frame-Options: DENY`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`,
  and HSTS in production only. ✅ verified live against the container.
  **Partially closed on purpose:** the CSP ships as
  `Content-Security-Policy-Report-Only`, exactly the "measure first, enforce
  second" order the review asked for. Enforcing `default-src 'self'` today would
  white-screen the app — Next's inline hydration bootstrap violates it on every
  page. Closing it fully needs a nonce in `src/proxy.ts`, which is application
  territory, not mine. The clickjacking case the review called "reachable today"
  *is* blocked now, by the enforced `X-Frame-Options`.
- **SEC-009** (low, `X-Powered-By`) — `poweredByHeader: false`. ✅ verified: 0
  occurrences on a live response.

Not mine and still open: SEC-001, SEC-002, SEC-004..SEC-008. **SEC-008** (no
request body size cap) was suggested as possibly-mine "at the reverse proxy" —
on Fly there is no body-size knob without adding a proxy in front, so the honest
fix is the `Content-Length` check in `src/server/http.ts`. That is Backend's.

---

## CI

`.github/workflows/ci.yml` runs on push and pull request, on Node 24.18.0
(pinned to the version this was proven on), in three jobs:

- **verify** — `npm ci` → `db:generate` → `typecheck` → `lint` → `format:check` →
  `test` → `build`. ✅ every step run locally this session, all exit 0.
- **e2e** — migrate, build, Playwright chromium. ✅ run locally, 11/11, exit 0.
- **container** — `docker build` then boot the image and hit `/api/health`.
  ✅ run locally, exit 0, healthy.

It does **not** deploy, and it pushes no image anywhere. Deployment stays a
command you run deliberately, from this file, with your credentials.
