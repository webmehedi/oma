# Phase playbook: 02-architecture

Read by the orchestrator. Not read by agents.

## Preconditions

- Gate `01-discovery` is `approved`.
- No blocking `open_questions` addressed to `user`.

## Dispatch

One agent, foreground:

**oma-architect** — dispatch with:

```
You run in the project root (the directory containing .oma/). All `.oma/...`
paths in your role file are relative to it, and ${CLAUDE_PLUGIN_ROOT} is the
installed OMA plugin directory.

You are running Phase 02-architecture for this project.

Inputs (read in this order):
- .oma/state.json  (note stack.profile and stack.overrides)
- .oma/01-discovery/prd.md, scope.md
- Stack profile: ${CLAUDE_PLUGIN_ROOT}/stacks/{state.stack.profile}.md
  {if profile == "custom": "No profile — derive the stack from the user's
   overrides in state.json and interview conventions from the brief."}
- Your handoff inbox: .oma/log/handoffs.jsonl, records addressed to oma-architect
{if re-run: rejection corrections, as in discovery}

Templates: ${CLAUDE_PLUGIN_ROOT}/templates/adr.md for ADRs.

Outputs (all required):
- .oma/02-architecture/stack.md          (profile + overrides resolved; versions
                                          pinned AND proven to compose — see below)
- .oma/02-architecture/data-model.md
- .oma/02-architecture/api-contract.yaml (OpenAPI 3.1)
- .oma/02-architecture/adr/ADR-001-*.md  (one per irreversible decision, 3-7 total)

You MUST run the compatibility proof described in your role file before writing
final version pins. Unproven pins are not acceptable output.

Next handoff seq to use: {seq}
```

## The compatibility proof (why this phase runs a build)

Resolving "latest of each package" produces a set that frequently does **not
compose** — a framework's bundled toolchain lags its own peer dependencies, a
linter plugin doesn't support the newest compiler, a driver adapter trails its
client. None of this is discoverable by reading documentation or registry
metadata. It is only discoverable by installing.

Because `stack.md` freezes at this gate and every dev agent is forbidden from
deviating from it, an incompatible pin set poisons the entire Build phase and
can only be undone through `/oma:change`. So the Architect proves the pins in a
throwaway directory before committing them. See the agent's role file for the
procedure; your job here is to **verify the proof happened**.

## Verification

- [ ] All artifacts exist; `api-contract.yaml` parses as YAML.
- [ ] Every `must` REQ that implies server interaction maps to at least one path
      in the contract (spot-check 3 REQs; full traceability is QA's job later).
- [ ] The contract defines the error envelope and enumerates error codes.
- [ ] `data-model.md` covers every entity the contract's schemas reference.
- [ ] `stack.md` names exact package versions, not ranges.
- [ ] **`stack.md` contains a "Compatibility proof" section** recording the
      throwaway-install results: the commands run and their exit codes. Confirm
      those commands appear in `.oma/log/commands.jsonl` — an absent proof means
      the pins are unverified, which is a re-dispatch, not a warning.
- [ ] At least 3 ADRs exist.
- [ ] Handoff appended; promote questions; bump seq. Set `state.stack.resolved`.

## Gate presentation

1. The stack table from `stack.md` — one line per concern.
2. **The compatibility proof result** — install/typecheck/lint/build exit codes
   from the throwaway scaffold, and any version the Architect had to step back
   from latest to make the set compose (with which package forced it).
3. Entity list with relationships, one line each.
4. Endpoint list grouped by resource: method, path, one-line purpose.
5. ADR titles with their one-sentence decisions.
6. Assumptions from the handoff.
7. Warn plainly: "Approving this gate FREEZES stack.md and data-model.md. The
   API contract freezes at the next gate (Design), after UX has had the chance
   to surface screen needs that bend the API. After freezing, changes go through
   /oma:change with impact analysis."
8. Instruct: `/oma:gate approve` / `/oma:gate reject "why"`.
