<!-- Pillar: How it works
     Day 19 · X/Twitter · single post
     Rests on: REQ-003 + REQ-008 + ADR-004 — sequential per-account numbering, visible on
       the invoice, and numbers are not reused after deletion. QA run-3 verified it live:
       deleted INV-0001, the next created invoice was INV-0002.
     Asset: A5 (invoice detail showing the number) — optional.
     Drafted by OMA. Nothing is posted for you. -->

# X — day 19

## Post

```
Invoice numbers in Ledgerly are sequential per account and never reused.

Delete INV-0001 and the next invoice is still INV-0002.

A gap in a numbering sequence is a question you can answer. A reused number is a
question you can't.
```

Fits 280 as written; recount if you edit.

## Asset

Optional — **A5**, cropped tight on the invoice header so the number is the
subject.

## Before you publish

- Expect "doesn't a gap look unprofessional to a client?" It's a fair question
  and the honest answer is that a client seeing INV-0001 and INV-0003 can ask
  one question and get one answer, whereas two different invoices sharing a
  number is unresolvable from the outside. Don't dodge it.
- Do not claim this is a legal or accounting requirement anywhere in particular.
  It varies by jurisdiction and you have not checked. [[TODO: if you want to
  make that argument, look up the actual rule for your country first — otherwise
  keep the post on the reasoning, which needs no citation.]]
