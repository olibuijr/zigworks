# Badge

A small count or status. Tint it with a system color, fill it for a notification count, or shrink it to a bare status dot. With `oob`, a z.js response can update a badge anywhere on the page.

```demo
badge
```

## Usage

```zig
// In the page:
ui.badge(.{ .text = "3 left", .id = "remaining" })

// In a response, next to the swapped content:
ui.badge(.{ .text = "2 left", .id = "remaining", .oob = true })

// A notification count: shows "99+" above `max`, hides itself at 0.
ui.badge(.{ .count = unread, .tone = .red, .solid = true, .hide_zero = true, .id = "unread" })

// A status dot, named for screen readers:
ui.badge(.{ .dot = true, .tone = .green, .text = "Online" })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | `""` | label; the accessible name of a `dot` |
| `id` | string | `""` | needed for `oob` |
| `oob` | bool | `false` | replace the element with the same `id` |
| `tone` | `.gray` `.accent` `.red` `.green` `.orange` | `.gray` | system color of the tint (or of the fill with `solid`) |
| `size` | `.small` `.regular` | `.regular` | `.small` uses the footnote text style |
| `solid` | bool | `false` | filled with the tone and white text, like an app icon's notification badge |
| `dot` | bool | `false` | 8px (6px when `.small`) status dot, no text |
| `count` | `?u32` | `null` | number shown instead of `text` |
| `max` | u32 | `99` | with `count`: larger numbers read `99+` |
| `hide_zero` | bool | `false` | with `count`: hidden while 0, but still in the page so `oob` can bring it back |

## Notes

- A `dot` with no `text` is decorative and hidden from assistive technology; give it `text` when the color carries meaning, and never rely on color alone.
- `solid` uses white text on the system color. Prefer `.red` or `.accent` for small text; on `.green` and `.orange` keep the badge `.regular` or larger.
- Tints, fills and the Increase Contrast outline follow the light and dark appearance automatically.
