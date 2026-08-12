<!-- Pillar: How it works
     Day 9 · X/Twitter · single post
     Rests on: REQ-004 + QA run-3 print probe — under print media the set of visible
       nav/button/a/.no-print elements is empty, and print-to-PDF of a 1-line invoice
       is exactly 1 page. No PDF library is in the pinned dependency list (stack.md).
     Asset: A6 (print preview beside the on-screen invoice).
     Drafted by OMA. Nothing is posted for you. -->

# X — day 9

## Post — attach asset A6

```
I didn't build PDF export. I wrote a print stylesheet.

Under print media the invoice page has no nav, no buttons, no links. Ctrl+P
gives you the document.

A one-line invoice is one page. That was the entire requirement, and a PDF
library would have been a second renderer to keep in sync.
```

Fits 280 as written; recount if you edit.

## Asset

**A6** — the browser print preview and the on-screen invoice side by side. The
contrast is the post; a preview alone doesn't land.

## Before you publish

- Expect the reply "but users want a real PDF button". It's a fair reply and the
  honest answer is: browser print-to-PDF produces a real PDF, and a dedicated
  export is on the deferred list with a trigger written next to it — if print
  output turns out to be insufficient for actually sending to clients, it gets
  built. Say that rather than defending the absence.
- Don't claim it was less work unless it was. [[TODO: it probably was — but say
  "cheaper" only if you didn't sink a day into the stylesheet.]]
