<!-- Maintained by OMA. Rewritten at every phase gate. Edit .oma/ artifacts, not this file. -->
# {{project_name}}

{{one_liner}}

## Stack

{{stack_summary_one_line}}
Full detail: .oma/02-architecture/stack.md — do not deviate from it. Do not
introduce frameworks, ORMs, or libraries it doesn't name.

## Conventions

{{conventions_bullets}}

## Current state

- Phase: {{phase_current}} ({{phase_status}})
- Contracts: {{contracts_summary}}
- Read .oma/state.json before doing anything. Never edit it by hand — use /oma:* skills.
- Inter-agent communication happens through .oma/log/handoffs.jsonl, not conversation.

## For any agent working here

1. Read .oma/state.json first.
2. Read .oma/02-architecture/stack.md if it exists.
3. Read your handoff inbox (records addressed to you in .oma/log/handoffs.jsonl).
4. Frozen contracts are read-only. Request changes via your handoff's contract_changes field.
