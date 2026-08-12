<!-- Written by oma-archaeologist, FIRST, before anything is read for meaning.
     Lives at .oma/00-archaeology/baseline.md
     This file exists to answer one question later: "was it broken before?" -->

# Baseline — <project>

Recorded <UTC date> against commit `<short sha>`, before OMA changed anything.

## Verdict

<One line: green, or red with the count of failing stages. Say it plainly —
this is the single most consequential sentence in the brownfield pipeline.>

| Stage | Command | Exit | Verdict | Notes |
|---|---|---|---|---|
| install | `<cmd>` | | pass/fail | |
| typecheck | `<cmd>` | | pass/fail/n/a | |
| lint | `<cmd>` | | pass/fail/n/a | |
| build | `<cmd>` | | pass/fail | |
| test | `<cmd>` | | pass/fail/n/a | `<n>` passed, `<n>` failed, `<n>` skipped |

**These commands are the project's toolchain.** Every later OMA phase runs these
exact commands, not invented ones.

## If any stage is red

<For each failure: the real output, trimmed to the relevant lines; whether it
looks environmental (missing service, missing env var, wrong runtime version) or
genuine; and how long it appears to have been failing if git history shows.>

**These failures predate OMA.** They are not in scope to fix unless the user
asks. Recording them here is what makes that provable later.

## Environment

| | |
|---|---|
| Runtime | `<node/python/… version found>` vs `<version the project expects>` |
| Package manager | `<from the lockfile>` |
| Services required | `<database, cache, queue — and whether they were reachable>` |
| Env vars needed to run | `<names only, never values; which were absent>` |

## What was NOT run, and why

<Anything skipped: e2e needing a browser or a live service, tests requiring
credentials, a build needing a paid API key. An unrun stage is not a passing
stage, and this section is what keeps that distinction honest.>

## Test suite shape

| | |
|---|---|
| Framework | |
| Test files / cases | |
| Roughly what they cover | <the areas, not a coverage percentage unless a tool actually produced one> |
| Areas with no tests at all | <this is where refactor mode is dangerous> |

For `refactor` scope this section is load-bearing: the existing suite is the
contract that proves behavior didn't change, so its blind spots are precisely
where a refactor can break something invisibly.
