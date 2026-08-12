<!-- Pillar: Build in public (things that broke)
     Day 16 · X/Twitter · single post
     Rests on: QA run-3 F-8 / T-028 — with a contract-legal invoice total, /invoices and
       /invoices/{id} rendered correctly while /dashboard showed "Couldn't load your
       dashboard." The cause was centsSchema being stricter than the frozen API contract.
     Asset: A1 or none. A screenshot of the failed dashboard would need a re-created repro.
     Drafted by OMA. Nothing is posted for you. -->

# X — day 16

## Post

```
One invoice rendered fine on the list, fine on the detail page, and killed the
dashboard.

The dashboard checked its own data against a schema stricter than the API
contract it mirrored. One screen died instead of degrading.

Now it's the first failure mode I look for.
```

Fits 280 as written; recount if you edit.

## Asset

Optional. If you want one, it means re-creating the repro (an invoice total
above Number.MAX_SAFE_INTEGER cents) on a scratch account and screenshotting the
error banner beside the working list view. That's the strongest version of this
post, and it's twenty minutes of work.

[[TODO: decide whether you're re-creating the repro; if not, post it text-only]]

## Before you publish

- Don't spell out `Number.MAX_SAFE_INTEGER` in the post — the specific threshold
  invites "no invoice is that big", which is true and beside the point. The
  point is that validating your own response harder than your contract turns a
  precision limit into a dead screen. Save the threshold for the replies.
- If someone asks whether it's fixed: yes, and it was one schema line plus a
  test. Say that. "One line" is the detail that makes the story useful.
