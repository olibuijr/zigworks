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

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | the target for z.js swaps |
| `empty` | string | `"Nothing here yet"` | shown when there are no rows |
| `body` | component | required | the rows |

Add rows with `.swap = .beforeend` and a target of `#id`; new rows animate in.
