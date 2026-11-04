# Liquid Glass

Every control in zigworks is made of Liquid Glass, Apple's material for the functional layer: buttons, pickers, the segmented pill, menus, sheets, the sidebar, search and dialogs. Glass bends what is behind it, catches light at its rim, and moves like liquid. Content (cards, lists, tables, text) stays opaque, as the Human Interface Guidelines ask.

```demo
setting
```

Press and hold a switch or drag the slider above. The knob swells into a clear drop that magnifies the track through it, then springs back when you let go.

## Refraction

glass.js gives each glass element an SVG displacement filter shaped like its own rounded rectangle. It is computed from a signed distance field, so a capsule and a square card bend correctly at their corners. The filter is used in `backdrop-filter`, so the edge of the glass bends the content behind it like a convex drop. Filters are cached by size, so fifty equal buttons share one.

Only Chromium supports SVG filters in `backdrop-filter`. Other browsers get the same tint, blur, rim and motion without the bending, and nothing breaks.

> [!NOTE]
> Chromium drops the lens while an element is scaled. Pressed knobs therefore grow by changing their size, and a pressed button's lens returns when it settles.

## Light

Each glass element has a specular rim (`--glass-rim`), a sheen across its upper half (`--glass-sheen`), and a soft highlight that follows the pointer (`--glass-glow`).

## Motion

Motion uses real spring curves, written as CSS `linear()` easings generated from stiffness and damping:

| Token | Overshoot | Used for |
|---|---|---|
| `--spring` with `--dur` | ~2% | menus, sheets, sidebars |
| `--spring-bouncy` with `--dur-bouncy` | ~20% | knobs, the segmented pill, pops: the water-drop feel |
| `--spring-snappy` with `--dur-snappy` | ~1.5% | following a finger or pointer |

Pressed buttons grow, stretch toward the pointer, and spring back with inertia when released. Menus and sheets spring out of their button and settle. New list rows drop in, deleted rows collapse, and a completed check pops.

Browsers without `linear()` fall back to overshooting `cubic-bezier` curves.

## Use it in your own markup

| Class | Gives |
|---|---|
| `zw-glass` | regular glass with refraction, rim, sheen and pointer light |
| `zw-glass--clear` | the clear variant, for glass over photos and video |
| `zw-press` | press, stretch and spring back |

```zig
try c.html("<nav class=\"toolbar zw-glass\">{b}</nav>", .{ .b = ui.button(.{ .label = "Share" }) });
```

Keep glass for controls and navigation that float above content, and avoid it on surfaces whose size animates: each new size would build a new lens.

## Accessibility

- **Reduce Transparency:** glass becomes opaque and refraction turns off.
- **Increase Contrast:** glass gets a solid edge.
- **Reduce Motion:** springs, pops and stretching turn off; state changes happen at once.
