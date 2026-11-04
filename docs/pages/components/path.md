# Path bar

Where a page sits, as links from the top level down, like the macOS path control. The last item is the current page.

```demo
path
```

## Usage

```zig
ui.path(.{ .items = &.{
    .{ .label = "Projects", .href = "/projects" },
    .{ .label = "zigworks", .href = "/projects/zigworks" },
    .{ .label = "Settings" },
} })
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `[]const ui.PathItem` | required | `label`, `href` and `icon`; the last item's `href` is not used |
| `label` | string | `"Path"` | accessible name of the `nav` |
| `separator` | `.chevron` or `.slash` | `.chevron` | the mark between items |
| `max` | usize | `0` | most items to show; a longer path keeps the first item and the last `max - 1` and folds the rest into a "…" menu. `0` shows everything |

Each `ui.PathItem` has:

| Field | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | |
| `href` | string | `""` | empty shows the item as plain text instead of a link |
| `icon` | string | `""` | a short glyph such as `⌂` before the label; hidden from screen readers |

## Long paths

```zig
ui.path(.{ .separator = .slash, .max = 3, .items = &.{
    .{ .label = "Home", .href = "/", .icon = "⌂" },
    .{ .label = "Projects", .href = "/projects" },
    .{ .label = "zigworks", .href = "/projects/zigworks" },
    .{ .label = "docs", .href = "/projects/zigworks/docs" },
    .{ .label = "Settings" },
} })
```

## Notes

- The last item is marked `aria-current="page"` and is never a link.
- The "…" button opens a glass menu with the folded items; tapping anywhere outside closes it. It needs no JavaScript, and its accessible name says how many items it holds.
- Long labels are shortened with an ellipsis. Links get a focus ring and are 44px tall on touch screens.
