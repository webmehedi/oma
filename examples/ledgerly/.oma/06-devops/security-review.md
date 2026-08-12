<!-- Written by oma-security. One file per review round: .oma/06-devops/security-review.md -->

# Security review — Ledgerly — round 1

Reviewed 2026-08-12 (UTC) against commit `14c82fe`. Application probed at
`http://localhost:3411` (`next dev`, started by me against an isolated
`file:./data/sec-probe.db` so the working database was never touched; server
stopped and probe database deleted at the end of the review). Scope: this
repository only. No host I did not start was contacted.

## Verdict

**Yes, with three hardening items — the thing that would have blocked shipping
is not there.** The one failure class that actually loses a freelancer's data
in an app like this is broken tenant isolation, and Ledgerly does not have it:
every one of the eleven cross-user operations I ran as user B against user A's
invoice and client ids returned `404 NOT_FOUND`, A's invoice was byte-identical
afterwards, and B's list/dashboard endpoints returned only B's own (empty) data.
That is enforced in the data layer, not in the route handlers — every Prisma
call in `src/server/services/` carries `userId` in its `where` — which is why it
holds for the paths nobody wrote a test for as well. Mass assignment is closed
(injected `userId`, `id`, `status`, `number`, `totalCents` were all ignored and
server values used), no secret is committed anywhere in the tree or the 13-commit
history, `npm audit` is genuinely zero, and there is no `dangerouslySetInnerHTML`,
`innerHTML`, `eval`, or `$queryRaw` in the codebase at all. What is missing is
the outer layer: the auth endpoints have no rate limit of any kind, sign-in
answers "does this email exist?" in its response time, and the app serves zero
security headers. None of those hands an attacker another user's data on its
own; all three are worth closing before this is on the public internet, and the
first two get materially worse together.

| Severity | Count | Ship-blocking |
|---|---|---|
| critical | 0 | yes |
| high | 0 | yes |
| medium | 3 | no |
| low | 6 | no |

Dependency audit: `npm audit --json` → **0 critical, 0 high, 0 moderate, 0 low**
across 685 dependencies (204 prod, 425 dev, 132 optional). Nothing to triage —
there is no vulnerable path to weigh, reachable or otherwise.

No `critical` or `high` findings, so **no tasks were filed** and
`.oma/04-build/tasks.json` is unchanged (`next_id` remains 29). The three
mediums and six lows below surface at the gate for the user to decide on; I did
not inflate any of them to force a fix round.

## Findings

### SEC-001 · medium · Auth endpoints have no rate limit, throttle, or lockout

- **Where:** `src/app/api/auth/signin/route.ts:14-21`, `src/server/services/auth.ts:94-120`
  (and `signup` at `:66-91` — same absence)
- **What an attacker does:** Points a loop at `POST /api/auth/signin` for a known
  email. Nothing slows it down: no per-IP limit, no per-account counter, no
  backoff, no captcha, no lockout. The same absence on `POST /api/auth/signup`
  lets one caller create unlimited accounts, each of which costs the server an
  argon2id hash (m=19456 KiB) — a cheap way to exhaust memory and CPU.
- **What they get:** Unbounded online password guessing against any account whose
  email they know — and SEC-002 tells them which emails those are. Ledgerly's
  password policy is a length check only (SEC-008), so a dictionary of common
  8-character passwords is a realistic attack, not a theoretical one. Success
  means full access to that freelancer's clients, invoices and revenue figures.
- **Evidence:**
  ```
  $ # 30 consecutive wrong-password sign-ins for one existing account
  codes: 400 400 400 400 400 400 400 400 400 401 401 401 401 401 401 401 401 401
         401 401 401 401 401 401 401 401 401 401 401 401
  elapsed 0.97s for 30 attempts
  # (the nine 400s are my own too-short guesses failing Zod, not a defence)

  $ # 31st attempt, correct password — the account was never locked
  status=200
  ```
  21 full-speed credential attempts in under a second, no degradation, and the
  account still signs in normally afterwards.
- **Fix:** Add a fixed-window or token-bucket limiter in front of
  `/api/auth/signin` and `/api/auth/signup` — keyed on client IP *and* on the
  submitted email, since either key alone is trivially evaded. For a
  single-process SQLite deployment an in-memory bucket in `src/proxy.ts` or a
  small `Session`-style counter table is sufficient; the numbers to aim for are
  ~5 failures per email per 15 minutes and ~20 sign-in attempts per IP per
  minute, returning the contract's existing `INVALID_CREDENTIALS` rather than a
  new error code so the frozen contract is untouched. Note this needs a
  contract decision if you want a distinct 429 — as written, the registry has no
  code for "too many requests".
- **Filed as:** not filed (medium — recorded here for the gate)

### SEC-002 · medium · Sign-in response time discloses whether an email is registered

- **Where:** `src/server/services/auth.ts:98-101`
- **What an attacker does:** Sends one `POST /api/auth/signin` per candidate
  email with any password and reads the wall-clock response time. The handler
  looks the user up first and returns `INVALID_CREDENTIALS` immediately when the
  row is absent (`:101`), reaching the argon2id verify at `:105` only when the
  email exists. The status code and body are identical either way, so the
  contract's stated defence holds — but the clock does not.
- **What they get:** A reliable registered-email oracle at roughly 300
  requests/second (SEC-001 removes the only brake). This directly defeats what
  the frozen contract promises at `api-contract.yaml:118` — *"same code for both
  — no account enumeration"* — and it is the reconnaissance step that makes
  SEC-001 targeted rather than blind. For an invoicing app the membership fact
  itself is also a small privacy leak: it confirms someone freelances.
- **Evidence:**
  ```
  $ # 10 unknown emails vs 10 wrong passwords on a known email, same endpoint
  UNKNOWN_EMAIL     0.003857 0.003851 0.004251 0.004971 0.008941
                    0.003795 0.003495 0.003332 0.003799 0.003346
  KNOWN_EMAIL_BADPW 0.019919 0.020901 0.019020 0.019665 0.018876
                    0.019399 0.019165 0.019268 0.020733 0.019080
  ```
  Two non-overlapping bands ~3.3–8.9 ms vs ~18.9–20.9 ms: a single request
  classifies any address with no error margin to speak of.
- **Fix:** Make both paths do the same work. Compute a module-level dummy
  argon2id hash once at startup (same parameters as real hashes) and, when
  `findUnique` returns `null`, run `argon2Verify(DUMMY_HASH, password)` and
  discard the result before returning `INVALID_CREDENTIALS`. Four lines in
  `signin`, no contract change, and it closes the gap the contract already
  claims is closed.
- **Filed as:** not filed (medium — recorded here for the gate)

### SEC-003 · medium · No security response headers on any route

- **Where:** `next.config.ts:1-9` (no `headers()` entry; Next sets none of these
  by default)
- **What an attacker does:** Frames `/invoices/{id}` in a hidden iframe on a page
  the victim visits and overlays it — the send-ready view's mark-paid control is
  a one-click state change, which is exactly the shape clickjacking targets.
  Separately, any future injected script runs unrestricted (no CSP), any
  content-type confusion is exploitable (no `X-Content-Type-Options`), full
  invoice URLs leak to third-party sites via `Referer` (no `Referrer-Policy`),
  and a first request over `http://` is downgradeable (no HSTS).
- **What they get:** No single header's absence discloses data by itself; together
  they remove every layer that would contain a mistake made later. The frame
  case is the one reachable today without another bug.
- **Evidence:**
  ```
  $ curl -sD - -o /dev/null http://localhost:3411/signin
  HTTP/1.1 200 OK
  Vary: rsc, next-router-state-tree, ...
  Cache-Control: no-cache, must-revalidate
  X-Powered-By: Next.js
  Content-Type: text/html; charset=utf-8

  content-security-policy: 0
  strict-transport-security: 0
  x-content-type-options: 0
  x-frame-options: 0
  referrer-policy: 0
  permissions-policy: 0
  ```
- **Fix:** `oma-devops` territory, not application code. Add a `headers()` block
  to `next.config.ts` covering `/(.*)`: `X-Frame-Options: DENY` (or
  `frame-ancestors 'none'`), `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`,
  `Strict-Transport-Security: max-age=63072000; includeSubDomains` (production
  only), `Permissions-Policy: camera=(), microphone=(), geolocation=()`, and a
  CSP. The CSP needs care with Next's inline bootstrap and framer-motion's
  injected styles — start with `default-src 'self'; object-src 'none';
  base-uri 'self'; frame-ancestors 'none'` in report-only, confirm the invoice
  detail and form screens report nothing, then enforce.
- **Filed as:** not filed (medium — recorded here for the gate)

### SEC-004 · low · CSRF protection rests entirely on `SameSite=Lax`

- **Where:** `src/server/auth.ts:20-25`; no origin check in `src/server/http.ts`
- **What an attacker does:** Nothing that works in a current browser — and that
  is the whole point of the rating. Every state-changing route is POST/PATCH/DELETE
  and `SameSite=Lax` stops the browser attaching `ledgerly_session` to a
  cross-site request of those methods, so the control genuinely holds today.
  There is simply no second layer: the server never inspects `Origin`, there is
  no CSRF token, and `parseJson` does not require a JSON content-type.
- **What they get:** Nothing now. The exposure is that a single future change —
  loosening the cookie to `SameSite=None` for an embed, or adding a
  state-changing GET — silently removes the only defence with nothing behind it.
- **Evidence:**
  ```
  $ curl -H 'Origin: https://evil.example' -b cookiejar -X POST \
      http://localhost:3411/api/clients -d '{"name":"csrf-probe"}'
  status=201 {"data":{"id":"tfczhq8...","name":"csrf-probe",...}}
  ```
  The 201 is *not* a browser-reachable exploit — curl ignores `SameSite`, which
  is precisely the protection under test. It does show the server itself applies
  no origin check whatsoever.
- **Fix:** Reject state-changing requests whose `Origin` header is present and
  not same-origin, in `respond()` or `src/proxy.ts` — about six lines, and it
  makes the cookie flag a second layer rather than the only one.
- **Filed as:** not filed (low)

### SEC-005 · low · Sessions are never revocable and expired rows accumulate

- **Where:** `src/server/services/auth.ts:127-164`
- **What an attacker does:** Having stolen a session token (via a shared machine,
  a backup, or a future XSS), keeps using it. Sign-out deletes only the row for
  the token presented (`:128-130`), so the victim signing out elsewhere does not
  evict it, and there is no "sign out everywhere". The token stays valid for 30
  days and slides forward on every use.
- **What they get:** Persistence. Also an unbounded `Session` table: expired rows
  are swept only when that exact token is presented again (`:149-152`), so rows
  from sessions nobody returns to are never collected — 16 rows for one test
  account after a handful of sign-ins, and the working dev database carries 84.
- **Evidence:**
  ```
  $ # 10 sign-ins as one user, then count
  session rows: 16   expired-but-present: 0
  $ # working dev database
  users: 98  sessions: 84  invoices: 41
  ```
- **Fix:** Add a periodic `deleteMany({ where: { expiresAt: { lt: now } } })`
  sweep (a boot-time call plus a daily interval is enough at this scale), and
  when a password-change feature lands, delete all of that user's sessions with
  it.
- **Filed as:** not filed (low)

### SEC-006 · low · Signup discloses whether an email is already registered

- **Where:** `api-contract.yaml:83-89` (the `EMAIL_TAKEN` 409), implemented at
  `src/server/services/auth.ts:88`
- **What an attacker does:** Posts a candidate email to `/api/auth/signup` with
  any password and reads the status: 409 means registered, 201 means not.
- **What they get:** The same registered-email oracle as SEC-002, by a second
  route — so fixing SEC-002 alone does not close enumeration. Unlike SEC-002
  this one is **the frozen contract's own design**, not an implementation slip:
  `EMAIL_TAKEN` is in the error registry and the signup response table. I am
  flagging it rather than filing it, because closing it properly means changing
  a frozen contract (signup would have to always return 201 and send a "this
  address is already registered" email instead) and Ledgerly v1 has no outbound
  email to do that with — the PRD defers it. **This is a `contract_changes`
  candidate for v1.1, not something Backend can fix inside the contract.**
- **Evidence:**
  ```
  $ curl -X POST /api/auth/signup -d '{"email":"<existing>","password":"..."}'
  409 {"error":{"code":"EMAIL_TAKEN","message":"An account with this email already exists."}}
  ```
- **Fix:** Accept for v1 (documented risk), or raise a contract change for v1.1
  once email sending exists.
- **Filed as:** not filed (low, contract-level)

### SEC-007 · low · Password policy is a length check only

- **Where:** `src/shared/schemas/auth.ts:17-20`
- **What an attacker does:** Guesses `password123`, `letmein1`, `qwerty12` — all
  of which Ledgerly accepts at signup and none of which any check rejects.
- **What they get:** With SEC-001 (no rate limit) and SEC-002 (a list of valid
  emails), a small dictionary is a viable path into real accounts.
- **Evidence:** `password: z.string().min(8).max(200)` is the entire policy; no
  common-password list, no breach check, no zxcvbn-style strength gate. Storage
  itself is correct — argon2id `$v=19$m=19456,t=2,p=1`, read from a real row.
- **Fix:** Reject a bundled top-10k common-password list at signup (a ~90 KB
  static file, no network dependency). The `VALIDATION_FAILED` envelope already
  carries the field message, so the contract is untouched.
- **Filed as:** not filed (low)

### SEC-008 · low · No request body size cap

- **Where:** `src/server/http.ts:110-123` (`request.json()` with no length check)
- **What an attacker does:** POSTs a very large JSON body to any authenticated
  endpoint. The whole body is buffered and parsed before Zod ever sees it.
- **What they get:** Memory and CPU per request, cheaply, in a single-process
  Node server with a synchronous single-writer SQLite behind it. Requires a
  valid session, so it is an authenticated nuisance, not an open door.
- **Evidence:**
  ```
  $ curl -X POST /api/clients --data-binary @8MB.json
  status=400 time=0.028421
  {"error":{"code":"VALIDATION_FAILED",...,"details":{"name":"Name must be at most 200 characters."}}}
  ```
  8 MB accepted, parsed, and only then rejected on a 200-character field limit —
  a 413 never happened because nothing checks length.
- **Fix:** Check `Content-Length` in `parseJson` and reject above ~256 KB (the
  contract's own maxima put a legitimate 100-line invoice far below that), or
  set the equivalent limit at the reverse proxy — `oma-devops` can do it either
  way.
- **Filed as:** not filed (low)

### SEC-009 · low · `X-Powered-By: Next.js` advertises the framework

- **Where:** Next's default; disabled with `poweredByHeader: false` in
  `next.config.ts`
- **What an attacker does:** Reads one response header and knows which
  framework-specific CVEs to try first.
- **What they get:** Reconnaissance only.
- **Evidence:** `X-Powered-By: Next.js` present on every page response (see
  SEC-003's header dump).
- **Fix:** `poweredByHeader: false` — one line, same `next.config.ts` change as
  SEC-003, so do them together.
- **Filed as:** not filed (low)

## Checked and clean

| Area | How it was checked | Result |
|---|---|---|
| **Cross-user authorization (the one that matters)** | Two real users created through the API; B ran GET/PATCH/DELETE on A's invoice, POST on A's status route, GET/PATCH/DELETE on A's client, and POST /invoices carrying A's `clientId` | **11/11 → 404 `NOT_FOUND`**, identical to a nonexistent id; A's invoice re-fetched byte-identical afterwards |
| Tenant scoping in the data layer | Read every Prisma call in `src/server/services/{invoices,clients,dashboard,auth}.ts` | Every user-owned query carries `userId` in `where`; `findFirst({id, userId})` before every mutation; `InvoiceLineItem` is only ever reached through an ownership-checked invoice |
| List/aggregate endpoints leaking across accounts | B called `/clients`, `/invoices`, `/dashboard` while A held data | B's own client only; `data: []` with `total: 0`; dashboard all zeros |
| Unauthenticated access to every protected path | No cookie against `/auth/me`, `/clients`, `/invoices`, `/dashboard`, both `{id}` routes, and a PATCH | 7/7 → `401 UNAUTHENTICATED`, never a 400 — auth runs before validation everywhere |
| Forged / garbage session token | `Cookie: ledgerly_session=not-a-real-token` on `/auth/me` | 401; token is looked up by SHA-256, so an unknown value is simply absent |
| Mass assignment | Injected `id`, `userId`, `isAdmin`, `passwordHash`, `nextInvoiceNumber` at signup; `userId`/`id`/`invoiceCount` at client create; `number`/`status`/`totalCents`/`userId`/`amountCents` at invoice create | All ignored — Zod objects strip unknown keys and services name every column explicitly; returned invoice had server `number: 1`, `status: "unpaid"`, `totalCents` recomputed as 100 (not the 1 sent) |
| Session token generation and storage | Read `src/server/services/auth.ts:47-54`; inspected a live `Set-Cookie` and the `Session` table | 256-bit `randomBytes`, base64url; only the SHA-256 is persisted; raw token never stored or logged |
| Session cookie flags | `Set-Cookie` on signup/signin/signout | `Path=/; Max-Age=2592000; HttpOnly; SameSite=lax`; `secure: isProduction` (`src/server/auth.ts:23`) so `Secure` is set under `next start`, correctly absent over dev http |
| Session rotation and sign-out | Signed in twice (token1 ≠ token2), signed out with token1 | New token per sign-in (no fixation); token1 → 401 immediately after its own sign-out; token2 unaffected; sign-out sets `Max-Age=0` with matching flags |
| Password storage | Read the hash from a real user row | argon2id, `$v=19$m=19456,t=2,p=1` — matches `stack.md` and meets current OWASP minimums |
| Sign-in failure codes | Unknown email vs wrong password | Both `401 INVALID_CREDENTIALS`, identical body — status/body enumeration is closed (the *timing* is SEC-002) |
| Secrets in the working tree | `git ls-files` for env/key/pem/credential names; scanned tracked files | Only `.env.example`, which contains one non-secret SQLite path; `.env` is gitignored and holds the same path |
| Secrets in git history | `git log -p --all` across all 13 commits grepped for key/token/secret/PEM/AWS/GitHub/OpenAI patterns | No secret-shaped string; every hit was prose in `.oma/` docs or the word "token" in session design notes |
| Client-bundle exposure | Grepped `.next/static` for `passwordHash`, `tokenHash`, `DATABASE_URL`, `argon2`; grepped the repo for `NEXT_PUBLIC_*` | Nothing; the app defines no `NEXT_PUBLIC_` variable at all |
| SQL injection | Grepped for `$queryRaw`/`$executeRaw`; read the adapter setup | Zero raw SQL anywhere — Prisma Client API only, as ADR-001 requires |
| XSS | Grepped all of `src/` for `dangerouslySetInnerHTML`, `innerHTML`, `eval`, `new Function`; stored `<script>alert(1)</script><img src=x onerror=alert(2)>` as a client name, address and line-item description, then fetched the invoice detail page | Zero occurrences of any raw-HTML sink in the codebase; payload round-tripped through the API and rendered only through React text interpolation — 0 raw and 0 `alert` occurrences in the served HTML |
| Input validation at every trust boundary | Read all 11 route handlers against the contract | Every one validates with the stack's Zod schema before touching a service; auth guard runs first; `parseJson`/`parseQuery` are the only entry points |
| Malformed / hostile input | Malformed JSON, top-level array, form-encoded body, `page=0`, `page=-5`, `page=99999999999999999999`, `status=overdue`, a 100k-character name, 101 line items | 11/11 → `400 VALIDATION_FAILED` with authored field messages; no stack trace, no 500 |
| Path traversal / null bytes in ids | `GET /api/invoices/..%2f..%2fetc%2fpasswd`, `GET /api/clients/%00` | 404 `NOT_FOUND` — ids are only ever database lookup keys; no filesystem path is built from user input anywhere |
| SSRF | Grepped `src/server` and `src/app` for outbound `fetch` | None — the server makes no outbound requests at all |
| Open redirect | Read every `redirect`/`router.push`/`NextResponse.redirect` site | All five targets are hardcoded literals or a server-issued invoice id; no user-controlled redirect target |
| Error handling / information disclosure | Forced validation and not-found failures across the API; read `src/server/http.ts:72-83`, `app/error.tsx`, `app/global-error.tsx` | Unknown throwables become a generic `INTERNAL`; the detail stays in the server log; the client boundary logs only `error.digest` |
| Signed-out page gating | `/dashboard`, `/clients`, `/invoices`, `/invoices/new` with no cookie, then with a forged cookie | 307 → `/signin` without a cookie; with a forged cookie the shell renders (proxy is a documented presence-only check, `src/proxy.ts:15`) but contains no user data — the API returns 401 and the screen redirects |
| CORS | `Origin: https://evil.example` on a GET and an OPTIONS preflight | No `Access-Control-Allow-Origin` on any response — cross-origin *reads* are blocked by the browser's same-origin policy with nothing opening it up |
| Dependencies | `npm audit --json`, this session | 0 vulnerabilities across 685 packages; no triage needed |

## Not checked

- **Deployment and infrastructure.** No Dockerfile, CI workflow, or reverse-proxy
  config exists yet — `oma-devops` writes those after this review. TLS
  termination, the container's user, secret injection, network exposure and
  backups are all their surface, not reviewable here.
- **Production runtime configuration.** I probed `next dev`. `Secure` on the
  session cookie, HSTS, and the production error digest path are correct by code
  reading but were not exercised against a `next start` behind TLS.
- **The `data/ledgerly.db` file's confidentiality at rest.** SQLite is unencrypted
  by design; whether the volume it lands on is encrypted is a deployment answer.
- **Denial of service beyond the two probes above.** No load testing, no
  concurrency testing against better-sqlite3's single-writer model.
- **Third-party and supply-chain integrity beyond `npm audit`.** No lockfile
  provenance check, no dependency-confusion analysis, no review of the five
  packages allowed to run install scripts in `package.json`'s `allowScripts`.
- **Anything requiring credentials or hosts this environment does not have.** No
  external service, no staging URL, no production system was contacted — by rule
  and in fact.
- **Physical and social attack surface**, and the browser extension / shared
  machine threat model.

## Recommendations beyond the findings

- **Purge the working dev database before it becomes a habit.**
  `data/ledgerly.db` currently holds 98 accounts, 84 sessions and 41 invoices
  left over from QA runs, all with the same known password
  (`correct-horse-battery`, hardcoded in `e2e/helpers.ts:3`). It is gitignored
  and never shipped, so this is not a finding — but the moment someone copies a
  dev volume to a demo box, those become 98 working logins. Have QA reset it, or
  point the e2e harness at its own file the way I did for this review.
- **Give the invoice detail route a deliberate caching answer.** It is the one
  page a freelancer might share a link to, and it currently renders a
  client-fetched document with no `Cache-Control` of its own. Decide explicitly
  whether an intermediary may ever store it — for an invoice with a client's
  address on it, the answer is no.
- **Add an audit trail for status changes.** `paid`/`unpaid` is the only field in
  this app with money attached, and it flips on one click from two different
  screens with no record of who flipped it or when (only the resulting
  `paidAt`). A tiny append-only log would pay for itself the first time a
  freelancer disputes what a client saw — this is the specific place Ledgerly's
  data model would otherwise lose history.
- **Wrap `updateClient` and `deleteClient` in a transaction** the way the invoice
  service already does. Both check ownership and then mutate by id in two
  separate statements (`src/server/services/clients.ts:88-109`, `:121-129`). It
  is not exploitable today — nothing in this data model transfers ownership of a
  row — but the invoice service's pattern is the better one and the asymmetry is
  a trap for whoever adds client sharing later.
- **When rate limiting lands (SEC-001), raise the contract question with it.**
  The frozen error registry has no code for "too many requests"; returning
  `INVALID_CREDENTIALS` for a throttled request is contract-legal but tells the
  user something untrue. A `RATE_LIMITED`/429 addition is the honest version and
  needs `/oma:change`.
