# Personas — Ledgerly

Two personas. Both are solo; the difference that matters is invoice volume and
how much patience they bring to setup.

## Maya — full-time freelance designer (primary)

- **Context:** Freelancing is her whole income. 6–10 active clients, 5–15
  invoices a month, several outstanding at any time. Currently tracks this in a
  spreadsheet that has silently drifted from reality twice this year.
- **Job to be done:** Know exactly who owes her what, and produce a
  professional-looking invoice she can print or attach herself in under two
  minutes.
- **Friction tolerance:** Low for the core loop — she runs it several times a
  week and will abandon anything slower than her spreadsheet. High for one-time
  setup (entering her client list once is fine).
- **Device reality:** 13" laptop for all invoice creation; phone (375px-class)
  to check outstanding totals and mark an invoice paid when a payment
  notification arrives. Drives REQ-010's read/mark-paid mobile bar.
- **Design consequences:** Invoice form speed and correctness (REQ-003) and a
  trustworthy outstanding number (REQ-006) are what retain her. She will notice
  a wrong total once and never trust the dashboard again.

## Tomás — evenings-and-weekends moonlighter (secondary)

- **Context:** Has a day job; freelances 2–3 clients, invoices maybe once or
  twice a month. Weeks pass between sessions, so he re-learns the app every
  time he opens it.
- **Job to be done:** Get from a blank account to a first send-ready invoice
  without reading anything, and later find last month's invoice to check
  whether it was paid.
- **Friction tolerance:** Very low everywhere — any dead-end screen and he goes
  back to a Word template. He is the reason empty states must point to the next
  step (REQ-009) and the invoice list must filter to unpaid in one action
  (REQ-007).
- **Device reality:** Desktop browser only; mobile is irrelevant to him.
- **Design consequences:** Navigation must be self-evident after a month away:
  defaults filled in (issue date = today), one obvious primary action per
  screen, no state he can get stuck in.
