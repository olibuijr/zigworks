# List

An inset list of rows. Rows are `<li>` elements; separators start after a leading control, as in macOS. An empty list shows its `empty` text.

This is an inbox: a header, an avatar as the leading control, and a Delete button that appears on hover. Delete every message to see the empty text.

```demo
list
```

## Usage

```zig
fn row(t: Todo) zw.View("<li>{t.title}</li>", struct { t: Todo }) {
    return .{ .data = .{ .t = t } };
}

ui.list(.{ .id = "todos", .empty = "No todos yet.", .body = zw.each(todos, row) })
```

A grouped list with a caption and navigation rows:

```zig
ui.list(.{
    .id = "panes",
    .header = "Network",
    .footer = "Changes apply to every account.",
    .nav = true,
    .body = zw.view("<li><a href=\"/wifi\">Wi-Fi</a></li><li><a href=\"/vpn\">VPN</a></li>", .{}),
})
```

## Variants

Separators, the navigation list and the flat surface, side by side. Each label shows the prop that makes the difference.

- `separators`: `.inset` (default) starts the hairline after the leading control, `.full` runs it edge to edge, `.none` drops it.
- `nav` makes each row a link that fills the row and draws a disclosure chevron.
- `inset = false` removes the surface, so the list sits flat inside a card. A `flush` card does the same for you.

```demo
list-variants
```

## Row states

Set these on the `<li>`; no props needed.

- `aria-selected="true"` fills the row with the accent color.
- `aria-disabled="true"` dims the row and ignores the pointer.

A list with no rows shows its `empty` text. While data loads, put a skeleton in each row.

```demo
list-states
```

Rows are at least 44px tall, and focus rings are drawn inside the list so its rounded corners never clip them.

## Selecting a row

A `nav` list whose links carry a z.js request. The server answers with the rows (the selected one moves) and the detail pane as an out-of-band swap, so one click updates both. The page holds no state; the link says which note it opens.

```demo
list-select
```

```zig
// Each row link:
//   <li aria-selected="true"><a href="#notes" z-get="/notes/2" z-target="#notes" z-swap="inner">...</a></li>
fn open(c: *zw.Ctx) !void {
    const n = std.fmt.parseInt(usize, c.query("n") orelse "0", 10) catch 0;
    // The pane has z-oob and an id, so z.js replaces the pane already on the page.
    try c.html("{rows}{pane}", .{ .rows = noteRows(n), .pane = notePane(n) });
}
```

## Adding and removing rows

Add rows with `.swap = .beforeend` and a target of `#id`; new rows animate in. A row's Delete button uses `.swap = .delete` on `closest li`, and the row collapses away. With `reveal`, the button shows on hover or focus only. Each answer carries a toast, which lands in the layout's toast area wherever the request points.

```demo
list-add
```

```zig
fn add(c: *zw.Ctx) !void {
    const item = std.mem.trim(u8, c.form("item") orelse "", " ");
    try c.html("{row}{toast}", .{ .row = bagRow(item), .toast = ui.toast(.{ .text = "Added", .kind = .success }) });
}
```

## In a real layout

A list inside a flush card, with avatars, tags and a switch. The card gives the list its surface and the card's header and footer carry the actions.

```demo
list-share
```

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | the target for z.js swaps |
| `empty` | string | `"Nothing here yet"` | shown when there are no rows |
| `header` | string | `""` | caption above the list; also names the list for screen readers |
| `footer` | string | `""` | caption below the list; also describes the list |
| `separators` | `.inset`, `.full`, `.none` | `.inset` | hairlines between rows: after a leading control, edge to edge, or none |
| `nav` | bool | `false` | rows are `<li><a href>`: the link fills the row and shows a disclosure chevron |
| `reveal` | bool | `false` | a row's destructive button shows on hover or focus (always visible on touch) |
| `inset` | bool | `true` | `false` drops the surface, so the list sits flat inside a card |
| `body` | component | required | the rows |
