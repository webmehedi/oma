# Screen — {{name}}

- **Route:** {{/path}}
- **Requirements:** REQ-{{ids}}
- **Mockup:** ../mockups/{{name}}.html
- **Personas:** {{who lands here and in what mood}}

## Purpose

<!-- One sentence: the single job of this screen. If it has two jobs, it's two screens. -->

## Layout

<!-- Regions top-to-bottom / responsive behavior. Reference components by their
     names from components.md — never invent a component here. -->

## States

Every screen ships all five. The mockup must demonstrate each (visible via a
state-switcher control or separate anchors).

| State | What the user sees | Notes |
|---|---|---|
| **Loading** | {{skeleton/spinner strategy}} | no layout shift on resolve |
| **Empty** | {{empty-state illustration + primary action}} | first-run experience |
| **Ideal** | {{the happy path with realistic data}} | |
| **Error** | {{what failed, what to do about it}} | retry affordance |
| **Partial** | {{some data, some failed / pagination edges}} | |

## Interactions & motion

<!-- Every animated element cites a token from motion-spec.md. No magic numbers. -->

| Element | Trigger | Motion token |
|---|---|---|
| {{element}} | {{enter/hover/scroll}} | `{{enter.default}}` |

## Responsive

| Breakpoint | Changes |
|---|---|
| < 640 | {{stack, hide, collapse what}} |
| 640–1024 | {{...}} |
| > 1024 | {{...}} |

## Accessibility

- Focus order: {{tab sequence through the primary flow}}
- Announcements: {{aria-live regions for async results}}
- Contrast: all text ≥ 4.5:1 against its background (tokens guarantee this)
- Reduced motion: {{what this screen does under prefers-reduced-motion}}
