# List

An inset list of rows. Rows are `<li>` elements; separators start after a leading control, as in macOS. An empty list shows its `empty` text.

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

Add rows with `.swap = .beforeend` and a target of `#id`; new rows animate in.

## Row states

Set these on the `<li>`; no props needed.

- `aria-selected="true"` fills the row with the accent color.
- `aria-disabled="true"` dims the row and ignores the pointer.

Rows are at least 44px tall, and focus rings are drawn inside the list so its rounded corners never clip them.
