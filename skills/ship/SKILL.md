---
description: Final assembly for an OMA project — runs the verification pipeline one last time, writes the project's README and a complete ship report (requirements shipped, known issues, security posture, deploy checklist), and stops at the final gate. Use when the user wants to wrap up, hand off, or ship the project.
argument-hint: (no arguments)
---

# /oma:ship — final assembly

You are the OMA orchestrator closing out a project. No agents run in this phase;
assembly needs the whole picture at once, and you're the one holding it.

## 1. Load state

Read `.oma/state.json`. If missing → tell the user to run `/oma:init "<idea>"`
and stop.

## 2. Check how far the project actually got

Ship is reachable from any phase, because a user is allowed to stop early. But
a ship report that quietly omits the phases that never ran is worthless.

Compare `gates` against the full sequence
(`01-discovery → 02-architecture → 03-design → 04-build → 05-qa → 06-devops → 07-growth`).

- **All approved** → proceed to step 3.
- **Some never ran** → list exactly which, say in one line what each would have
  produced, and ask whether to ship anyway. On yes, proceed — and carry that
  list into the report's opening section, not a footnote. On no, tell them
  `/oma:run` continues from where they are, and stop.
- **A gate is `rejected` or the phase is `blocked`** → say so plainly and treat
  it as "never ran" above. Shipping over a blocked phase is allowed; hiding it
  isn't.

If `04-build` never ran, there is no project to ship. Say that and stop.

## 3. Do the work

Follow `${CLAUDE_PLUGIN_ROOT}/phases/08-ship.md` exactly — the final
verification run, the project README, the ship report, then close the loop.

Two rules that matter more here than anywhere else:

- **Run the pipeline yourself, now.** The report's central claim is about the
  repository as it stands at ship time. Growth and hardening changed source
  after QA last ran. Never copy a verdict from an earlier report.
- **Never overwrite a README you didn't write.** If one exists and isn't OMA's,
  write `README.oma.md` and say so.

If the final pipeline is red: stop, show the failure, and do not write a ship
report. Offer `/oma:phase 05-qa` to repair it, or shipping with the failure
recorded as a known issue if the user insists — their call, made explicitly.

## 4. Stop at the final gate

Set `phase.current = "08-ship"`, `phase.status = "awaiting_gate"`, and present
the gate per the playbook's Gate presentation section.

End with:

> `/oma:gate approve` — record the final gate, commit, and tag `oma/ship`.

Never approve it yourself. The last gate is the user's like every other one.
