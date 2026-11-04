# Path bar

Where a page sits, as links from the top level down, like the macOS path control. The last item is the current page.

Here it is in a small Finder. Open a folder to go deeper and use the back button to climb out. Past four items, the middle folds into a "…" menu.

```demo
path
```

Each ancestor is a link with a `z` request, so a click opens that folder in place; without JavaScript the `href` takes over. The Up button does the same for the parent.

## Usage

```zig
ui.path(.{ .items = &.{
    .{ .label = "Projects", .href = "/projects" },
    .{ .label = "zigworks", .href = "/projects/zigworks" },
    .{ .label = "Settings" },
} })
```

Build the items from the request when the path is dynamic. The slice only has to live until the page is rendered:

```zig
var items: [3]ui.PathItem = undefined;
items[0] = .{ .label = "Home", .href = "/", .icon = "⌂" };
// ... one item per segment ...
items[n - 1].href = ""; // the current page
try c.page(ui.path(.{ .items = items[0..n], .max = 4 }));
```

To navigate without a full page load, give an item a `z` request. Keep the `href` as the fallback:

```zig
.{ .label = "Projects", .href = "/projects", .z = .{ .get = "/projects?partial", .target = "#content", .swap = .inner } },
```

## Separators and icons

`separator` picks the mark between items: a chevron (the default) or a slash. An `icon` adds a short glyph before the label.

```demo
path-variants
```

## Plain text, one item and long labels

An item with an empty `href` is shown as plain text, for a level that has no page of its own. A path with a single item is just the current page. Long labels are cut with an ellipsis, and `label` renames the `nav` for screen readers.

```demo
path-states
```

## Long paths

`max` caps how many items show. The first item and the last `max - 1` stay; the rest go into a "…" menu. Values below 2 count as 2, so the first and the current page always remain.

```demo
path-folding
```

```zig
ui.path(.{ .separator = .slash, .max = 3, .items = &.{
    .{ .label = "Home", .href = "/", .icon = "⌂" },
    .{ .label = "Projects", .href = "/projects" },
    .{ .label = "zigworks", .href = "/projects/zigworks" },
    .{ .label = "docs", .href = "/projects/zigworks/docs" },
    .{ .label = "Settings" },
} })
```

## With other components

A path bar sits above the content it names. This mail card uses a segmented control to switch mailbox: each change asks the server for the path bar and message list of that mailbox and swaps them in. The same response carries the unread badge as an out-of-band update.

```demo
path-compose
```

```zig
// GET /demo/path/mailbox?box=sent
fn mailbox(c: *zw.Ctx) !void {
    const items = [_]ui.PathItem{
        .{ .label = "Mail", .href = "/mail", .icon = "✉" },
        .{ .label = "Personal" },
        .{ .label = "Sent" },
    };
    try c.page(zw.view("{path}{list}{badge}", .{
        .path = ui.path(.{ .items = &items, .separator = .slash }),
        .list = messages,
        // Replaces the badge with this id, wherever it is on the page.
        .badge = ui.badge(.{ .id = "unread", .oob = true, .count = 0, .hide_zero = true }),
    }));
}
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `[]const ui.PathItem` | required | `label`, `href` and `icon`; the last item is the current page and is never a link |
| `label` | string | `"Path"` | accessible name of the `nav` |
| `separator` | `.chevron` or `.slash` | `.chevron` | the mark between items |
| `max` | usize | `0` | most items to show; a longer path keeps the first item and the last `max - 1` and folds the rest into a "…" menu. `0` shows everything, values below 2 count as 2 |

Each `ui.PathItem` has:

| Field | Type | Default | Notes |
|---|---|---|---|
| `label` | string | required | |
| `href` | string | `""` | empty shows the item as plain text instead of a link |
| `icon` | string | `""` | a short glyph such as `⌂` before the label; hidden from screen readers |
| `z` | `ui.Z` | `.{}` | z.js request fired when the link is clicked; keep `href` as the no-JS fallback. Ignored on the last item and on plain-text items |

## Notes

- The last item is marked `aria-current="page"` and is never a link, whatever its `href`.
- The "…" button opens a glass menu with the folded items; tapping anywhere outside closes it. It needs no JavaScript, and its accessible name says how many items it holds.
- An item's `z` makes a click update part of the page (the Finder demo swaps the folder). A bar that is itself inside the swapped region is replaced by the response, so return the new bar with it.
- An empty `items` renders nothing, so no empty landmark reaches screen readers. Build the slice with at least the current page when you want the bar shown.
- Every item with an `href` is a real link. An empty `href` is the only way to get a plain-text level; there is no inert link-styled item, because a link that goes nowhere should not look clickable.
- Long labels are shortened with an ellipsis. Links get a focus ring and are 44px tall on touch screens.
