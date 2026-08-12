<!-- Pillar: Build in public
     Day 23 · X/Twitter · single post
     Rests on: ADR-003 + the data model — quantityThousandths, integer cents end to end,
       decimals accepted to 3 places ("Quantity allows at most 3 decimal places." is a
       real authored validation message). QA round-tripped 7.5 hours → 112500 cents live.
     Asset: A3 (screen recording of the invoice form total updating live) — optional.
     Drafted by OMA. Nothing is posted for you. -->

# X — day 23

## Post

```
Quantity in my invoicing app is stored as thousandths of a unit.

7.5 hours is stored as 7500. Every total is integer arithmetic — no float ever
touches money.

The alternative was one day explaining to a client why their invoice says
$2,624.99.
```

Fits 280 as written; recount if you edit.

## Asset

Optional — **A3**, the 10-second clip of the form total recomputing as line
items are typed. It pairs well but the post works alone.

## Before you publish

- The `$2,624.99` is a hypothetical, and it should stay obviously hypothetical
  ("would have", "one day"). Don't rewrite it into "a client once asked me why…"
  — that's a story that didn't happen.
- Someone will reply that decimals in floats are fine if you round at the end.
  The useful answer is that rounding at the end still requires deciding where
  "the end" is, and with line-item amounts, an invoice total and a dashboard sum
  over all unpaid invoices, there are three ends. Integers mean not deciding.
