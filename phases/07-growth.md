# Phase playbook: 07-growth

Read by the orchestrator. Not read by agents.

## Preconditions

- Gate `06-devops` is `approved`.
- No blocking `open_questions` for `user`.

## Why all three run in parallel

SEO, Marketer and Social touch disjoint files, and none of them depends on
another's output to do good work — they depend on the *same* upstream inputs
(PRD, personas, the built app). Running them concurrently is safe by
construction, and the only coordination they need is that their voices agree,
which they get by all reading `positioning.md`'s source material.

The one asymmetry: **SEO writes source code.** It is the only growth agent that
can break the build, which is why the verification step below runs the build
yourself rather than trusting three green summaries.

## Territory (disjoint by construction — check before dispatching)

| Agent | Owns |
|---|---|
| `oma-seo` | route metadata, `robots.ts`, `sitemap.ts`, JSON-LD in source · `.oma/07-growth/seo-brief.md` |
| `oma-marketer` | `.oma/07-growth/positioning.md`, `landing-copy.md`, `launch-plan.md` |
| `oma-social` | `.oma/07-growth/social-calendar.md`, `.oma/07-growth/posts/` |

No two agents may write the same file. If a change request would cross these
lines, it becomes a task, not an edit.

## The dispatch preamble (prepend to every agent prompt in this phase)

```
You run in the project root (the directory containing .oma/). All `.oma/...`
paths in your role file are relative to it, and ${CLAUDE_PLUGIN_ROOT} is the
installed OMA plugin directory.

You are running concurrently with the other Growth agents. Read whatever they
have already produced in .oma/07-growth/, but never wait for them and never
write their files. Append your handoff with a python3 append — never by reading
the log and rewriting it, or you will destroy a record written beside yours.
```

## Stage A — dispatch all three in one message

Three Agent calls in the SAME message, all `run_in_background: false`. Reserve
one handoff seq per agent (N+1 SEO, N+2 Marketer, N+3 Social) and state each
agent's seq in its prompt — concurrent appends must not collide on seq.

Per-agent additions to the preamble:

- **oma-seo** — `Brief template: none; structure per your role file. After your
  changes, run typecheck and build yourself and report exit codes. Your handoff
  seq: {N+1}.`
- **oma-marketer** — `Launch plan template: ${CLAUDE_PLUGIN_ROOT}/templates/launch-plan.md.
  Every feature claim must trace to a done task or verified REQ. Your handoff
  seq: {N+2}.`
- **oma-social** — `Calendar template: ${CLAUDE_PLUGIN_ROOT}/templates/social-calendar.md.
  Your handoff seq: {N+3}.`

If the project has no public web surface (an API, a CLI, an internal tool), say
so and dispatch only the agents that make sense — a social calendar for an
internal admin panel is waste, and running it anyway is how a tool loses the
user's trust. Note the skip in the gate summary.

## Verification — the build is yours to check

1. **Run typecheck and build yourself.** SEO changed source. Three passing
   self-reports do not substitute for one run of your own. If red: re-dispatch
   `oma-seo` scoped to the failure; twice red → revert its source changes
   (`git checkout` the metadata files), keep the brief, and report.
2. **Fetch and confirm.** Start the app, fetch two or three routes, and confirm
   the title, description, canonical and JSON-LD are actually in the returned
   HTML. Fetch `/robots.txt` and `/sitemap.xml`. Stop the server.
3. **Claim audit — do this, it's the point of the phase.** Pick three feature
   claims from `landing-copy.md` and trace each to a `done` task or a verified
   REQ in the QA coverage table. A claim that traces to nothing is a fabricated
   feature; send it back and say which one. Also confirm nothing on `scope.md`'s
   out-of-scope list is implied anywhere in the copy.
4. **No fabricated proof.** Grep the growth artifacts for testimonial-shaped
   content, user counts, revenue figures and star ratings. Anything unsourced
   must be a `[[TODO]]`, not a number.
5. **Calendar completeness:** every row in `social-calendar.md` has a real draft
   file behind it in `posts/`.
6. Reconcile all three handoffs; promote questions; set `handoff_seq` past the
   highest appended seq.

## Gate presentation

Set `awaiting_gate`. Show:

1. **What to look at first:** the landing copy's hero and the three
   differentiators — this is the product's public story and the user is the only
   one who can say whether it's true to their intent.
2. SEO: routes covered, what shipped, and **your own** build/typecheck exit codes.
3. The claim audit result: which three claims you traced, and to what.
4. Every `[[TODO]]` across the growth artifacts, grouped by file — these are the
   facts only the user has (price, contact, real quotes), and the copy is not
   usable until they're filled.
5. Social: post count, platform mix, and the assets the user must produce
   (screenshots, recordings) before day one.
6. Anything skipped and why.
7. `/oma:gate approve` / `/oma:gate reject "why"`.
