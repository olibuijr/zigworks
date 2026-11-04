# Avatar

A person's picture, or their initials on a color chosen from their name. The same name always gets the same color, on every page. A picture that fails to load falls back to the initials.

```demo
avatar
```

## Usage

```zig
ui.avatar(.{ .name = "Ada Lovelace" })
ui.avatar(.{ .name = "Grace Hopper", .src = "/img/grace.jpg", .size = 44, .status = .online })

// An organization: rounded square, fixed color.
ui.avatar(.{ .name = "Zig Software Foundation", .shape = .rounded, .hue = 35 })

// A stack with an overflow chip:
zw.view("<div class=\"zw-avatars\">{a}{b}{c}</div>", .{
    .a = ui.avatar(.{ .name = "Ada Lovelace" }),
    .b = ui.avatar(.{ .name = "Grace Hopper" }),
    .c = ui.avatar(.{ .name = "More people", .more = 5 }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | initials, color and accessible label |
| `src` | string | `""` | image URL; initials when empty, while loading, and if it fails |
| `size` | u16 | `32` | diameter in px |
| `shape` | `.circle` `.rounded` | `.circle` | `.rounded` is a square with soft corners |
| `status` | `.none` `.online` `.away` `.busy` `.offline` | `.none` | presence dot on the bottom corner; added to the accessible label ("Ada, online") |
| `hue` | `?u16` | `null` | color hue 0-359 instead of the one derived from `name` |
| `more` | u16 | `0` | above 0, draws a "+N" overflow chip (label "N more"); `name` is ignored |

## Notes

- `<div class="zw-avatars">` overlaps its avatars and gives each a ring in the content color, so stacks read on any surface. Put the `more` chip last.
- Images load lazily. They are decorative: the name is the accessible label.
- The status dot also differs in shape (offline is an outline), so it is not color-only.
