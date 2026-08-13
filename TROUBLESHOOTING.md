# Troubleshooting

[Installation](#installation) covers getting the plugin loaded, indexed by the
exact error message. Everything after it is a failure mode **hit during a real
validation run** — none is hypothetical, and most are *normal at this scale*
rather than signs something is broken.

The first rule once a project exists: **run `/oma:status`.** All state is on
disk, nothing lives in the conversation, and status reconstructs the whole
picture — including the exact next command.

---

## Installation

### `claude: command not found`

OMA is a Claude Code plugin, so the Claude Code CLI has to exist first:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

That's macOS, Linux and WSL. On Windows PowerShell it's
`irm https://claude.ai/install.ps1 | iex`. Then `claude --version` should print a
version, and `claude doctor` diagnoses anything else. The full table of install
methods is in [Installation](README.md#-installation).

Note that **having the desktop app is not the same as having the CLI on your
`PATH`** — and adding a third-party marketplace is a CLI step.

### `/plugin` isn't available in this environment

You're in the desktop app or a cloud session, where `/plugin` would open a
terminal-only panel. Run the two commands from a terminal instead — the desktop
app's own integrated terminal counts:

```bash
claude plugin marketplace add webmehedi/oma
claude plugin install oma@oma
```

Then restart the app. For **cloud sessions**, plugins can't be installed this way
at all; declare OMA in the repository's `.claude/settings.json` under
`extraKnownMarketplaces` + `enabledPlugins` instead — the JSON is in
[Installation](README.md#without-a-terminal-or-for-a-whole-team).

### `Marketplace "oma" not found`

`/plugin install oma@oma` was run before `/plugin marketplace add webmehedi/oma`.
Add the marketplace first — that command is what tells Claude Code where a plugin
called `oma` comes from.

If the `add` itself failed: the repo is public, so this is almost always network
or git. Confirm reachability with `git clone https://github.com/webmehedi/oma`
from the same machine, then point Claude Code at the local clone instead:
`claude plugin marketplace add /path/to/oma`.

### `Plugin "oma" not found in marketplace`

Your cached copy of the catalog is stale — third-party marketplaces don't
auto-update by default:

```bash
claude plugin marketplace update oma
```

Then retry the install.

### It installed, but `/oma:init` doesn't exist

In order:

1. `claude plugin list` — is `oma@oma` present *and* enabled?
2. `/reload-plugins` (add `--force` if it warns about the prompt cache).
3. Restart the session. **Do this before starting a project regardless** — see
   the next entry.
4. Still nothing: `rm -rf ~/.claude/plugins/cache`, restart, reinstall.

Plugin skills are namespaced by plugin name, so the command is `/oma:init` —
never a bare `/init`.

### Installed mid-session and the hooks aren't firing

Expected. Hooks are loaded at **session start**, so a plugin installed partway
through a session may have its skills active while its hooks are not. Restart
before running a phase. Details in
[Hooks don't seem to be doing anything](#hooks-dont-seem-to-be-doing-anything).

---

## An agent died mid-dispatch

**Symptom:** an agent stops with an API error, a connection close, or a stall
watchdog. No handoff record was written.

**This is routine.** Three agents died across one Build phase alone. It is not a
sign of a broken project.

**What to do:** nothing dramatic. The work survives on disk — an agent that died
after writing six files still wrote six files. `/oma:run` again; the orchestrator
diagnoses which artifacts exist and re-dispatches **scoped to the gap only**.

**What not to do:** re-run the whole slice. A dead agent's replacement that
redoes finished work usually dies the same way, because the slice was too big to
begin with — which is the actual cause.

**Why it happens:** context exhaustion. A slice of three heavy build tasks —
scaffold, install dependencies, write a schema, generate a migration — will
exhaust an agent before it can hand off. OMA caps build slices at ~2 tasks for
exactly this reason. If you see repeated deaths in one phase, the slices are
still too big; `/oma:task` to split them.

---

## A phase is stuck at `blocked`

**Symptom:** `/oma:status` shows `blocked` and `/oma:run` won't advance.

A phase blocks for one of four reasons, and status names which:

| Cause | Fix |
|---|---|
| A blocking question for you | Answer it. The system refuses to build on a guess — that's the feature working. |
| QA hit its 3-iteration cap still red | Read the run reports. Then either fix manually, or `/oma:gate approve` with notes to accept specific failures as known issues, or `/oma:run` to re-enter with the counter reset. |
| Security hit its 2-round cap with critical/high open | Same choice, higher stakes. Approving records each finding by name in the gate notes and carries it into the ship report. |
| Required artifacts missing after two dispatches | Something structural is wrong — usually a contradiction between the PRD and the contract. Read the last handoff's `blocked_on`. |

Approving over a known failure is always your right. It is never silent: the
task moves to `wontfix` with your gate notes as the recorded reason.

---

## A frozen contract needs to change

**Symptom:** an agent stops and reports a `contract_changes` request, or a hook
denied a write with *"… is the FROZEN 'api' contract."*

**The hook is working.** Frozen contracts are what let Frontend and Backend build
in parallel without drifting apart.

```
/oma:change "the invoice total needs to hold values above 2^31"
```

That runs impact analysis first — which tasks, files and agents are affected —
then asks you to decide. On approval it unfreezes, lets the owning agent make a
surgical edit, writes an ADR, re-freezes at a bumped version with a new hash, and
files rework tasks.

**Never edit a frozen contract by hand.** The hash in `state.json` won't match,
and the mismatch will surface later as a confusing failure.

---

## Coming back after a week away

Nothing is lost. Nothing lived in the conversation.

```
cd my-project
claude
/oma:status
```

`/clear` between phases is *recommended*, not merely safe. Fresh context each
phase is how a project larger than one context window stays coherent.

---

## The build is red and I don't think OMA broke it

In brownfield mode, check `.oma/00-archaeology/baseline.md`. The archaeologist
records install/typecheck/lint/build/test results **before touching anything**,
precisely so this question has an answer. If it was red on arrival, that's
recorded, and OMA will not have silently "fixed" it.

In greenfield, check `.oma/05-qa/reports/` for the last green run and
`git log --oneline` for what landed since. Every phase is tagged
(`oma/gate-04-build`), so `git diff oma/gate-04-build` shows exactly what changed.

---

## "It passes here" but a fresh clone fails

Usually a generated artifact that is gitignored with no step to recreate it — a
database client, a codegen output. The working directory has it; a clone doesn't.

This exact defect survived a full greenfield run undetected. `08-ship` now
verifies from a clean `git clone`, but if you're shipping mid-pipeline, check it
yourself:

```bash
git clone . /tmp/check && cd /tmp/check && npm ci && npm test
```

---

## `npm install` has been running for an hour

**Kill it.** This is almost always a version that doesn't exist, sending the
resolver into an ERESOLVE loop. Real case: `eslint@9.42.0` was pinned, doesn't
exist, and two installs deadlocked for 58 minutes.

```bash
pkill -f "npm install"; rm -rf node_modules package-lock.json
```

Then check `stack.md` pins against reality: `npm view eslint versions --json`.

**Prevention:** the Architect is required to *prove* its pin set in a throwaway
install before `stack.md` freezes. If pins reach Build unproven, the Architecture
gate was approved too fast.

---

## The stack pins don't compose

**Symptom:** everything installs, then lint or typecheck fails with an internal
error from a plugin — `contextOrFilename.getFilename is not a function`, or
*"typescript-eslint does not support TS 7.0"*.

**Cause:** pinning the latest of *each* package rather than the latest set that
*composes*. Both examples above are real.

**Fix:** `/oma:change` against `stack`, and downgrade to the latest version that
works together. The framework's own toolchain pins outrank independently-latest
sub-packages.

---

## Hooks don't seem to be doing anything

Check the plugin is actually installed — `claude plugin list`, or `/plugin` if
your environment has it. Hooks load at **session start**, so a plugin installed
mid-session isn't active until you restart.

Then check the preconditions each hook has:

| Hook | Silent when |
|---|---|
| contract-guard | no `.oma/state.json`, or nothing frozen yet |
| command-log | `.oma/log/` doesn't exist (created by `/oma:init`) |
| deploy-guard | not inside an OMA project |
| audit-guard | `brownfield.scope` is not `audit` |

Every hook **fails open** by design: any internal error exits 0 and allows the
action, so a hook bug can never block your work. The cost is that a broken hook
is silent. To verify they're alive:

```bash
bash scripts/selftest.sh
```

`.oma/log/commands.jsonl` filling up is the simplest proof the wiring is live.

---

## An agent wrote outside its territory

**Symptom:** the Frontend agent edited server code, or two agents touched the
same file.

Territory rules are prompt-level, not hook-enforced (except in brownfield
`audit`, where all source writes are denied). Parallel dispatch is only safe
because slices are disjoint *by construction*.

If it happens: `git diff` the offending file, revert what shouldn't be there, and
check whether Stage A assigned an owner wrongly — a task whose title crosses
boundaries ("wire the invoice form to the API") is the usual culprit. Split it.

---

## Costs are higher than expected

OMA is thorough, not cheap. A full eight-phase run is dozens of agent dispatches.

Levers, in order of effect:

1. **Stop early at a gate.** The gates exist so a misread requirement costs one
   phase instead of a whole build. Reading the Discovery gate carefully is the
   highest-leverage minute you will spend.
2. **`/clear` between phases.** Smaller context per dispatch.
3. **Keep scope small.** Every `could`-priority requirement in the PRD becomes
   build tasks, tests, and QA iterations. Cut them in Discovery, not Build.
4. **Don't re-run phases speculatively.** `/oma:phase` re-runs cost as much as
   the original.

---

## I'm not using Next.js and things are odd

Expected, and worth saying plainly: **Next.js + TypeScript + Prisma is the only
stack OMA has been validated on.**

The phase machinery is stack-agnostic — gates, frozen contracts, the handoff bus,
the QA loop. What is written around Next.js: the default stack profile, the
mockup pipeline's Framer Motion translation, the SEO agent's metadata idioms
(`metadata` exports, `robots.ts`, `sitemap.ts`), and the DevOps container and CI
templates.

If you're on another stack, expect Discovery and Architecture to work well, and
expect friction in Design, Build and DevOps. Overriding `stacks/web-app-default.md`
at intake makes the Architect interview you instead of assuming. Please
[open an issue](../../issues) with what broke — that's the most useful
contribution to this project right now.

## Still stuck

Open an issue with `/oma:status` output, the tail of
`.oma/log/handoffs.jsonl`, and which phase you're in. Those three make almost any
OMA problem diagnosable, because they are the entire state of the system.
