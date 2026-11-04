# Skeleton

Placeholder shapes with a soft shimmer while content loads: text lines, a block, an avatar circle, or an avatar next to lines. Pair it with `z-trigger="load"` so the real content replaces it as soon as it arrives.

The inbox below renders as skeletons, asks the server for its messages the moment it is on the page, and swaps them in. Press Refresh to watch it load again.

```demo
skeleton
```

## Usage

```zig
// The page renders the skeleton; z.js loads the real content right away.
ui.skeleton(.{ .lines = 4, .z = .{ .get = "/feed", .trigger = "load", .swap = .outer } })

ui.skeleton(.{ .shape = .block, .height = "180px", .label = "Loading photo" })
ui.skeleton(.{ .shape = .circle, .size = 56 })
ui.skeleton(.{ .shape = .media, .lines = 2 })          // list row: avatar + two lines
ui.skeleton(.{ .lines = 3, .last_width = 40, .shimmer = false })
ui.skeleton(.{ .lines = 2, .line_height = 17, .gap = 5 }) // match a 17px headline
```

## Shapes and sizes

Each card shows the props that draw its skeleton. The last line of a `.lines` or `.media` skeleton is shorter, so the text looks like text. A single line fills the whole width. `.line_height` and `.gap` set the bar height and the space between lines, so they can match the text that replaces them.

```demo
skeleton-shapes
```

## States

A skeleton is shown while the content loads, then replaced by the content or by an empty state. Pick a state to see all four. The shimmer is on by default; `.shimmer = false` draws the same shapes without motion, for waits that may be long or for a quiet interface. With Reduce Motion, the shimmer stops on its own.

```demo
skeleton-states
```

## In a notes app

A skeleton can stand in for any part of the page. Choose a note: the pane shows a media skeleton for the header and four lines for the text, then loads the note. The list, avatar and badge are ordinary components around it.

```demo
skeleton-notes
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `lines` | u8 | `3` | number of text lines (`.lines`, `.media`); the last line is shorter |
| `label` | string | `"Loading"` | announced to screen readers; say what is loading |
| `shape` | enum | `.lines` | `.lines`, `.block` (image or card), `.circle` (avatar), `.media` (avatar + lines) |
| `last_width` | u8 | `62` | width of the last line in percent (`.lines`, `.media`) |
| `height` | string | `"120px"` | CSS height of a `.block` |
| `size` | u16 | `40` | diameter in px of a `.circle` or of the `.media` avatar |
| `line_height` | u8 | `12` | height in px of one text line (`.lines`, `.media`) |
| `gap` | u8 | `9` | space in px between text lines (`.lines`, `.media`) |
| `z` | Z | none | z.js attributes; `.{ .get = url, .trigger = "load", .swap = .outer }` loads the content on mount |
| `shimmer` | bool | `true` | false draws a still placeholder |

Make the skeleton roughly the size of the content it stands in for, so the page doesn't jump when the real content arrives.

A skeleton is `role="status"` with `aria-busy="true"`, so screen readers announce its `label`. Give each one a label that names what is loading.

## Notes

- Put `.z` on the skeleton to load content on mount. A skeleton with `z` is not dimmed while the request runs (other `z-get` elements are). Use `.swap = .outer` to replace the skeleton itself, or a `.target` to fill another element. With several skeletons for one request (as in the inbox and notes demos), put `.z` on one of them and target the container, or wrap them all in a `display:contents` element that carries the `z-*` attributes.
- A `.circle` is `size` px wide and never stretches or shrinks, also inside a flex row. Only `.lines` and `.block` fill their container's width; a skeleton has no `max-width` prop, so narrow it with a wrapper.
- Line height is set in whole px (`.line_height`), not in `em`; for text that scales with the user's font size, use a `.block` with a CSS `height` such as `"1.2em"`.
