<!-- Pillar: How it works
     Day 17 · LinkedIn
     Rests on: REQ-010 as built and as verified in QA run-3 — at 375px every screen has
       scrollWidth == clientWidth == 375 with zero overflowing elements, row-cards, filter
       tabs, status toggles and the sticky save bar all reachable; desktop-first is an
       explicit intake decision, and mobile is scoped as read/mark-paid competent.
     Asset: A7 (real phone screenshot of the dashboard at 375px-class width).
     Drafted by OMA. Nothing is posted for you. -->

# LinkedIn — day 17

## Post

```
Ledgerly's mobile layout is not built for creating invoices, and I'm not going
to pretend otherwise.

It's built for the thirty seconds after a payment notification arrives.

That's a real design decision rather than a shortcut, so here's the reasoning.
Making an invoice is a desk activity: you're picking a client, typing line
items, checking hours against your notes, reading a total. Every one of those is
easier with a keyboard and a wide screen, and no amount of responsive work
changes that. Meanwhile the two things you genuinely want on a phone are: what
am I owed, and this one just landed, mark it paid.

So both of those work properly on a phone. Every screen fits a 375-pixel-wide
viewport with no horizontal scrolling — the tables become stacked cards, the
filter tabs stay tappable, the paid toggle is where your thumb already is, and
the save bar sticks to the bottom instead of scrolling off. The invoice form
works too. It's just not where I'd choose to build one, and I'd rather say that
than claim a phone-first experience I didn't design.

I think a lot of small tools would be better if they picked which half of the
job the phone is for, instead of shipping a compressed desktop app and calling
it responsive.

What's the one thing you'd actually want to do from your phone in a tool like
this? If it's more than "check the number and mark it paid", I've scoped this
wrong and I'd like to know now.
```

## Asset

**A7** — a real phone screenshot of the dashboard (not a devtools emulation —
people can tell, and the status bar sells it).

## Before you publish

- The two-line opening is a concession, which is why it works. Don't rewrite it
  into a boast about responsive design.
- Verify the claim on your own phone before posting. It was tested at 375px, but
  a post that says "no horizontal scrolling" is one screenshot away from being
  disproved by a stranger.
