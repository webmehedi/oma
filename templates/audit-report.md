<!-- Written by the orchestrator at 08-ship when brownfield scope is `audit`.
     Lives at .oma/08-ship/audit-report.md
     An audit changes nothing. This is a handover, not a work log. Every
     finding cites evidence; nothing here is a guess presented as a fact. -->

# Audit report — <project>

Audited <UTC date> against commit `<short sha>`. **No source code was changed.**

## Verdict

<Two or three sentences a decision-maker can act on: what state this codebase is
in, the one thing most worth fixing, and whether it is safe to keep building on.
Be direct. An audit that hedges everything is worth nothing.>

## Health at a glance

| Stage | On arrival (baseline) | Now | |
|---|---|---|---|
| install | | | unchanged — nothing was modified |
| typecheck | | | |
| lint | | | |
| build | | | |
| test | | | `<n>` passed / `<n>` failed |

<If anything is red, restate plainly that it was red before this audit began.>

## Findings

Ordered by priority. Priority = impact × likelihood, not effort.

### F-001 · <critical|high|medium|low> · <one-line title>

- **Where:** `path/to/file.ts:42` (and `<n>` similar sites)
- **What's wrong:** <the specific defect, not a category>
- **Why it matters:** <the concrete consequence — data loss, outage, a class of
  bug that will recur, an hour a week of someone's time>
- **Evidence:** <command output, the code, or the reproduction>
- **Fix:** <the specific change>
- **Effort:** <hours or days, honestly — an estimate you'd defend>
- **Filed as:** `T-###`

<Repeat. Group trivially similar findings into one with a site count; do not
inflate the list by splitting one problem into eight.>

## What is sound

The parts that are well built, named specifically. This is not padding: a
maintainer needs to know what *not* to rewrite, and an audit that lists only
problems reads as though nothing here works, which is almost never true.

| Area | Assessment |
|---|---|
| | |

## Security posture

From `.oma/06-devops/security-review.md`: `<n>` critical, `<n>` high, `<n>`
medium, `<n>` low. <The one that matters most, in a sentence.> Dependency audit:
`<result>`.

## Architecture and conventions

- **Coherence:** <does the codebase follow its own patterns, and where does it
  contradict itself — from `conventions.md`>
- **Test coverage shape:** <what is tested, what is not; the untested areas that
  carry the most risk>
- **Portability / lock-in:** <what would be hard to change and why>
- **Dependencies:** <unmaintained, majors behind, or duplicated packages — as facts>

## The backlog

`<n>` tasks in `.oma/04-build/tasks.json`, each citing evidence in this report.
**Nobody has been dispatched to do any of them.** To act on them, re-initialize
with scope `extend` (to add) or `refactor` (to restructure with behavior frozen),
or work through them by hand.

## If you fix three things

1. <the highest-value fix, with the reason it is first>
2. <second>
3. <third>

## Scope of this audit

What was examined: <directories, layers>. What was **not**: <infrastructure,
third-party services, anything requiring credentials, production data, load and
performance under real traffic>. An audit's limits are part of its result.
