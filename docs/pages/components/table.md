# Table

A simple data table with a header row. Cells are plain strings and escaped, unless you mark a column as trusted HTML to hold a badge or button. Wide tables scroll inside their own frame. Use it for read-only data such as a Finder-style file list; for rows that are mostly controls, use a [list](/components/list).

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

Two segmented controls sit in one form. When either changes, the form sends both values and the server returns the sorted, filtered table, which replaces the old one (the table's `.id` is the swap target). `.sort_col` and `.sort_desc` mark the sorted header with `aria-sort` and an arrow. Pick Archives to see the empty message.

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
zw.view("<form{z}>{sort}{kind}</form>{table}", .{
    .z = ui.Z{ .get = "/files", .trigger = "change", .target = "#files", .swap = .outer },
    // ...
})

// The route answers with the table, carrying the same id.
ui.table(.{ .id = "files", .sort_col = 1, .sort_desc = true, .head = head, .rows = rows })
```

## Buttons and badges in cells

List the columns whose cells are trusted HTML in `.html`, one bool per column. Render the badge or button to a string first, then put the string in the row. The row at `.selected` is highlighted and marked `aria-current="true"`.

```demo
table-rich
```

```zig
// Render a component into the request arena.
var out: std.Io.Writer.Allocating = .init(c.arena);
try ui.badge(.{ .text = "Active", .tone = .green }).render(&out.writer);
const status = out.written();

ui.table(.{
    .head = &.{ "Name", "Status" },
    .rows = &.{ &.{ "Ada Lovelace", status } },
    .html = &.{ false, true },
    .selected = 0,
})
```

## In a card

A table fits inside a card body. `.foot` adds a footer row for totals, with a bold row header. The badge in the header and a toast come back from one request: the badge replaces the one with the same `id`, and the toast is appended to the toast area.

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
        .rows = &.{ &.{ "Hosting, annual", "1", "$120.00" } },
        .foot = &.{ "Total", "", "$120.00" },
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
| `id` | string | `""` | id of the table frame, usable as a `z-target` (swap `.outer`) or anchor |
| `html` | slice of bool | `&.{}` | per column: body cells are trusted HTML, not escaped (missing columns are text) |
| `foot` | `[]const []const u8` | `&.{}` | footer row for totals; first cell is a bold row header; text only, aligned like the columns |
| `sort_col` | `?usize` | `null` | column the rows are sorted by: its header gets `aria-sort` and an arrow |
| `sort_desc` | bool | `false` | the sort runs high to low (arrow points down) |
| `selected` | `?usize` | `null` | index of the highlighted row (`aria-current="true"`) |

## Notes

- Align numbers right and text left, as in Finder's list view.
- Cells are escaped text by default. Only columns you list in `.html` are written raw, so never put user input in them without escaping it. Header and footer cells are always text.
- The table does not sort itself. Sort the rows on the server and set `.sort_col` and `.sort_desc` so the header says which column is sorted. Header cells cannot hold controls; sort with controls next to the table, as the demo does.
- There is no loading state. While a swap is in flight the target is dimmed; to show a placeholder first, render a [skeleton](/components/skeleton) where the table will go and load the table with `z-trigger="load"`.
- A row header column makes every first cell bold. Put summary rows such as totals in `.foot` rather than in `.rows`.
- The frame is focusable so keyboard users can scroll a wide table sideways.
- Markdown tables on these pages render with the same styles.
