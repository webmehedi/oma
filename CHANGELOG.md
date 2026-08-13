# Changelog

All notable changes to OMA. Versions follow [semver](https://semver.org/);
while the plugin is pre-1.0, minor versions may change behaviour.

## [0.6.3] — 2026-08-13

### Added
- **[GETTING-STARTED.md](GETTING-STARTED.md)** — the whole path from "I have an
  idea" to a running application, written for someone who has never opened a
  terminal. Checking for and installing Node, git and Claude Code per platform;
  installing OMA; writing a one-line idea that scopes well; the three-step loop,
  taught once and then applied; a walkthrough of all eight phases saying what
  each produces, **how much of your attention its review deserves**, and what to
  actually check; opening the mockups; running the finished app; deploying it
  yourself; the five things that will go wrong; a command cheat sheet; and a
  glossary of every term that isn't ordinary English.

  It sets expectations honestly rather than selling: you need a paid Claude
  account, a terminal, a real budget, and a few hours of attention at the gates —
  and OMA still can't decide what your product should be.

### Changed
- **README restructured as a landing page.** A hero with a start-here call to
  action, a three-panel "one sentence in, a tested application out" walkthrough,
  and a plain statement of what you're holding at the end. The 170-line
  installation section is now a two-minute path with the five other routes —
  in-session, desktop, team `settings.json`, updating, local development —
  folded into collapsible blocks, so the page scans instead of scrolling.
- FAQ gained the two questions a non-developer asks first: whether coding is
  required, and how long this actually takes. Requirements links to the
  getting-started check for each dependency.

## [0.6.2] — 2026-08-13

### Added
- **A real [Installation](README.md#-installation) section.** The old
  instructions were two slash commands with no context, which left two things
  unanswered: that OMA installs **straight from this GitHub repo** rather than
  through Anthropic's marketplace — in Claude Code a "marketplace" is just a git
  repo with a `.claude-plugin/marketplace.json` — and what to do when you don't
  have a terminal `/plugin` panel. Now covered: checking for and installing the
  Claude Code CLI itself, the interactive route, the `claude plugin …` shell
  route, verification, the **desktop app** (where the plugin browser only lists
  marketplaces you've already added, so the marketplace must be registered from a
  terminal first), a `.claude/settings.json` declaration for teams and cloud
  sessions, updating, local development and uninstalling.
- **Installation section in [TROUBLESHOOTING.md](TROUBLESHOOTING.md#installation)**,
  indexed by the exact error message: `claude: command not found`, `/plugin`
  unavailable, `Marketplace "oma" not found`, a stale catalog, and skills that
  install but don't appear.

### Changed
- Both quick start and installation now say to **restart the session after
  installing**. Hooks load at session start, so a mid-session install can leave
  contract freezing, command logging and the deploy guard inert — and because
  every hook fails open, that failure is silent.
- Requirements expanded: the account tiers Claude Code needs, and Windows stated
  as WSL-only rather than implied by "macOS or Linux".

### Fixed
- DESIGN.md named the marketplace source as `mehedi/oma`; the repo is
  `webmehedi/oma`.

## [0.6.1] — 2026-08-13

### Changed
- Documentation now states plainly that **Next.js is the only stack OMA has been
  validated on**. Added a `validated on: Next.js only` badge, a
  "what it's been proven on" section separating the stack-agnostic machinery from
  the Next.js-specific parts, and the same caveat in both plugin manifests, the
  design doc and the troubleshooting guide. No behaviour change — other stacks
  were always supported by design and always untested; the docs just said it too
  quietly.

## [0.6.0] — 2026-08-13 · M6: Distribution

The milestone that makes the project readable by someone who isn't its author.

### Added
- **[`examples/ledgerly/`](examples/ledgerly)** — the complete `.oma/` workspace
  from a real eight-phase run. 74 files, 28 agent dispatches, runnable mockups,
  and a guide to the five files worth reading first. It includes the failures:
  the QA report that caught nine tasks marked done against tests that never
  existed, a frozen contract changed properly through `/oma:change`, and a ship
  report naming every known issue.
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — built from failures actually hit
  during validation: agents dying mid-dispatch, phases stuck at `blocked`, an
  `npm install` that ran 58 minutes on a version that doesn't exist, pins that
  don't compose, hooks that appear inert.
- **`scripts/selftest.sh`** — 41 behavioral cases across all six hooks, plus a
  fail-open assertion for each. Every hook fails open by design, which means a
  broken hook is *silent*; this is what catches that.
- **CI for the plugin itself** — self-test, executable bits, shell syntax, JSON
  parsing, agent/skill frontmatter, playbook presence, and a check that the
  README version badge matches the manifest.

### Fixed
- **`session-start.sh` read `.oma/state.json` by relative path**, so it silently
  did nothing whenever the hook ran from anywhere but the project root. It now
  takes the directory from the hook payload's `cwd`, and emits its summary as
  `hookSpecificOutput.additionalContext` rather than bare stdout. Found by
  writing the self-test — it had never been exercised.

## [0.5.1] — 2026-08-13 · M5 validated

### Validated
- Brownfield reconstruction, scored against **ground truth**: Ledgerly was
  stripped of `.oma/`, `CLAUDE.md`, its README, git history and every agent
  attribution in a comment, then handed to the archaeologist as an unfamiliar
  codebase. Results: **17/17 API operations** (verified by calling them, not
  reading), **5/5 entities and 24/24 scalar fields**, **10/10 lockfile
  versions**, **0 source files modified**.

### Fixed
- **`08-ship` now verifies from a clean `git clone`**, not the working tree. The
  archaeologist discovered that Ledgerly did not work from a fresh clone — the
  generated database client is gitignored with no `postinstall`, so 91 of 191
  tests failed. The ship report had called it green, because it was green in a
  directory that already had the generated code.
- Roadmap reconciled: brownfield is M5, Distribution is M6. Brownfield was
  specified as post-v1 in DESIGN §18 and displaced the original M5.

## [0.5.0] — 2026-08-13 · M5: Brownfield

### Added
- **`oma-archaeologist`** — reconstructs stack, data model, API contract,
  conventions and ADRs from an existing repository, every artifact marked
  `inferred` with a confidence and a "how I know". Records a green/red baseline
  *before* touching anything, so pre-existing failures are never attributed to
  OMA and never silently repaired.
- **`00-archaeology` phase** and three scope modes: `extend`, `refactor`, `audit`.
- **`audit-guard` hook** — in `audit` scope, writes to anything outside `.oma/`
  are denied. Read-only becomes a property of the system rather than a promise.
- Inferred contracts cannot freeze until reviewed at a gate.

## [0.4.1] — 2026-08-13 · M4 validated

### Validated
- Phases 06–08 run end-to-end to a tagged `oma/ship`. The security agent's
  cross-user authorization probe ran 11 operations and measured a sign-in timing
  oracle. The review was then **mutation-tested** with an injected IDOR: located,
  graded `high`, reproduced and filed — along with the observation that the unit
  suite passed with the hole open.

### Fixed
- `state.security` was absent on projects initialized before 0.4.0 and the
  playbook dereferenced it unconditionally.
- **The Growth phase can introduce environment variables and nothing re-checked
  `env.template`**, which DevOps writes a phase earlier. SEO's
  `NEXT_PUBLIC_SITE_URL` went missing, shipping canonicals and sitemap URLs
  pointing at `localhost`. Caught by orchestrator verification, not by any agent.

## [0.4.0] — 2026-08-12 · M4: Ops & Growth

### Added
- **Five agents:** `oma-security`, `oma-devops`, `oma-seo`, `oma-marketer`,
  `oma-social`.
- **Three phases:** `06-devops` (security review → bounded harden loop → DevOps),
  `07-growth` (three agents in parallel over disjoint files), `08-ship`.
- **`/oma:ship`**, the `harden` task stage, `state.security`, `state.ship`, and
  six artifact templates.
- **`deploy-guard` hook** — production commands denied, `git push` and remote
  repo creation ask first. "OMA never deploys" became enforcement rather than a
  request.

## [0.3.1] — 2026-08-12 · M3 validated

### Validated
- Full pipeline on a real project: 28/28 tasks, 191 unit + 11 e2e tests, zero
  contract drift across 23 dispatches, zero territory violations during parallel
  build. The QA loop caught nine tasks marked `done` against vitest tests that
  did not exist, then mutation-tested its own suite.

### Fixed
- Build slices capped at ~2 tasks — a three-task slice killed the agent twice.
- `stack.md` added to the frozen contract registry.
- Architect must prove version pins compose in a throwaway install before
  freezing; "latest of each package" produced sets that don't work together.
- Playbook dispatch templates now state the agent's working directory.

## [0.3.0] — 2026-08-12 · M3: Build & QA

### Added
- `oma-frontend`, `oma-backend`, `oma-qa`; parallel build against frozen
  contracts; the bounded QA repair loop; `/oma:change` and `/oma:task`;
  `contract-guard` and `command-log` hooks.

## [0.2.0] — M2: Spec phases

### Added
- `oma-project-manager`, `oma-architect`, `oma-ux-designer`; Discovery,
  Architecture and Design phases; gates; contract freezing; the runnable
  HTML mockup pipeline.

## [0.1.0] — M1: Skeleton

### Added
- Plugin and marketplace manifests, `state.json` and handoff schemas,
  `/oma:init`, `/oma:status`, and the filesystem message bus.
