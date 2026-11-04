# Table

A simple data table with a header row. Cells are strings and escaped. Wide tables scroll inside their own frame.

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

ui.table(.{
    .caption = "Disk usage",
    .head = &.{ "Volume", "Used", "Free" },
    .aligns = &.{ .left, .right, .right },
    .rows = &.{ &.{ "System", "41.2 GB", "22.8 GB" }, &.{ "Backups", "310 GB", "190 GB" } },
    .striped = true,
    .row_header = true,
})

ui.table(.{ .head = &.{ "Name", "Role" }, .rows = &.{}, .empty = "No members yet" })
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
| `empty` | string | `""` | message across the table when `rows` is empty |

## Notes

- Align numbers right and text left, as in Finder's list view.
- The frame is focusable so keyboard users can scroll a wide table sideways.
