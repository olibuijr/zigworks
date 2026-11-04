# Badge

A small count or status. Tint it with a system color, fill it for a notification count, or shrink it to a bare status dot. With `oob`, a z.js response can update a badge anywhere on the page.

```demo
badge
```

## Variants and sizes

`tone` tints the badge with a system color. `solid` fills it, `size` shrinks it, and `dot` drops the text for a bare status dot. Each row below changes one prop across all five tones.

```demo
badge-variants
```

## Counts and status

Give `count` a number and the badge keeps it tidy: above `max` it reads `99+`, and `hide_zero` hides it at 0. A `dot` with `text` is named for screen readers; one without is decorative. A badge has no disabled or loading state: hide it or leave it out.

```demo
badge-states
```

## Update it from the server

Give the badge an `id`, and send it back with `oob` in any z.js response. It replaces the badge with the same `id`, wherever it is on the page. Here one form change updates the header badge and the Dock icon badge together. Check the messages, or mark them all read: the count drops, and `hide_zero` hides the badge at 0.

```demo
badge-live
```

The server keeps no state. The count comes from the checked boxes in the request.

```zig
fn mail(c: *zw.Ctx) !void {
    const unread = total - checked(c.body);
    try c.html("{head}{dock}", .{
        .head = ui.badge(.{ .id = "unread", .count = unread, .tone = .red, .solid = true, .hide_zero = true, .oob = true }),
        .dock = ui.badge(.{ .id = "dock", .count = unread, .tone = .red, .solid = true, .size = .small, .hide_zero = true, .oob = true }),
    });
}
```

## With other components

A badge sits next to an avatar, in a card header, or at the end of a list row. It labels the thing beside it and never carries an action itself.

```demo
badge-compose
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

// Smaller, tinted, with a lower cap:
ui.badge(.{ .count = 25, .max = 9, .tone = .accent, .size = .small })
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
