# Tooltip

A short glass hint that appears when the pointer rests on something, after the macOS half-second delay, or when keyboard focus enters it. It replaces the browser's `title` attribute, which zigworks never uses.

```demo
tooltip
```

## Usage

```zig
ui.tooltip(.{ .text = "More actions", .body = ui.button(.{ .label = "•••", .aria = "More actions", .variant = .plain }) })
```

With a shortcut, a detail line and a description link for screen readers:

```zig
ui.tooltip(.{
    .id = "save-tip", .text = "Save", .shortcut = "⌘S", .detail = "Writes the document to disk.", .side = .right,
    .body = ui.button(.{ .label = "Save", .variant = .primary, .describedby = "save-tip" }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string | required | a few words, no period |
| `side` | enum | `.above` | `.above`, `.below` (near the top of a page), `.left` or `.right` (near the window edges) |
| `body` | component | required | the thing being explained |
| `delay` | `u16` | `500` | milliseconds the pointer or focus rests before the tip shows; `0` shows it at once |
| `detail` | string | `""` | second line in secondary color, for a short explanation |
| `shortcut` | string | `""` | key hint after the text, such as `⌘S`; display only |
| `id` | string | `""` | id of the tip; pass the same string as the trigger's `describedby` (`ui.button`) so screen readers read it |

Tooltips explain; they must not hold the only copy of important information, since touch screens never show them.

## Notes

- Keyboard focus (Tab) shows the tip; a mouse click does not, so it never sticks after pressing a button.
- Hover tips only appear on devices with a real pointer; touch screens never show them.
- `.left` and `.right` tips are at most half the viewport wide, but do not place them against the window edge.
