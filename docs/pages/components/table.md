# Table

A simple data table with a header row. Cells are plain strings and escaped. Wide tables scroll inside their own frame. Use it for read-only data such as a Finder-style file list; for rows with controls, use a [list](/components/list).

```demo
table
```

## Usage

```zig
ui.table(.{
    .head = &.{ "Method", "Path" },
    .rows = &.{
        &.{ "GET", "/" },
        &.{ "POST", "/todos" },
    },
})
```

## Variants

Every option is a plain bool or a per-column list. `.striped` shades every other row, `.compact` tightens the padding, `.row_header` turns the first column into bold row names, and `.aligns` and `.caption` set the column alignment and the title.

```demo
table-variants
```

```zig
ui.table(.{
    .caption = "Service status",
    .head = &.{ "Region", "Status", "Latency" },
    .aligns = &.{ .left, .center, .right },
    .rows = &.{ &.{ "Iceland", "Online", "12 ms" }, &.{ "Frankfurt", "Online", "48 ms" } },
    .striped = true,
    .row_header = true,
})
```

## States

With no rows, `.empty` shows a message across the table. When the table is wider than its container, the frame scrolls sideways and can be focused with the keyboard.

```demo
table-states
```

```zig
ui.table(.{ .head = &.{ "Name", "Role" }, .rows = &.{}, .empty = "No members yet" })
```

## Adding and clearing rows

A table has no state of its own. To change it, render the new table on the server and swap it in. Here the buttons carry the row count in their URL, so the server keeps nothing. Clear the log to see the empty state again.

```demo
table-live
```

```zig
ui.button(.{
    .label = "Add Reading",
    .variant = .primary,
    .z = .{ .get = "/demo/table/log?n=3", .target = "#log", .swap = .inner },
})
```

## Sorting and filtering

Two segmented controls sit in one form. When either changes, the form sends both values and the server returns the sorted, filtered table. Pick Archives to see the empty message.

```demo
table-files
```

```zig
fn files(c: *zw.Ctx) !void {
    // Build the rows from the query, in the request arena.
    const rows = try c.arena.alloc([]const []const u8, count);
    // ... fill rows ...
    try c.page(ui.table(.{ .head = &.{ "Name", "Size" }, .rows = rows, .empty = "No matching files." }));
}
```

```zig
zw.view("<form{z}>{sort}{kind}</form><div id=\"files\">{table}</div>", .{
    .z = ui.Z{ .get = "/files", .trigger = "change", .target = "#files", .swap = .inner },
    // ...
})
```

## In a card

A table fits inside a card body. The badge in the header and a toast come back from one request: the badge replaces the one with the same `id`, and the toast is appended to the toast area.

```demo
table-invoice
```

```zig
ui.card(.{
    .title = "Invoice 1042",
    .accessory = ui.badge(.{ .id = "status", .text = "Due", .tone = .orange }),
    .body = ui.table(.{
        .head = &.{ "Item", "Qty", "Amount" },
        .aligns = &.{ .left, .right, .right },
        .rows = &.{ &.{ "Hosting, annual", "1", "$120.00" }, &.{ "Total", "", "$120.00" } },
        .row_header = true,
    }),
})
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `head` | `[]const []const u8` | required | column titles |
| `rows` | `[]const []const []const u8` | required | each row has one cell per column |
| `aligns` | slice of enum | `&.{}` | per column: `.left`, `.center`, `.right` (missing columns are left); right-aligned cells use tabular digits |
| `caption` | string | `""` | title above the table; also its accessible name |
| `striped` | bool | `false` | shade every other row |
| `compact` | bool | `false` | tighter rows for dense data |
| `row_header` | bool | `false` | first column becomes a bold row header (`<th scope="row">`) |
| `empty` | string | `""` | message across the table when `rows` is empty; with no message the table shows just its header |

## Notes

- Align numbers right and text left, as in Finder's list view.
- Cells are text only. Markup in a cell is escaped, so a cell cannot hold a button or a badge. Put actions next to the table, as the demos do.
- The frame is focusable so keyboard users can scroll a wide table sideways.
- Markdown tables on these pages render with the same styles.
