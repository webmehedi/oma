<!-- Pillar: The problem (framed as what the product will and won't become)
     Day 30 · LinkedIn
     Rests on: the real deferred list in .oma/01-discovery/scope.md (overdue detection,
       recurring invoices, dedicated PDF export, tax/discount lines, search, multi-currency,
       password reset, partial payments) with their real revisit triggers; the v1.1 items
       accepted at the QA and security gates; and the permanent out-of-scope list.
     Asset: none.
     Drafted by OMA. Nothing is posted for you. -->

# LinkedIn — day 30

## Post

```
Thirty days of Ledgerly being public, and the most useful thing I can post is
the list of things it still doesn't do.

Not as a roadmap promise — as the actual state of it, with what would make me
build each one.

No overdue flag. Invoices carry a due date, but nothing marks one late. I build
this the first time someone tells me the outstanding total is hiding a
problem — which is a real failure mode, and probably the first thing to go in.

No recurring invoices. The trigger is people recreating the same invoice every
month. If that's you, say so, because right now I only have my own habits to go
on.

No password reset. This one has an unusual reason: the app has no outbound email
anywhere, so there is literally nowhere to send a reset link. Adding it means
adding a mail pipeline, which is a bigger decision than the feature.

No search. It doesn't hurt until you're past roughly fifty clients, so it waits
for someone to actually get there.

No tax or discount lines, and USD only. Both are the same shape of problem:
easy to add badly, and correctness matters more than speed.

And the permanent list — the things I'm not going to build regardless of who
asks. No payment processing. No multi-user or teams. No client portal. Those
would each turn this into a different product, and there are good versions of
that product already.

The thing I'd say to anyone building something small: writing down what you
won't do, with the specific event that would change your mind, is worth more
than a roadmap. It's the difference between "not yet" and "no", and users can
plan around a "no".

[[TODO: if any of the above changed during the month — because someone asked —
say which and who prompted it. That's the strongest version of this post, and it
requires the month to have actually produced it.]]
```

## Asset

None. This one is a text post.

## Before you publish

- Check this list against `.oma/01-discovery/scope.md` on the day you post. If
  you shipped one of these in the first month, it has to come off the list —
  posting a deferred item you already built is the sort of error people screenshot.
- Don't promise dates. Every item above has a trigger, not a date, and that's
  the honest version.
