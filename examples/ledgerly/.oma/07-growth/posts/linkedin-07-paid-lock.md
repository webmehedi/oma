<!-- Pillar: Build in public (a decision, with a point of view)
     Day 5 · LinkedIn
     Rests on: REQ-008 + ADR-005 — a paid invoice's edit affordance is absent, revert to
       unpaid to edit; API returns 409 INVOICE_PAID_LOCKED on PATCH and DELETE, verified
       in QA run-3. The PRD itself lists this as one of the three riskiest assumptions.
     Asset: A5 (invoice detail, paid, with the disabled edit affordance and its reason).
     Drafted by OMA. Nothing is posted for you. -->

# LinkedIn — day 5

## Post

```
You cannot edit a paid invoice in Ledgerly.

Several people are going to read that as a missing feature, so let me argue for
it before they do.

A "paid this month" figure that anyone can retroactively rewrite is not a
figure, it's a suggestion. The moment a paid invoice can be edited in place, the
number on the dashboard stops being a record of what happened and becomes a
record of what the file currently says. Those are different things, and the
difference only shows up months later, when you're trying to work out where a
missing $400 went.

So paid invoices are locked. The API refuses the edit outright rather than
letting the UI pretend. If you need to correct one, you flip it back to unpaid
first — the correction is one extra click and it leaves the status trail
visible, which is exactly the trade I wanted.

The honest part: this is the decision in the whole product I'm least sure about.
I made it alone, on a data-integrity argument, without watching anyone hit it.
If it turns out freelancers routinely fix invoices after payment lands — wrong
rate, wrong hours, a line the client queried — then the revert-to-edit step is
just friction wearing a principle's clothes, and I'll say so and change it.

If you invoice: how often do you actually correct an invoice after it's been
paid? Genuinely asking, because that answer decides this.
```

## Asset

**A5** — invoice detail view of a paid invoice, showing the paid stamp and the
absent/disabled edit affordance with its reason.

## Before you publish

- The two-line opening does the work: a flat statement of the constraint, then
  permission to disagree. Don't bury it under a preamble.
- The closing question is real. Read the answers before defending the decision
  in the comments.
- No emoji bullets. Plain paragraphs are the format that works here.
