<!-- Written by oma-social. Lives at .oma/07-growth/social-calendar.md
     Every row has a real draft file behind it in .oma/07-growth/posts/.
     OMA posts nothing. No account was connected, nothing was scheduled, nothing
     was sent. These are drafts on disk for the user to edit and publish. -->

# Social calendar — Ledgerly — 30 days

**22 posts over 30 days, plus one pre-launch post**, across five platforms.
Every claim in every draft traces to a shipped requirement, a `done` task, an
ADR, or a verified row in `.oma/05-qa/reports/run-3.md`. There are no invented
numbers anywhere in this calendar; where a post needs a figure the product
doesn't have yet, the draft carries `[[TODO: real number]]`.

## Do not start this calendar yet

`launch-plan.md`'s asset checklist gates day 1, and when this was written it had
red rows — including **nothing deployed**, no domain, and two open medium
security findings: **SEC-001** (no rate limit or lockout on sign-in) and
**SEC-002** (sign-in timing reveals whether an email is registered).

Day 1 points five platforms at a sign-in form. Do not run it until that form is
throttled and the URL has been walked through end to end from a clean browser,
including on a phone. Everything in `posts/` keeps indefinitely; a launch day
does not repeat.

## Cadence

| Stretch | Posts | Shape |
|---|---|---|
| Day −7 | 1 | One pre-launch post, per `launch-plan.md`. Skip it if you have no audience where you'd post it — don't fake one. |
| Week 1 (days 1–7) | 9 | Launch week, dense and sequenced against `launch-plan.md`. Five of these are on day 1 itself, across five different platforms. |
| Week 2 (days 8–14) | 4 | The sustainable rhythm starts. |
| Week 3 (days 15–21) | 4 | |
| Week 4 (days 22–30) | 5 | |

Four posts a week is the number one person can hold while also answering replies
and fixing what launch week finds. It is deliberately below what you could do in
a good week, because a calendar sized for good weeks gets abandoned in week two.

**Day 1's five posts are the exception, not a precedent** — they're five
platforms on one morning because a launch only lands once. If the day gets away
from you, the Show HN thread and its comments are the part that matters; drop
the Indie Hackers post first, then LinkedIn. Both keep until day 2.

## Platform mix and why

From `.oma/01-discovery/personas.md`, not from a list of popular platforms. Maya
is a full-time freelance designer, 6–10 clients, laptop for work and phone for
checking. Tomás moonlights around a day job, invoices once or twice a month.

| Platform | Posts | Who is actually there |
|---|---|---|
| **X/Twitter** | 12 | Where solo builders show work in progress and where freelancers who follow tool-makers already are. The bulk of the calendar because the format suits one specific detail per post, and because it's the only platform here where posting four times a week is normal rather than aggressive. |
| **LinkedIn** | 6 | Where freelancers keep a professional face and where Tomás already has an account for his day job. Longer-form, one point of view per post. This is also the platform most likely to reach someone who hires freelancers, which is a second-order reason to be there. |
| **Reddit** | 2 | Two posts only, in two subreddits that permit them, because most communities remove promotional posts on sight. Both drafts name the rule they're operating under. |
| **Hacker News** | 1 | One Show HN. The stack (Next.js, SQLite via a driver adapter, integer money, print-stylesheet-instead-of-PDF) is genuinely of interest here, and the honest-limitations framing is what HN rewards. You get one. |
| **Indie Hackers** | 1 | Per `launch-plan.md`'s day-0 afternoon row. This audience engages with the decisions, not the app, which is exactly what the draft is. |

### Platforms deliberately not in this calendar

- **Instagram and TikTok.** Maya is a designer and designers are on Instagram —
  but they're there for portfolio and inspiration, not for invoicing tools, and
  short-form video is the most expensive content a solo builder can make per
  unit of reach. A caption without a plan for the visual isn't a draft, and I'm
  not going to fill a grid with visuals you'd have to invent a reason to shoot.
  If you're already fluent in video and it's cheap for you, revisit this — the
  invoice-form-total clip (A3) is the one thing here that would work as a Reel.
- **Freelancer subreddits (r/freelance and similar).** `launch-plan.md` flags
  them and is right to: most ban self-promotion outright, and a removed post can
  cost the account. There is no draft for them because there shouldn't be a
  post. The only honest version is being a genuine participant who answers
  existing "how do you track invoices?" threads over months — that's a habit,
  not a calendar row, and it's the highest-value thing on this page.
- **Product Hunt.** `launch-plan.md` leaves it as a `[[TODO: decide yes/no]]`
  and it needs a gallery, a tagline and a full day of presence. It's a launch
  channel, not a social cadence, so it stays in the marketer's file rather than
  being duplicated here.

## Content pillars

| Pillar | What it's for | Target | Actual |
|---|---|---|---|
| Build in public | progress, decisions, things that broke | 40% | 45% (10 posts) |
| The problem | the pain the product removes | 25% | 18% (4 posts) |
| How it works | one feature, one screenshot, one sentence | 20% | 23% (5 posts) |
| Useful & unrelated | things worth reading that aren't your product | 15% | 14% (3 posts) |

Build-in-public runs over target and the problem pillar under it, because a
launch month genuinely is build-heavy — five of the ten build posts are launch
day itself or the two week-one retrospectives. From day 31 the balance should
invert: the problem pillar is what reaches people who have never heard of the
product, and it's the one to grow first.

**The "useful & unrelated" pillar is the one people cut**, and it's the one that
makes the account worth following when you have nothing to announce. Two of its
three posts (`reddit-12`, `x-19`) carry no product link at all. That's the
discipline; keep it.

## Assets to make first

Batch these in one sitting before day 1. Four of them are already on
`launch-plan.md`'s checklist — make each one once and use it in both places.

| ID | Asset | Used by | Also on launch-plan |
|---|---|---|---|
| **A1** | Dashboard screenshot — Outstanding, Paid this month, recent invoices | 2 posts (+2 optional) | yes |
| **A2** | Invoice list filtered to Unpaid, **with the browser address bar in frame** so `/invoices?status=unpaid` is legible | 2 posts | yes |
| **A3** | 10s screen recording: type a quantity and unit price, watch the line amount and total move. No cuts, no music | 1 post (+1 optional) | part of the demo |
| **A5** | Invoice detail view of a **paid** invoice — paid stamp visible, edit affordance absent | 1 post (+1 optional) | yes |
| **A6** | Print preview **beside** the on-screen invoice. The contrast is the asset; a preview alone doesn't land | 2 posts | no |
| **A7** | Real phone screenshot of the dashboard (an actual phone, not devtools emulation) | 1 post | no |
| **A8** | Dashboard empty state on a fresh account | optional, 2 posts | no |
| **A10** | Code screenshot: the BigInt migration, or the emitted Postgres DDL. Eight lines maximum so it's legible in a feed | 1 post (+1 optional) | no |
| **A12** | 45s recording of the whole loop: empty dashboard → add client → two line items → save → the document → print preview → Mark paid → Outstanding drops | 2 posts | yes |

### The one thing you must decide before taking any screenshot

`[[TODO: real account or demo account?]]` Both are fine; mixing them is not.

- **Real account:** replace client names with placeholders **inside the app**,
  not in an image editor, so nothing real is one un-blurred pixel away from
  publication. Those are your clients' names, and they're not yours to publish.
- **Demo account:** seed it, and say "demo data" in the post or the first reply.

Never let a viewer read a figure in a screenshot as money you personally earned
unless it is. That is the fastest way to lose the credibility this whole
calendar is built on, and it's unrecoverable.

## Calendar

| Day | Platform | Pillar | Hook (first line, verbatim) | Asset | Draft |
|---|---|---|---|---|---|
| −7 | X | Build in public | "Shipping this next week." | A3 | `posts/x-00-preview.md` |
| 1 am | Hacker News | Build in public | "Show HN: Ledgerly – invoicing for freelancers with no sending and no payments" | — | `posts/hn-01-show-hn.md` |
| 1 am | Reddit — r/SideProject | Build in public | "I built an invoicing app that deliberately can't send invoices" | A2 | `posts/reddit-05-sideproject.md` |
| 1 am | X | Build in public | "My invoice tracking was a spreadsheet I'd stopped trusting." | A1, A6 | `posts/x-02-launch-thread.md` |
| 1 midday | LinkedIn | The problem | "A spreadsheet will give you a number. It won't tell you whether the number is still true." | A12 | `posts/linkedin-03-launch.md` |
| 1 pm | Indie Hackers | Build in public | "I cut sending, payments, tax and three invoice statuses. Here's what was left." | A12 | `posts/ih-22-what-i-left-out.md` |
| 2 | X | How it works | "The whole dashboard is two numbers and a list of ten." | A1 | `posts/x-04-one-number.md` |
| 4 | X | Build in public | "The money columns in my invoicing app were 32-bit ints. Max invoice total: about $21.5M." | A10 | `posts/x-06-money-columns.md` |
| 5 | LinkedIn | Build in public | "You cannot edit a paid invoice in Ledgerly." | A5 | `posts/linkedin-07-paid-lock.md` |
| 7 | X | Build in public | "One week since Ledgerly went up." | — | `posts/x-08-launch-week.md` |
| 9 | X | How it works | "I didn't build PDF export. I wrote a print stylesheet." | A6 | `posts/x-09-print-not-pdf.md` |
| 10 | LinkedIn | The problem | "I could always tell you what I was owed. I couldn't tell you when I last checked that it was true." | — | `posts/linkedin-10-reconcile.md` |
| 12 | X | How it works | "Small thing I'm unreasonably pleased with: the invoice filter lives in the URL." | A2 | `posts/x-11-url-filter.md` |
| 14 | Reddit — r/webdev | Useful & unrelated | "Replacing PDF export with a print stylesheet — and how to actually verify it worked" | — | `posts/reddit-12-webdev-print-css.md` |
| 16 | X | Build in public | "One invoice rendered fine on the list, fine on the detail page, and killed the dashboard." | — | `posts/x-13-one-screen-died.md` |
| 17 | LinkedIn | How it works | "Ledgerly's mobile layout is not built for creating invoices, and I'm not going to pretend otherwise." | A7 | `posts/linkedin-14-mobile.md` |
| 19 | X | How it works | "Invoice numbers in Ledgerly are sequential per account and never reused." | A5 (opt) | `posts/x-15-invoice-numbers.md` |
| 21 | X | Useful & unrelated | "Chasing a late invoice is easier if you decide the schedule before you need it." | — | `posts/x-16-chasing-unpaid.md` |
| 23 | X | Build in public | "Quantity in my invoicing app is stored as thousandths of a unit." | A3 (opt) | `posts/x-17-decimal-quantities.md` |
| 24 | LinkedIn | The problem | "Most accounting software is built for a finance department." | A8 (opt) | `posts/linkedin-18-built-for-firms.md` |
| 26 | X | Useful & unrelated | "Running SQLite in production for a single-user app is fine. Keeping the option to leave is the actual work." | A10 (opt) | `posts/x-19-sqlite-guardrails.md` |
| 28 | X | Build in public | "A month of Ledgerly being public." | — | `posts/x-20-month-one.md` |
| 30 | LinkedIn | The problem | "Thirty days of Ledgerly being public, and the most useful thing I can post is the list of things it still doesn't do." | — | `posts/linkedin-21-whats-next.md` |

Days 3, 6, 8, 11, 13, 15, 18, 20, 22, 25, 27 and 29 are deliberately empty.
They are where you reply to people, which at this stage is worth more than any
post on this page.

## Two posts you cannot publish as written

`posts/x-08-launch-week.md` (day 7) and `posts/x-20-month-one.md` (day 28) are
**scaffolds**, not drafts. Both are retrospectives, so every number in them has
to come from the period that actually happened. Each carries `[[TODO: real
number]]` markers and an alternative "if the week was quiet" version, because a
quiet launch is the normal outcome and `launch-plan.md` says so plainly — assume
tens of visitors and possibly zero signups.

If the real number is 3, post 3. If you won't post the real number, delete the
sentence. "The response has been amazing" is the exact sentence this entire
calendar exists to avoid.

## Rules for this account

- **Never post a number you don't have.** `[[TODO: real number]]` is the only
  acceptable placeholder, and it is not decoration.
- **Maya and Tomás are internal fiction.** They live in `personas.md` as design
  tools. They are not users, they have never said anything, and no post may
  quote them, paraphrase them, or borrow their details as your experience.
  `linkedin-10` carries a `[[TODO]]` asking outright whether its opening line is
  true of you — answer it honestly or rewrite the opener. Apply the same test to
  every first-person sentence you keep.
- **No quoting a user without a public link.** No screenshots of DMs, no
  paraphrased praise, no "someone told me…".
- **Reply to everyone in the first month.** Reach at this stage comes from
  conversations, not from posting volume. This is why the calendar has gaps.
- **One person, said plainly.** Never "we" — the solo story is more interesting
  than the fake team story, and it's the one the whole positioning rests on.
- **Name the limit in the same breath as the feature** (`positioning.md`, voice
  rule 1). Every draft here does; keep it that way when you edit.
- **Use the interface's own words** (voice rule 2): Outstanding, Paid in August,
  Mark paid, Mark unpaid, New invoice, Add client. No synonyms.
- **Banned outright** (`positioning.md`): *seamless*, *effortless*,
  *bank-level*, *enterprise*, *trusted by*, and "secure" as a bare adjective.
  Also banned here: engagement bait ("comment YES and I'll DM you the link"),
  manufactured urgency, and manufactured scarcity.
- **Don't name a competing product.** `positioning.md` allows it only if you
  re-checked their pricing and features that week. Nothing here does, so nothing
  here names one.
- **If a week goes badly and nothing gets posted, skip it.** Don't post filler
  to fill the grid. A gap costs nothing; a bad post costs attention you can't
  re-earn.
- **Re-read a subreddit's rules the morning you post.** Both Reddit drafts say
  this. Rules change and I cannot verify current sidebar text from here.

## What I couldn't verify, and what's still open

- **Nothing is scheduled or connected.** OMA has no account access and made no
  post. Every file here is a draft on disk.
- `positioning.md` and `launch-plan.md` landed while I was drafting, so the
  calendar is aligned to both — voice rules, the banned-words list, the
  competitor rule, the day-0 sequence and the security gate all come from them.
  If either file changes after this, the drafts most likely to need a second
  look are `hn-01` (the security paragraph and the first comment) and
  `linkedin-21` (the deferred list).
- **The public URL does not exist yet.** Every `[[TODO: URL]]` in the drafts is
  live until it does. `deploy-runbook.md` targets `https://ledgerly.fly.dev` but
  nothing has been deployed.
- **Two product questions are unanswered and both appear in drafts as genuine
  questions to readers**, which is the right place for them: whether locking
  paid invoices is correct (`linkedin-07`, `reddit-05`) and whether two invoice
  statuses are enough (`ih-22`, `reddit-05`). The PRD lists both as riskiest
  assumptions. The answers you get in those threads are worth more than the
  posts.
- **Is the source public?** `hn-01` and `reddit-05` both carry a `[[TODO]]` for
  this. HN will ask within three comments, and the answer changes how both posts
  land. Decide before day 1.
