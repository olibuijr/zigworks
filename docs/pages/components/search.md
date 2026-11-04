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

A compact field with a shortcut hint:

```zig
ui.search(.{ .action = "/search", .size = .small, .shortcut = "k", .min_length = 2 })
```

## Notes

- The clear button appears once there is text. It is the browser's `type=search` button, restyled to match; Firefox does not draw one. Turn it off with `clear = false`.
- `shortcut` draws a `⌘K` hint at the end of the field while it is empty and unfocused, and sets `aria-keyshortcuts` and `data-shortcut` on the input. The hint relies on the placeholder being visible, so keep a non-empty `placeholder`. Focusing the field with the key needs a script that reads `data-shortcut`.
- `min_length` sets the native `minlength`, which applies when the form is submitted without JavaScript. Live results still run on every keystroke unless the handler returns nothing for short queries.
- Esc closes the results panel. On touch screens the field and each result are at least 44px tall.
- When a page has more than one search field, give each its own `id`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `action` | string | required | the search URL |
| `label` | string | `"Search"` | accessible name |
| `placeholder` | string | `"Search"` | |
| `id` | string | `"zw-results"` | id of the results panel, unique per page |
| `name` | string | `"q"` | query parameter name |
| `value` | string | `""` | initial query, for a results page |
| `size` | enum: `small`, `regular`, `large` | `.regular` | 24px, 30px or 36px tall (44px on touch screens) |
| `clear` | bool | `true` | show the clear button once there is text |
| `shortcut` | string | `""` | key that focuses the field, shown as a `⌘` hint, for example `"k"` |
| `min_length` | u8 | `0` | shortest query the plain form submits; `0` means no minimum |
| `autofocus` | bool | `false` | |
