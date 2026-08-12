# Success metrics — Ledgerly v1

Five metrics. Each has a numeric target and a concrete way to measure it in the
built app. These are v1 (local demo) metrics — measured by walkthrough and
instrumented timing, not production analytics.

## 1. Time to first send-ready invoice

- **Target:** < 3 minutes from completed sign-up to viewing a send-ready
  invoice (REQ-004 view), including creating one client and a 2-line-item
  invoice.
- **Measured by:** Stopwatch walkthrough on a fresh account, performed at QA;
  repeat 3 times, all runs must beat the target.
- **Requirements exercised:** REQ-001, REQ-002, REQ-003, REQ-004.

## 2. Core-loop interaction cost

- **Target:** Marking an existing invoice paid takes ≤ 2 clicks from the
  dashboard (dashboard → invoice row/action → paid) and completes without a
  full page reload.
- **Measured by:** Click-count walkthrough on the built app.
- **Requirements exercised:** REQ-005, REQ-006.

## 3. Dashboard correctness

- **Target:** 0 discrepancies between dashboard totals and the underlying
  invoice data across a seeded 25-invoice fixture (mixed paid/unpaid, including
  edits and a deletion).
- **Measured by:** Automated test comparing dashboard-rendered totals to a
  direct sum over the database fixture.
- **Requirements exercised:** REQ-003, REQ-005, REQ-006, REQ-008.

## 4. Print fidelity of the send-ready view

- **Target:** 100% of a 5-invoice sample prints (print-to-PDF) as one page per
  invoice with no navigation chrome and no clipped line items, at default
  browser print settings.
- **Measured by:** Manual print-preview check of 5 fixture invoices, including
  one with 15 line items.
- **Requirements exercised:** REQ-004.

## 5. Perceived responsiveness of core pages

- **Target:** Dashboard, invoice list (100-invoice fixture), and invoice detail
  each reach a rendered, interactive state in < 1 second on a local dev
  machine.
- **Measured by:** Browser devtools performance timing against the seeded
  fixture, 3 runs per page, median under target.
- **Requirements exercised:** REQ-006, REQ-007.
