# Phase playbook: 03-design

Read by the orchestrator. Not read by agents.

## Preconditions

- Gate `02-architecture` is `approved`.
- No blocking `open_questions` addressed to `user`.

## Dispatch

One agent, foreground. This is the longest-running spec-phase dispatch — the
mockups are real deliverables, not sketches.

**oma-ux-designer** — dispatch with:

```
You run in the project root (the directory containing .oma/). All `.oma/...`
paths in your role file are relative to it, and ${CLAUDE_PLUGIN_ROOT} is the
installed OMA plugin directory.

You are running Phase 03-design for this project.

Inputs (read in this order):
- .oma/state.json
- .oma/01-discovery/prd.md, personas.md
- .oma/02-architecture/api-contract.yaml, data-model.md, stack.md
- Your handoff inbox: .oma/log/handoffs.jsonl, records addressed to oma-ux-designer
{if re-run: rejection corrections}

Templates:
- ${CLAUDE_PLUGIN_ROOT}/templates/motion-spec.md
- ${CLAUDE_PLUGIN_ROOT}/templates/screen.md

Outputs (all required):
- .oma/03-design/design-system.md
- .oma/03-design/tokens.json
- .oma/03-design/motion-spec.md
- .oma/03-design/components.md
- .oma/03-design/screens/<screen>.md      (one per screen)
- .oma/03-design/mockups/                 (runnable HTML/CSS — see your agent
                                           definition for the mockup standard)

Screen inventory: derive it from the PRD — every must-REQ's user-facing surface
gets a screen. If the count exceeds 9, propose the set and flag a non-blocking
question rather than building all of them.

If a screen genuinely needs an API shape the contract lacks, do NOT design
around it silently — record it in contract_changes on your handoff. This gate
is the last cheap moment to fix the API.

Next handoff seq to use: {seq}
```

## Verification

- [ ] `tokens.json` parses; includes color (light + dark), spacing, radius, type scale.
- [ ] `motion-spec.md` exists with the token tables filled.
- [ ] Every file in `screens/` has a corresponding `mockups/<screen>.html`.
- [ ] `mockups/index.html` exists and links every screen.
- [ ] `mockups/tokens.css` exists (generated from tokens.json).
- [ ] Mockup HTML contains no lorem ipsum (grep for it) and references tokens.css.
- [ ] Handoff appended; check `contract_changes` — if non-empty, surface these
      to the user FIRST, before the gate; they may change the architecture.
- [ ] Promote questions; bump seq.

## Gate presentation

1. **Lead with the mockups**: tell the user to run
   `python3 -m http.server 4173 -d .oma/03-design/mockups` and open
   http://localhost:4173 — or offer to open it in the browser pane for them.
2. Screen list with the REQ each serves.
3. The type scale and color palette summary from design-system.md.
4. Any contract_changes (already surfaced above, restate the decision needed).
5. Assumptions from the handoff.
6. Warn plainly: "Approving this gate FREEZES api-contract.yaml, data-model.md,
   tokens.json and motion-spec.md. After this, changes go through /oma:change
   with impact analysis. Click through every mockup before approving."
7. Instruct: `/oma:gate approve` / `/oma:gate reject "why"`.
