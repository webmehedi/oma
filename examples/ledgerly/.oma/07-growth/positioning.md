<!-- Written by oma-marketer. Lives at .oma/07-growth/positioning.md
     Every claim below is traceable to a shipped requirement, a `done` task, or
     a verified row in .oma/05-qa/reports/run-3.md. Traceability is cited inline
     so a future agent can re-check it instead of trusting it. -->

# Positioning — Ledgerly

## The one sentence

**Ledgerly is a single-user invoicing ledger for solo freelancers — it keeps the
client list, does the invoice arithmetic, and tracks who has paid, replacing the
spreadsheet that quietly drifts out of sync with what you are actually owed.**

The three verbs are the whole product: *compose* an invoice from line items
(REQ-003), *present* it in a print-clean document (REQ-004), *mark it paid*
(REQ-005) so one number on the dashboard stays true (REQ-006).

## The ideal customer

**A solo freelancer who bills 2–15 invoices a month, in US dollars, to fewer
than about twenty clients, and who sends invoices themselves — by email, chat,
or as a printed PDF — and gets paid by bank transfer.**

Written from `.oma/01-discovery/personas.md`: Maya (full-time, 6–10 active
clients, 5–15 invoices/month) is the primary; Tomás (moonlighter, 2–3 clients,
one or two invoices a month, weeks between sessions) is the secondary and the
harder test, because he re-learns the app every time he opens it.

This description is meant to exclude people. Ledgerly is **not** for:

| Not for | Why, concretely |
|---|---|
| Agencies, studios, anyone with a colleague | Single-user accounts only; there is no sharing, no roles, no team (`scope.md`) |
| Anyone who must show tax or VAT on an invoice | No tax lines and no discount lines exist (deferred, `scope.md`) |
| Anyone billing outside USD | Single currency, USD display only (`scope.md`) |
| Anyone who wants clients to pay in-app | No payment processing, no payment links, no card fields anywhere (brief + `scope.md`) |
| Anyone who wants the app to email the invoice | Zero outbound email in v1 — it produces the document, you send it (REQ-004 note) |
| Anyone with recurring/retainer billing | No recurring invoices (deferred, `scope.md`) |
| Anyone tracking hundreds of invoices | Fixed 25-per-page list, no search, no bulk anything (REQ-007; search deferred at ~200 invoices) |

If a prospect is in that table, say so early. The people who stay are the ones
for whom "less" is the feature.

## Category and alternatives

**Category:** freelance invoicing — specifically the *record-keeping* half of
it, not the *getting-paid-online* half.

The four real alternatives, in the order a freelancer actually meets them:

1. **A spreadsheet.** The default and the true competitor. Free, already open,
   infinitely flexible — and it has no idea what an invoice *is*, so paid/unpaid
   is a cell somebody has to remember to change, and totals are formulas that
   survive until someone drags one.
2. **A document template** (Word/Docs/Pages). Produces a good-looking invoice
   and nothing else — no list, no status, no total across invoices. You end up
   with a spreadsheet *as well*.
3. **A full accounting suite.** Does everything Ledgerly does and thirty things
   more, including the ones Ledgerly deliberately lacks (sending, payments,
   tax, multi-currency). Costs a monthly fee, has an onboarding, and buries the
   three-step loop under features a solo freelancer never touches.
   *Do not name specific products in public copy unless you have re-checked
   their current pricing and features that week — see Voice rule 3.*
4. **Doing nothing.** Invoicing from memory and chasing when the bank balance
   looks wrong. More common than any vendor admits, and the state most first-time
   Ledgerly users are actually in.

**Where Ledgerly wins:** against 1, 2 and 4, on correctness and on one honest
number. **Where it loses:** against 3, the moment someone needs tax, sending,
payments, or a second person — and it should lose there. Losing that comparison
cleanly is cheaper than winning it dishonestly.

## Three differentiators

Each is tied to something that shipped, with the receipt.

### 1. It is small on purpose, and the small part is the part you do daily

Six screens: dashboard, invoices, one invoice, new invoice, clients, sign-in
(`.oma/03-design/screens/`, T-012..T-019, all `done`). Two invoice statuses —
unpaid and paid — and no third (REQ-005; draft/sent/overdue explicitly out of
scope). Nothing to configure before the first invoice: issue date defaults to
today, the invoice number is assigned for you.

*Receipt:* QA drove the whole loop end to end in a real browser and in the API
in run 3 — REQ-003 through REQ-006 all verified.

### 2. You never type a total, and you never type an invoice number

Line amount (quantity × unit price) and the invoice total compute live as you
type in the form, and are **recomputed on the server** on save — the number
stored is never the number the browser sent. Money is held as whole cents,
never floats. Quantities take decimals, so 7.5 hours is 7.5 hours.
Invoice numbers are sequential per account (INV-0001, INV-0002 …) and a deleted
invoice's number is never reused.

*Receipt:* REQ-003, T-006, ADR-003 and ADR-006. QA's mutation campaign in run 3
truncated the money arithmetic in three different places and the test suite
turned red every time; 191 unit tests and 11 end-to-end tests pass on the
shipped commit.

### 3. The outstanding figure is designed to stay trustworthy, not just to look right

A paid invoice locks: you cannot edit or delete it without first reverting it to
unpaid, and the app tells you why. Editing a client's details updates that
client's existing invoices. Marking paid records the date; reverting clears it.
A client with invoices attached cannot be deleted at all.

That is the exact failure mode of the spreadsheet — figures that silently stop
matching reality — closed by design rather than by discipline.

*Receipt:* REQ-002, REQ-005, REQ-008, ADR-005, T-008/T-009 `done`; QA verified
the lock from the UI and the API (409 `INVOICE_PAID_LOCKED` on both PATCH and
DELETE).

## The three objections, answered honestly

### "Why wouldn't I just keep using my spreadsheet?"

If your spreadsheet is right, keep it — genuinely. Ledgerly is worth a switch
only if you have had the specific experience of your sheet disagreeing with your
bank: a row marked paid that wasn't, a total that stopped summing, a client who
paid twice because you asked twice. Ledgerly makes those states hard to reach:
totals are computed server-side, paid invoices lock, and the outstanding figure
is derived from the invoices rather than maintained by hand.

**What the spreadsheet still does better:** anything unusual. A discount line, a
different currency, a note in the margin, three columns of your own. Ledgerly
has none of that and is not adding it in v1.

### "It can't send an invoice or take a payment. Is that half an app?"

It is half of *invoicing*, and it is the half you repeat. Ledgerly produces the
finished invoice document — number, dates, client, every line, total, paid
stamp — and gets out of the way; you attach it to the email you were going to
write anyway. The reason is deliberate: v1 has **no outbound email at all**
(which also means no password reset — see the FAQ) and **no payment processing**.

**Honest version:** if the thing you want is "click send, client clicks pay",
Ledgerly is the wrong product today and there is no date on which it becomes the
right one. Email sending and payment links are not on the v1 roadmap;
`scope.md` lists them as out of scope, not as "coming soon".

### "It's my clients' details and my income. Why would I trust it?"

Here is what has actually been verified, and what has not.

**Verified** (`.oma/06-devops/security-review.md`, `.oma/05-qa/reports/run-3.md`):
account separation was probed for real — a second account ran eleven operations
against the first account's invoices and clients and got "not found" on all
eleven, and the separation is enforced in the data layer rather than in the
routes. Passwords are stored with argon2id. The session cookie is HttpOnly and
SameSite. There is no third-party script, no analytics, and no tracker in the
app at all; the server makes no outbound requests. Stored `<script>` payloads
render as text. Dependency audit is zero vulnerabilities.

**Not fixed yet, and a buyer should know:** sign-in has no rate limit or lockout,
so password guessing is not slowed down; sign-in's response *timing* reveals
whether an email is registered; and the Content-Security-Policy currently ships
in report-only mode rather than enforced. All three are rated medium — zero
critical, zero high — and all three are open. **Close SEC-001 and SEC-002 before
this is on the public internet**, and re-write this section when you do.

**Never say:** "bank-level security", "enterprise-grade", "fully encrypted", or
any compliance word. None of them is supported and the security review says so.

## Voice and tone

### Three rules

1. **Name the limit in the same breath as the feature.** "Print-clean invoice
   document — you send it yourself; Ledgerly has no email." One sentence, both
   halves. A limit discovered later feels like a lie; a limit stated up front
   is a filter that works for you.
2. **Use the interface's own words.** The app says *Outstanding*, *Paid in
   August*, *Mark paid*, *Mark unpaid*, *New invoice*, *Add client*. Copy uses
   those exact words and invents no synonyms — a reader should recognise the
   product on the first screen they see.
3. **A number in the copy has a source or it doesn't ship.** Product figures
   (six screens, 25 per page, two statuses) come from the specs; anything about
   the world outside the repo needs a link. No statistic, no benchmark, no
   "freelancers lose X hours a week".

### Two banned words

- **seamless**
- **effortless**

Both describe a feeling the reader hasn't had yet, and both are what every
competing page already says. Also banned as *claims*, not just words:
"bank-level", "enterprise", "trusted by", and any use of "secure" as a bare
adjective.

### Tone in one line

Plain, specific, a little understated — the voice of a tool that would rather be
believed than admired.
