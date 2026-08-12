<!-- Written by oma-seo, phase 07-growth. Everything below describes code that
     is in the repository and was fetched from a running server, or is labelled
     as a recommendation. No traffic estimate, search volume or difficulty score
     appears anywhere in this file, because none was measured. -->

# SEO brief — Ledgerly

## The honest headline

**Ledgerly has two indexable pages.** `/signup` and `/signin`. That is the
entire public surface, and it is a fact about the product, not an oversight:
every screen that carries content — dashboard, invoice list, invoice document,
client list — sits behind `src/proxy.ts`, which redirects a cookie-less request
to `/signin` before any HTML is produced. A crawler is a cookie-less request.

So the metadata work below is small and finished, and the leverage is not in
metadata at all. It is in the fact that **`/` currently 307s to `/dashboard`**
and there is no public page describing the product. `oma-marketer` has written
the copy for that page (`landing-copy.md`); nobody has built the route. That is
the single change that would matter more than everything in this brief combined.

Marking up private routes would have been the wrong move, so I didn't. All seven
authenticated routes carry an explicit `noindex, nofollow, nocache`.

---

## What shipped

| File | What it does |
|---|---|
| `src/app/site.ts` | Single source of truth: origin, brand strings, the public-route list, the private-prefix list, the OG defaults, the private-route robots directive. `robots.ts` and `sitemap.ts` both read it, so they cannot disagree. |
| `src/app/robots.ts` | `/robots.txt` — allow all, disallow the four private prefixes, point at the sitemap. |
| `src/app/sitemap.ts` | `/sitemap.xml` — the two public routes, filtered against the private prefixes so a mistake in `site.ts` drops the URL rather than publishing a contradiction. |
| `src/app/opengraph-image.tsx` | Generated 1200×630 PNG card in the brand palette. Verified served as a real PNG, not a 404. |
| `src/app/structured-data.tsx` | The JSON-LD graph rendered on both public routes. |
| `src/app/layout.tsx` | `metadataBase`, title template, description, OG/Twitter defaults, `formatDetection`. |
| `src/app/signin/page.tsx`, `src/app/signup/page.tsx` | Per-route title, description, canonical, OG, Twitter, JSON-LD. |
| `src/app/{dashboard,clients,invoices,invoices/new,invoices/[id],invoices/[id]/edit}/page.tsx` | Titles moved onto the template; `robots: PRIVATE_ROUTE_ROBOTS` added. |
| `src/app/signin/auth-screen.tsx` | The brand wordmark is now the page `<h1>` (both public routes had zero headings), and the decorative `●` glyph is `aria-hidden`. |

Nothing else was touched. No analytics script, no tag manager, no tracking
pixel — that is a consent and privacy decision for the user to make, and it is
recommended, not installed. `next.config.ts` and its
`Content-Security-Policy-Report-Only` were not modified; the JSON-LD block is
`type="application/ld+json"`, which the browser never executes and `script-src`
therefore never governs.

---

## Page inventory

Every route in `src/app`, checked against the router directory rather than
assumed. Titles are shown as rendered (the root template appends `— Ledgerly`).

### Public — indexed

| Route | Primary term | Intent | `<title>` (rendered) | Description |
|---|---|---|---|---|
| `/signup` | simple invoicing app for solo freelancers | Transactional — has decided, wants an account | `Create your freelance invoicing account — Ledgerly` (50 ch) | "Create a Ledgerly account and start invoicing in minutes: keep a client list, build line-item invoices, mark them paid, and see exactly what you are still owed." (160 ch) |
| `/signin` | ledgerly login / ledgerly sign in | Navigational — already a user, or bounced here by the proxy | `Sign in — Ledgerly` (18 ch) | "Sign in to Ledgerly to check what is outstanding, mark an invoice paid, or write a new one. Invoicing for solo freelancers and nothing else in the way." (151 ch) |

Site default, inherited by anything without its own block:
`Ledgerly — Simple invoicing for solo freelancers` (48 ch) /
"Ledgerly is a tiny invoicing app for solo freelancers: keep a client list,
build line-item invoices, mark them paid, and see what you are still owed."
(149 ch).

### Deliberately `noindex`

Each of these is behind the session cookie, unreachable to a crawler already,
and carries `noindex, nofollow, nocache` as a second, explicit statement.

| Route | Rendered title | Why noindex, specifically |
|---|---|---|
| `/dashboard` | `Dashboard — Ledgerly` | One freelancer's outstanding balance. |
| `/clients` | `Clients — Ledgerly` | A private list of named third parties. |
| `/invoices` | `Invoices — Ledgerly` | Same, plus amounts. |
| `/invoices/new` | `New invoice — Ledgerly` | Empty form; nothing to index even in principle. |
| `/invoices/[id]` | `Invoice — Ledgerly` (refined client-side to `INV-0001 — Ledgerly`) | A named client, a due date, an amount owed. Indexing this would be a data leak, not a ranking decision. |
| `/invoices/[id]/edit` | `Edit invoice — Ledgerly` | Form state. |
| `/clients/[id]` | — | Always `notFound()`; v1 has no client detail screen. |

### Neither — no metadata to give

| Route | Status | Note |
|---|---|---|
| `/` | 307 → `/dashboard` → 307 → `/signin` | Excluded from the sitemap on purpose: a sitemap must not list a URL that answers with a redirect. **This should become the landing page** — see Content gaps. |
| `/_not-found`, `/clients/[id]/not-found` | 404 | Next emits its own `noindex` on the 404 boundary. I removed the duplicate directive I had first added — two `<meta name="robots">` tags on one page is sloppy, and the one Next writes is sufficient for a response that is already a 404. |
| `/api/*` (11 routes) | JSON | `Disallow: /api/` in robots.txt. Not a security control — the 401 is. |

---

## Structured data

One `@graph` on `/signin` and `/signup`, three nodes:

- **`WebSite`** — true of every page here.
- **`SoftwareApplication`** — `applicationCategory: BusinessApplication`,
  `operatingSystem: Web browser`, and a `featureList` of six entries, each one
  a capability that actually shipped under REQ-002 … REQ-006.
- **`WebPage`** — page-specific, `isPartOf` the WebSite, `about` the app, so
  the two routes are not the same blob emitted twice.

**What is absent, and why it stays absent.** No `offers`: Ledgerly has no
pricing (PRD, *Out of scope (v1): Monetization*), and `price: 0` is a claim
nobody has made. No `aggregateRating` or `review`: there are no users and no
reviews, and inventing them is the specific kind of markup that earns a manual
action. No `Organization`: Ledgerly is a product name, not a company that
exists. If any of those three become true, the node goes in then.

Both blocks were fetched from a running server, parsed as JSON, and asserted
free of `offers`/`aggregateRating`/`review`/`priceRange`.

---

## Keyword set

**No volume or difficulty data was measured.** There is no keyword tool in this
environment and I will not invent numbers. The ordering below is reasoning from
`personas.md` and `positioning.md`, and should be re-checked against real data
before anyone spends money on it.

**Head term to actually own: `ledgerly`.** For an unfunded solo product the
brand is the only head term that is winnable, and `/signin` and `/signup` now
both target it cleanly.

**Long-tail terms the product can plausibly win** — each one is winnable
*because* it encodes a limitation that the incumbents cannot match, since
matching it would mean removing features:

1. **"simple invoicing app for solo freelancers"** — the positioning sentence
   almost verbatim. Targeted by `/signup`.
2. **"invoicing app without payment processing"** — someone who does *not* want
   a payments integration. Ledgerly is one of very few honest answers.
3. **"how to track unpaid invoices"** — informational, and the exact job
   REQ-005 + REQ-006 do. Needs a page that does not exist yet.
4. **"spreadsheet alternative for freelance invoicing"** — `positioning.md`
   names the spreadsheet as the true competitor. Needs the comparison page.
5. **"invoice tracker that doesn't email clients"** — the REQ-004 boundary
   (send-ready, not sending) stated as a search query.

**Terms deliberately skipped**, and not because they are hard — because winning
them would be bad:

| Skipped | Why |
|---|---|
| "invoicing software", "invoice generator", "invoice maker" | Dominated by funded incumbents and template farms with backlink profiles a solo product will not match. Real cost, no realistic return. |
| "free invoice template" | Enormous term, entirely served by template downloads. Ledgerly has no template download, so a ranking would be a bounce. |
| "send invoices online", "invoice payment links", "get paid online" | **These would be actively harmful.** Ledgerly explicitly does not send and does not process payments. Traffic on these terms arrives wanting the two things the product refuses to do. |
| "accounting software for freelancers", "tax invoice", "VAT invoice" | No tax lines, no discount lines, no accounting. Same intent mismatch. |
| Any competitor-name comparison ("X alternative") | `positioning.md` voice rule 3 forbids naming products without re-checking their current pricing that week. Ranking for a competitor's name is a maintenance commitment, not a page. |

The through-line: **intent match beats volume here.** Ledgerly's whole
positioning is a list of things it does not do, and every high-volume term in
this category promises at least one of them.

---

## Internal linking plan

The honest version is short, and it starts with a defect.

**Finding: there is not a single `<a>` element on either public page.** Fetched
and counted — zero anchors on `/signup`, zero on `/signin`. The Sign in ↔
Create account toggle is a pair of `<button>`s that swap component state and
call `history.replaceState`. A crawler that lands on `/signin` has no crawlable
path to `/signup`; the sitemap is currently the only way either page is
discoverable from the other. This is a real link-equity and discovery problem
and it is a five-line fix, but it is a component behaviour change, so it is
filed for `oma-frontend` rather than done here.

**Plan once the landing page exists** (it is the hub; everything else is a spoke):

| From | To | Why |
|---|---|---|
| `/` | `/signup` | Primary CTA. `landing-copy.md` §1 already has the button and a `[[TODO: sign-up URL]]` marker for it. |
| `/` | `/signin` | Secondary, header-right. Returning users. |
| `/signup` | `/signin` | Real anchor beside the toggle — fixes the finding above. |
| `/signin` | `/signup` | Same, reversed. |
| `/` | `/vs-spreadsheet`, `/how-to-track-unpaid-invoices` | The two content pages below, linked from the body, not stuffed in a footer. |
| Content pages | `/signup` | One CTA each. |

---

## Content gaps

Four pages that do not exist and should, each with the intent it serves.

1. **Public landing page at `/`** — *the one that matters.* Intent:
   evaluation ("is this the invoicing app I want?"). Today `/` redirects to a
   private route, so a visitor from any link, post, or search result lands on a
   login form with no explanation of what they are logging into. The copy is
   already written and claim-checked in `landing-copy.md`. This is a frontend
   task, not an SEO task: it needs a route, and building product routes is
   outside my boundary. **When it ships, add `/` to `PUBLIC_ROUTES` in
   `src/app/site.ts` and the sitemap picks it up automatically** — and it should
   take over the `SoftwareApplication` JSON-LD node, which currently lives on
   the auth pages for want of anywhere better.
2. **`/vs-spreadsheet`** — intent: "should I stop tracking invoices in a
   spreadsheet?" `positioning.md` names the spreadsheet as the true competitor
   and already contains the argument (drift, formulas, no notion of what an
   invoice is). Winnable because no incumbent bothers to write it honestly.
3. **`/how-to-track-unpaid-invoices`** — informational, top of funnel, and the
   only listed gap that targets a problem rather than a product. Should end on
   the outstanding-total screenshot.
4. **`/help`** — intent: branded support. There is a live dead end here: the
   auth screen tells the user "Reset isn't available yet — contact support to
   recover access" and names no way to contact anyone. `landing-copy.md` carries
   a `[[TODO: support email address]]` for the same reason. A page fixes both.

---

## Core Web Vitals

**Measured:** payload, from the real production build and from fetching the
running server. **Not measured:** LCP, INP and CLS — no Lighthouse or field
run was performed, so no numbers for those are claimed here.

`/signup`, the public entry page, ships:

| | Raw | Gzipped |
|---|---|---|
| HTML document | 14.1 KB | 3.3 KB |
| JavaScript (10 chunks) | **1016 KB** | **292 KB** |

That is roughly a megabyte of JavaScript for a page containing an email field,
a password field and a button.

**The named offender:** one chunk, 454.6 KB raw / 119.7 KB gzipped — 45% of the
total — and fingerprinting it shows it contains the **zod runtime**,
**framer-motion**, and **Ledgerly's entire schema barrel**, including invoice
symbols (`displayNumber`, `totalCents`) that the auth screen has no use for.

The cause is a one-line import. `src/app/signin/auth-screen.tsx` does:

```ts
import { credentialsInputSchema, zodIssuesToDetails, type User } from "@/shared";
```

`@/shared` re-exports `./schemas`, which re-exports `common`, `auth`, `clients`,
`invoices` and `dashboard`. Zod schemas are constructed at module top level, so
the bundler cannot drop the ones the page never touches — the whole contract
surface rides along to every signed-out visitor.

**Filed for `oma-frontend`, with the number:**

1. Import from `@/shared/schemas/auth` instead of the `@/shared` barrel on the
   auth screen. Expected saving: the invoice/client/dashboard schema graph.
   Worth measuring before and after rather than assuming.
2. `framer-motion` on the public entry page buys one card fade-in and one tab
   indicator slide (`motion-spec.md` `enter.default` / `move.default`). If the
   library is only on this page for those two, a CSS transition honouring
   `prefers-reduced-motion` gets the same result at zero library cost. **This
   touches the frozen motion spec's implementation, not its values** — the
   durations and easings stay exactly as specified; only the mechanism changes.
   Needs `oma-ux-designer` to agree before anyone does it.

Two things that are already right and should stay that way: `/signup`,
`/signin`, `/robots.txt`, `/sitemap.xml` and `/opengraph-image` are all
statically prerendered (`○` in the build output), so TTFB is a file read; and
the app loads no web fonts at all — `--font-sans` is the system stack, which
removes the most common LCP and CLS offender in this class of app before it
exists.

---

## Deployment requirement — read this before deploying

**`NEXT_PUBLIC_SITE_URL` must be set at *build* time, not just at runtime.**

`/robots.txt`, `/sitemap.xml` and every `<link rel="canonical">` are statically
prerendered, so the origin is baked into the build output. Setting the variable
only in the runtime environment silently ships a sitemap and a set of canonicals
pointing at `http://localhost:3000`. Proven both ways in this session: a build
with the variable unset serves `http://localhost:3000/signup` in the sitemap; a
build with `NEXT_PUBLIC_SITE_URL=https://ledgerly.app` serves
`https://ledgerly.app/signup`, from the same source.

For `oma-devops`: this needs to be a Docker **build arg** promoted to an `ENV`
in the builder stage, and an entry in `.oma/06-devops/env.template`. I did not
edit the Dockerfile or `env.template` — that is your territory, and this is the
question in my handoff.

The fallback is `http://localhost:3000`, so dev, the e2e suite and a fresh
clone all work with no configuration.

---

## Reconciliation with `landing-copy.md`

`oma-marketer` ran concurrently and left an explicit note in §7 of
`landing-copy.md`: if an SEO brief exists with different terms, the SEO brief
wins on the title tag and the description. Taking that up, with one concession
in the other direction — their tagline is better than mine was, and I changed
the code to theirs. `SITE_TAGLINE` is now **"Simple invoicing for solo
freelancers"**; *solo* carries the exclusion their positioning table spends
paragraphs establishing, and my original "Invoicing for freelancers" threw it
away.

For the landing page when it is built, §7 of `landing-copy.md` should be
replaced with the strings now in `src/app/site.ts`:

```
Title:       Ledgerly — Simple invoicing for solo freelancers
Description: Ledgerly is a tiny invoicing app for solo freelancers: keep a
             client list, build line-item invoices, mark them paid, and see
             what you are still owed.
```

Their §7 draft and these differ only in phrasing; no claim changed, and nothing
on that page became less true to fit a keyword.

---

## Recommended, not done

- **Analytics.** Ledgerly has no measurement of any kind, so nothing in this
  brief can be evaluated after the fact. That is a privacy and consent decision
  with real consequences and it is the user's to make — I will not install a
  tracking script on their behalf. If they want one, a cookieless,
  self-hosted-or-EU option is the one that fits a product whose whole pitch is
  restraint.
- **Search Console + Bing Webmaster verification.** Needs a real domain and the
  user's account. Once the domain exists, the sitemap URL to submit is
  `https://<domain>/sitemap.xml`.
- **`/signin` and `/signup` are a near-duplicate pair.** Same component, same
  DOM but for the active tab. Both are self-canonical with distinct titles and
  descriptions, which is the honest configuration; a cross-canonical would hide
  one of two genuinely different intents. If a search engine later folds them
  together, that is the expected outcome and `/signup` should be the survivor —
  it holds the higher sitemap priority. The real fix is the landing page, which
  gives both a parent that is neither.

---

## Verification log

Run by me, in this session, after the changes. Real exit codes.

| Check | Command | Exit |
|---|---|---|
| Typecheck | `npm run typecheck` | **0** |
| Lint | `npm run lint` | **0** |
| Format | `npm run format:check` | **0** |
| Build | `npm run build` | **0** |
| Unit tests | `npm test` | **0** — 191 passed, 10 files |
| E2E (auth) | `npx playwright test e2e/auth.spec.ts` | **0** — 6 passed. Run because the `<p>` → `<h1>` change alters DOM on a page every e2e test passes through. |

Fetched from `npx next start` on port 3100 (server stopped afterwards; confirmed
by PID check):

- `/signup` → 200. Exactly one `<title>`, exactly one `<h1>`, meta description,
  `<link rel="canonical">`, `og:title/description/url/site_name/locale/type`,
  `og:image` + width/height, `twitter:card/title/description/image`, one
  `application/ld+json` block.
- `/signin` → 200. Same set, distinct values.
- `/nope` → 404, single `noindex`, inherits the site defaults.
- `/dashboard`, `/clients`, `/invoices`, `/invoices/new` (fetched with a dummy
  session cookie, since the proxy only checks for presence) → each carries
  `noindex, nofollow, nocache`.
- `/opengraph-image` → 200, `content-type: image/png`, **PNG 1200×630**, 58 KB.
  Opened and eyeballed: brand palette, no clipped text.
- `/robots.txt` → 200, disallows `/dashboard`, `/clients`, `/invoices`, `/api/`.
- `/sitemap.xml` → 200, lists `/signup` and `/signin` only.
- **Agreement asserted programmatically:** every `<loc>` in the sitemap checked
  against every `Disallow:` in robots.txt — zero conflicts.
- `/` → 307 to `/dashboard` → 307 to `/signin`, confirming `/` was correctly
  kept out of the sitemap.

JSON-LD on both public routes was parsed with `json.loads` (valid) and asserted
to contain none of `offers`, `aggregateRating`, `review`, `priceRange`.
