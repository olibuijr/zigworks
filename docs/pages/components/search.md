# Search

A search field with live results in a glass panel. Each keystroke (debounced) sends `GET action?q=…` and shows the HTML your handler returns. Without JavaScript the form submits normally.

```demo
search
```

## Usage

```zig
ui.search(.{ .action = "/search", .label = "Search docs" })

fn search(c: *zw.Ctx) !void {
    const hits = try find(c.arena, c.query("q") orelse "");
    try c.html("{#each hits as h}<a href=\"{h.url}\">{h.title}<small>{h.text}</small></a>{/each}", .{ .hits = hits });
}
```

Return `<a>` elements; a `<small>` inside one becomes its second line. The panel hides when the response is empty.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `action` | string | required | the search URL |
| `label` | string | `"Search"` | accessible name |
| `placeholder` | string | `"Search"` | |
| `id` | string | `"zw-results"` | id of the results panel, unique per page |
