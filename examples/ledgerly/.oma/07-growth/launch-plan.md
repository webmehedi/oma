<!-- Written by oma-marketer. Lives at .oma/07-growth/launch-plan.md
     Nothing here is published by OMA. This is a plan the user executes, with
     the user's accounts and the user's reputation. No post has been made, no
     directory submitted, no message sent. -->

# Launch plan — Ledgerly

**The news, in one sentence:** *"I built the invoicing app I wanted: a client
list, line-item invoices, a print-clean invoice document, and one outstanding
total — no sending, no payments, nothing else."*

That sentence is the launch. The interesting part is not that an invoicing app
exists; it's the subtraction — the features deliberately left out, and the fact
that you'll say so on the page. Lead with what it *doesn't* do and you will get
a better class of first user, plus the only kind of comment thread worth having.

**Launch date:** `[[TODO: pick a date — a Tuesday, Wednesday or Thursday]]` ·
**Ready to launch when:** every row in the checklist below is green.

---

## Before you launch — asset checklist

| Asset | Status | Notes |
|---|---|---|
| The app itself, working | **exists** | 28/28 tasks `done`, pipeline green: typecheck, lint, format, build, 191 unit tests, 11 e2e |
| Deployed and reachable at a URL | **missing** | The container was proved locally on a fresh volume, but **nothing has been deployed**. `.oma/06-devops/deploy-runbook.md`, steps marked ⚠️ — Fly.io, one machine, one volume |
| Domain + TLS | **missing** | `[[TODO: domain name]]` |
| Working signup you have walked through yourself, on the deployed URL | **missing** | Do it as a stranger would, on a phone too. This is the thing every link points at |
| Sign-in rate limiting (SEC-001) | **missing** | Medium finding, open. Do not put a sign-in form on the public internet with no throttle and a length-only password policy |
| Sign-in timing fix (SEC-002) | **missing** | Four lines per the review; closes the registered-email oracle |
| Landing page built from `landing-copy.md` | **missing** | Copy is written and paste-ready; the page isn't built |
| The 12 open decisions in `landing-copy.md` filled | **missing** | Pricing and the locked-out policy are the two that cannot ship blank |
| 3–5 screenshots at 2× | **missing** | Dashboard with real figures; invoice form mid-edit showing a live total; the invoice document; the invoice list filtered to Unpaid |
| 30–60s demo recording, no voice-over needed | **missing** | The one flow: empty dashboard → add client → two line items (watch the total move) → save → the document → print preview → Mark paid → back to the dashboard, Outstanding drops. That is the entire product and it fits in 45 seconds |
| A "what it doesn't do" page or section | **written** | Section 5 of `landing-copy.md`. Keep it as a page — it will be linked more than you expect |
| Support channel that reaches you | **missing** | `[[TODO: support email]]`. An address in the footer is enough; silence is not |
| Pricing decided and stated | **missing** | `[[TODO]]`. "Free while it's in beta" is a decision. No billing exists in the app, so anything else means building it first |
| A reset/lockout answer | **missing** | There is no password reset. Decide what you do when someone is locked out, and publish it before the first person is |
| Database backup you have actually restored once | **missing** | The runbook has volume snapshots and `sftp get`. A backup you have never restored is not a backup |

**Do not launch with a red row.** A launch is spent attention; you get one first
impression per channel, and the failure that hurts is a signup form that 404s at
9am while your post is at the top of a page.

---

## Sequence

Assumes one person, no budget, no existing large audience. Adjust down, not up.

| When | Channel | What goes out | The rule that channel enforces |
|---|---|---|---|
| Day −10 | Your own network — the freelancers you personally know | Direct, individual messages: "I built this, will you break it for an hour?" Aim for 3–5 real users | Not a channel; a favour. Ask individually, never as a group blast |
| Day −7 | Wherever you already post (X / Mastodon / Bluesky / LinkedIn) `[[TODO: which one, and be honest about whether anyone is there]]` | Build-in-public: one screenshot of the invoice form with the live total, one line about why it does so little | You cannot manufacture an audience the week of launch. If you have none here, skip this row rather than fake it |
| Day 0, 07:00–09:00 your time | **Show HN** (news.ycombinator.com) | `Show HN: Ledgerly – invoicing for freelancers with no sending and no payments` + a first comment explaining the subtraction and naming the three open security items | Title is plain and factual — no adjectives, no "revolutionary". Marketing voice gets flagged in minutes. **Be in the comments all day**; that is the actual work. HN dislikes a hard signup wall, so put the demo video and screenshots above the fold. Expect a comment that says "this is just a spreadsheet" — answer it well and that thread becomes your best copy |
| Day 0, same morning | **r/SideProject** (and `[[TODO: check r/freelance and any freelancer subreddit you actually participate in]]`) | Same demo video, shorter text, honest about the limits | **Read each subreddit's sidebar the week of launch — the rules change and most freelancer subs ban self-promotion outright.** The only safe version in a strict sub is being a genuine participant who answers an existing "how do you track invoices?" thread. Posting a launch into a no-promo sub gets the post removed and can get you banned; that's the common failure |
| Day 0, afternoon | **Indie Hackers** — a "built this, here's what I left out" post | The subtraction argument, plus what building it cost you in hours | This audience rewards the *decisions*, not the app. A pure launch announcement sinks; a post about why you cut payments does not |
| Day +1 | **Product Hunt** `[[TODO: decide yes/no — it needs a gallery, a tagline, a first comment, and you present all day]]` | Full asset set: thumbnail, gallery, 60s video | Launch 00:01 PT and stay present. The failure mode for a solo unfunded launch is going to bed after posting. It is a full day of your attention — skip it if you can't give that |
| Day +3 | A written post-mortem on your own blog / dev.to, then submit *that* to HN | "What I removed from an invoicing app, and what broke anyway" — the money-arithmetic decision (integer cents) and the container bug found at build time are both genuinely interesting | The write-up usually outlives the launch. Technical honesty is the whole draw; a post-mortem that is secretly an ad reads as one |
| Day +7 | Directory listings, slowly `[[TODO: pick 2–3 you'd actually use yourself]]` | The same copy, submitted by you | Low value, low cost. Do not buy "we'll submit you to 100 directories" — it's link spam with your name on it |

**Channels deliberately not on this list:** paid ads (nothing to measure yet and
no pricing), cold email to freelancers (you have no email infrastructure and it
would be spam), and influencer outreach (there is nothing to pay with and no
track record to trade on).

---

## What to expect

An unfunded launch by one person, honestly.

- **Most launches are quiet.** A quiet launch is not a failed product — it's a
  distribution problem, and distribution compounds over months while a launch
  day does not. Do not decide anything about Ledgerly's future on day two.
- **The range, with the assumption stated:** a Show HN that does *not* reach the
  front page is typically seen by a small number of people browsing /newest, and
  a front-page one is seen by a lot; the gap between those two outcomes is far
  larger than anything you control on the day. So plan for the low case and
  treat the high case as weather. Concretely: assume **tens of visitors, not
  thousands**, and a signup rate in the low single-digit percent of visitors —
  which on tens of visitors means **you may get zero to a handful of signups,
  and that is the normal result**. `[[TODO: after the day, write the real
  numbers in here — you will want them the next time you launch something.]]`
  I have not sourced industry conversion benchmarks and am not going to invent
  any; measure your own.
- **The outcome that matters in week one is not signups.** It's whether anyone
  who signed up creates a *second* invoice. One invoice is curiosity. Two is a
  ledger they intend to keep.
- **Five real users who invoice weekly is a success.** That's enough to learn
  what actually breaks and enough to know whether the subtraction was right.

---

## Week-one metrics

You have **no analytics in the app** — no tracker, no pixel, no third-party
script, and no consent banner to justify one. That's a feature; keep it. Every
metric below is readable from your own server without adding any of that.

| Metric | Where to read it | What it tells you |
|---|---|---|
| Signups per day | `SELECT date(createdAt), count(*) FROM User GROUP BY 1` on the database | Raw interest. The only number the launch itself moves |
| Accounts with ≥1 invoice | `User` joined to `Invoice` | Whether the first-run flow actually lands. A big gap here means the empty state or the client-first requirement is the wall |
| Accounts with ≥2 invoices | same | The real retention signal at this volume — they came back and did it again |
| Day-3 return | `Session` rows created more than 48h after a user's signup | Whether the product is a tool or a demo. This is the number to care about |
| Where visitors came from | Your web server / Fly logs (`Referer`) | Which channel was worth the day. Log-derived, no tracker needed |
| Replies, emails, comment threads | Your inbox and the launch threads | At tens of users, the only qualitative signal there is — and worth more than all the rows above |

Read these once at the end of week one, not hourly on day one. Refreshing a
counter is not distribution.

---

## If it goes quiet

Three concrete moves, in order:

1. **Talk to everyone who signed up.** Not a survey — an individual email asking
   what they were using before and whether they made a second invoice. At this
   volume you can email all of them personally, and the answers are the roadmap.
2. **Publish the thing you learned building it.** The integer-cents money
   decision, the Postgres-portability guardrails, or the container bug that
   passed `docker build` and died on first boot. Technical write-ups reach the
   people who would use this, and they keep working for months.
3. **Pick one channel and be present in it for a month** — one freelancer
   community where you answer questions about getting paid, without linking
   Ledgerly most of the time. Slower than a launch and far more reliable.

What *not* to do: rebuild the landing page, add a feature from `scope.md`'s
out-of-scope list, or launch again somewhere new next week. Silence is usually
distribution, not the product.

## If it goes well

The limits are known and written down, so here's what breaks in order.

- **Scale, first and hardest.** Ledgerly's database is a SQLite file that
  exactly one process writes to. The runbook is explicit: **never scale past one
  machine** — a second machine on the volume corrupts the arrangement, and Fly
  will try. `fly scale count 1`, and watch `fly machine list`. Vertical is the
  only direction available; the Postgres move is a day of work, not an hour
  (runbook: migration history is not portable, and the data needs a hand-written
  copy script).
- **Cost, second.** The knob that produces a surprise bill is
  `min_machines_running = 1`, not traffic. Set a spending limit in the Fly
  dashboard on day one and re-check the current prices yourself — the runbook's
  figures are marked unverified for exactly that reason.
- **Support load, third.** Pre-answer the highest-frequency question, which will
  be **"can it email the invoice to my client?"** — it's the first thing every
  freelancer assumes an invoicing app does. It's already answered in the FAQ;
  when it arrives three times in a day, put it in the app's empty state too
  (file that as a task for `oma-frontend` with the exact string — it is not
  yours to edit and it is not mine).
- **The second question will be "can I export everything?"** and the honest
  answer today is no. If traffic is real, that is the first thing to build.
- **Security, immediately.** If SEC-001 and SEC-002 are still open when traffic
  arrives, close them that week. Attention brings the people who try passwords.
