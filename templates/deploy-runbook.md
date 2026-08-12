<!-- Written by oma-devops. Lives at .oma/06-devops/deploy-runbook.md
     Written for a tired person at 2am. Every command copy-pasteable, every
     expected result stated. OMA never runs any of these — the user does. -->

# Deploy runbook — <project>

**Platform:** <platform> · **Database:** <db> · **Region:** <region>
**Chosen because:** <one line — why this platform for this stack>

> Nothing in this file has been run against a live environment. OMA writes the
> runbook; you run it, with your credentials. Steps verified locally are marked
> ✅ verified; everything else is marked ⚠️ unverified.

## Prerequisites

| Need | Version | Install / get it |
|---|---|---|
| <CLI> | <ver> | `<command>` |
| <account> | — | <url> |

## Environment variables

Every variable the application reads. Full descriptions in
`.oma/06-devops/env.template`.

| Variable | Required | Where the value comes from |
|---|---|---|
| `DATABASE_URL` | yes | provisioned in step 2 |
| ... | | |

Set them with:

```bash
<the platform's env-setting command, one line per variable>
```

## First deploy

1. **<Step>**
   ```bash
   <command>
   ```
   Expect: `<the actual output that means success>`

2. **Provision the database**
   ```bash
   <command>
   ```
   Expect: a connection string. Set it as `DATABASE_URL` and never commit it.

3. **Run migrations** — see the migrations section below. Migrations run as a
   *release step*, never during the image build.

4. **Deploy**
   ```bash
   <command>
   ```
   Expect: a URL. First boot takes `<n>` seconds.

## Migrations

```bash
<the production migration command>
```

- Runs as a release/predeploy step, not in the build. A build runs on every
  push; a migration must run once, in order, against the real database.
- **Before any destructive migration** (dropped column, changed type, removed
  table), take a backup: `<backup command>`. A migration that loses data cannot
  be rolled back by redeploying.
- Migration failures leave a lock: `<how to clear it for this stack>`.

## Verify the deploy worked

```bash
curl -i https://<url>/<health endpoint>
```

Expect: `200` and `<body>`. Then check in the app itself: `<the one user flow
that proves the database is really connected>`.

Logs: `<command>` — the line that proves a clean boot is `<line>`.

## Rollback

```bash
<the exact rollback command>
```

Rollback restores the previous **code**. It does not undo an applied migration.
If the bad release included a migration, the recovery is `<the specific path
for this stack>` — decide before you need it.

Verified: <✅ / ⚠️ — say plainly whether this rollback path was tested>.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Build passes locally, fails in CI | <cause> | <fix> |
| Boots then crashes immediately | missing env var — check the runtime logs for the variable name | set it, redeploy |
| 500 on every database call | `DATABASE_URL` unset, wrong, or missing SSL params | <fix> |
| Migration hangs | advisory lock held by a failed run | <fix> |
| Cold start times out | <cause> | <fix> |

## Cost

Free tier: `<what's included>`. First thing to exceed it: `<what, and roughly
when>`. Next tier: `<price>`. Watch `<the specific metric>`.

## CI

`<workflow path>` runs on push and pull request: install → typecheck → lint →
build → test, on `<runtime version>`. It does **not** deploy — deployment stays
a command you run deliberately.
