<!-- Pillar: Useful & unrelated
     Day 14 · Reddit · r/webdev
     Rests on: the actual print approach and the actual verification method from QA run-3
       (enumerate visible nav/button/a/.no-print under print media emulation; assert the
       set is empty; print-to-PDF and count pages).
     Asset: none. Reddit text post; the code blocks are the content.
     Drafted by OMA. Nothing is posted for you. -->

# Reddit — r/webdev — day 14

## Subreddit and its self-promotion rule

r/webdev restricts self-promotion hard: project showcases belong in the weekly
showcase thread, and a post whose payload is your own product gets removed as
promo regardless of how it's dressed.

**So this post does not link the product and does not name it in the body.** It
is a technique writeup that stands on its own. If someone asks what you built it
for, answer in the comments — that's a different thing from posting a link, and
it's the only version of this that's honest in this sub.

**[[TODO: re-read the r/webdev rules the morning you post.** They change, and I
can't verify the current text. If there's a "no blog-style posts" rule in force,
drop this row rather than argue it.**]]**

## Title

```
Replacing PDF export with a print stylesheet — and how to actually verify it worked
```

## Body

```
I needed documents (invoices) that people could save and send. The obvious move
is a PDF library. I went with a print stylesheet and the browser's own
print-to-PDF instead, and the part worth sharing isn't the CSS — it's how you
convince yourself it's right, because print is the one output nobody looks at
until a user does.

The approach:

- One class, .no-print, on everything chrome-ish, plus a @media print block that
  drops nav, buttons and links entirely rather than hiding them visually.
- The document container gets its own print-only sizing. Screen layout and print
  layout stop sharing constraints at that point, which is the whole benefit.
- No page-break rules until you've seen a real multi-page document. Guessing at
  break-inside on a table you haven't printed is how you end up with an orphaned
  total row.

The verification is the bit I hadn't seen written down anywhere:

1. Emulate print media in devtools (Rendering panel → "Emulate CSS media type:
   print"). Then, in the console, enumerate every nav / button / a / .no-print
   element and filter to the ones still visible:

   [...document.querySelectorAll('nav,button,a,.no-print')]
     .filter(el => el.offsetParent !== null || getComputedStyle(el).display !== 'none')

   The assertion is that this array is empty. "It looks clean in the preview" is
   not the same claim — a link with zero opacity is still in the printed
   document's structure, and it's still in the PDF's text layer.

2. Actually print to PDF and count the pages, for the smallest realistic
   document. Mine had to be exactly one page for a single-line document; that's
   a number you can assert against, unlike "looks fine".

3. Print the pathological one too. A hundred-line document spanning five pages
   isn't a bug, but you want to have seen it before someone else does.

What you give up: no server-side generation, no custom fonts you don't already
load, no control over headers/footers (the browser puts its own URL and date in
there unless the user turns it off, which is genuinely the weakest part of this
approach). What you get: one renderer instead of two, and the printed output can
never drift from the screen output, because it is the screen output.

Worth it for documents that are basically styled text. Not worth it if you need
byte-identical output across machines, or if the document has to be generated
without a browser in the loop.
```

## Before you publish

- No product link, no product name. If you can't resist adding one, don't post
  this row — a removed post and a promo flag cost more than a post is worth.
- The console snippet is the value here. Test it on your own page before posting
  so the first reply isn't someone correcting your JavaScript.
- The "what you give up" paragraph is what makes this credible rather than
  evangelism. Keep it.
