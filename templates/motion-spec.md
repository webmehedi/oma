# Motion spec — {{project_name}}

> FROZEN at the Design gate. Both the HTML mockups (Lenis + Motion) and the
> production build (Lenis + Framer Motion) read their values from this file.
> This is what keeps "the mockup felt great, the build feels wrong" from
> happening: motion is tokens, not per-implementation taste.

## Principles

1. Motion explains causality — things enter from where they came, exit toward
   where they went. Never decoration for its own sake.
2. Fast is polite. Nothing the user waits on runs longer than 320ms.
3. `prefers-reduced-motion: reduce` collapses all durations to 0ms and replaces
   transforms with opacity-only. **This is not optional and is never gated.**

## Duration & easing tokens

| Token | Duration | Easing | Use |
|---|---|---|---|
| `enter.fast` | 180ms | cubic-bezier(.2, 0, 0, 1) | tooltips, dropdowns, menu items |
| `enter.default` | 320ms | cubic-bezier(.2, 0, 0, 1) | cards, modals, panels |
| `exit.fast` | 120ms | cubic-bezier(.4, 0, 1, 1) | tooltip/menu dismissal |
| `exit.default` | 200ms | cubic-bezier(.4, 0, 1, 1) | modal/panel dismissal |
| `move.default` | 260ms | cubic-bezier(.4, 0, .2, 1) | layout shifts, reorder, tab indicator |
| `emphasis` | 400ms | spring(1, 80, 12) | success confirmation, single-use delight |

## Stagger tokens

| Token | Value | Use |
|---|---|---|
| `stagger.list` | 40ms | list/grid item cascade, max 8 items then batch |
| `stagger.hero` | 90ms | landing hero headline → subhead → CTA |

## Scroll tokens

| Token | Value | Use |
|---|---|---|
| `scroll.lerp` | 0.1 | Lenis smoothing factor |
| `scroll.reveal.offset` | 15% | viewport intersection before reveal fires |
| `scroll.reveal.distance` | 24px | translateY of scroll-in elements |

## Page transitions

<!-- View Transitions API where supported; hard cut fallback. Name the shared
     elements that morph between routes, if any. -->

## Per-screen choreography

<!-- Only screens that deviate from defaults. Everything else uses the tokens
     above with no further specification. -->
