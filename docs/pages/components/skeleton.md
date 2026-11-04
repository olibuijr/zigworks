# Skeleton

Placeholder shapes with a soft shimmer while content loads: text lines, a block, an avatar circle, or an avatar next to lines. Pair it with `z-trigger="load"` so the real content replaces it as soon as it arrives.

```demo
skeleton
```

## Usage

```zig
// The page renders the skeleton; z.js loads the real content right away.
zw.view("<div z-get=\"/feed\" z-trigger=\"load\" z-swap=\"outer\">{s}</div>", .{ .s = ui.skeleton(.{ .lines = 4 }) })

ui.skeleton(.{ .shape = .block, .height = "180px", .label = "Loading photo" })
ui.skeleton(.{ .shape = .circle, .size = 56 })
ui.skeleton(.{ .shape = .media, .lines = 2 })          // list row: avatar + two lines
ui.skeleton(.{ .lines = 3, .last_width = 40, .shimmer = false })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `lines` | u8 | `3` | number of text lines (`.lines`, `.media`); the last line is shorter |
| `label` | string | `"Loading"` | announced to screen readers |
| `shape` | enum | `.lines` | `.lines`, `.block` (image or card), `.circle` (avatar), `.media` (avatar + lines) |
| `last_width` | u8 | `62` | width of the last line in percent |
| `height` | string | `"120px"` | CSS height of a `.block` |
| `size` | u16 | `40` | diameter in px of a `.circle` or of the `.media` avatar |
| `shimmer` | bool | `true` | false draws a still placeholder |

Make the skeleton roughly the size of the content it stands in for, so the page doesn't jump when the real content arrives.

With Reduce Motion, the shimmer stops and the shapes stay still.
