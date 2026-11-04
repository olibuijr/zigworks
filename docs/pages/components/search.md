# Search

A search field with live results in a glass panel. Each keystroke (debounced) sends `GET action?q=…` and shows the HTML your handler returns. Without JavaScript the form submits normally.

A notes window with a search field in its title bar. Type "lemon", "flights" or "retro" and pick a result: the note opens and the panel closes. The badge next to the title counts the matches. Press ⌘K (Ctrl+K) to focus the field.

```demo
search
```

The handlers behind this demo are short. One returns the result links, one opens a note:

```zig
fn find(c: *zw.Ctx) !void {
    const q = std.mem.trim(u8, c.query("q") orelse "", " ");
    const hits = try notes.search(c.arena, q);
    try c.html(
        \\{#each hits as h}<a href="#" z-get="/notes/open?id={h.id}" z-target="#note">{h.title}<small>{h.folder}</small></a>{/each}
        \\{#if !hits}{#if q}<p>No results for “{q}”.</p>{/if}{/if}
    , .{ .hits = hits, .q = q });
}
```

A result is a normal link, so it can also carry z.js attributes: here a click requests the note and swaps it into `#note`. The badge is updated out-of-band: add `ui.badge(.{ .id = "count", .oob = true, .count = hits.len })` to the same response.

## Usage

```zig
ui.search(.{ .action = "/search", .label = "Search docs" })

fn search(c: *zw.Ctx) !void {
    const hits = try find(c.arena, c.query("q") orelse "");
    try c.html("{#each hits as h}<a href=\"{h.url}\">{h.title}<small>{h.text}</small></a>{/each}", .{ .hits = hits });
}
```

Return `<a>` elements; a `<small>` inside one becomes its second line. The panel hides when the response is empty. Put the field in a toolbar or title bar; the panel opens under it, aligned to its right edge.

A compact field with a shortcut hint:

```zig
ui.search(.{ .action = "/search", .size = .small, .shortcut = "k", .min_length = 2 })
```

## Variants and sizes

`size` picks the height. `clear = false` removes the clear button, and `shortcut` adds the key hint. Each row shows the prop it sets. Type in any field to see results; picking one shows a toast.

```demo
search-sizes
```

## States

A search field has no states of its own beyond the text in it, so these are the cases your handler decides.

- **Results page.** `value` fills the field with the query, and `name` sets the parameter it is sent as (`term` here). Use it on the page a plain form submit lands on.
- **Too short.** `min_length` is the native `minlength` for the no-JS form. For live results, return nothing for short queries and the panel stays closed.
- **Nothing found.** Return a `<p>` and it shows as a plain message in the panel. The last field searches an empty archive, so anything you type ends here.
- **Loading.** While a request runs, z.js dims the field slightly. There is no spinner.

```demo
search-states
```

## In a sheet

A Quick Open sheet: a button opens the sheet, `autofocus` puts the cursor in the field, and the results sit under the field. Picking a result shows a toast and z.js closes the sheet, because the link is inside a popover.

```demo
search-quick
```

```zig
ui.sheet(.{
    .id = "quick",
    .title = "Quick Open",
    .size = .small,
    .body = ui.search(.{ .action = "/open", .id = "quick-results", .placeholder = "Open note", .autofocus = true }),
})
```

The results panel is positioned under the field by default. Inside a sheet, give it `position: static` so it grows with the sheet instead of floating.

## Notes

- The clear button appears once there is text. It is the browser's `type=search` button, restyled to match; Firefox does not draw one. Turn it off with `clear = false`.
- `shortcut` draws a `⌘K` hint at the end of the field while it is empty and unfocused, and sets `aria-keyshortcuts` and `data-shortcut` on the input. The hint relies on the placeholder being visible, so keep a non-empty `placeholder`. z.js focuses the field on ⌘+key or Ctrl+key. If several fields use the same key, the first one on the page wins.
- `min_length` sets the native `minlength`, which applies when the form is submitted without JavaScript. Live results still run on every keystroke unless the handler returns nothing for short queries.
- Extra query parameters belong in `action` (`/find?in=archive`): z.js adds `q` to them. A plain form submit without JavaScript replaces them, so read defaults on the server.
- Esc closes the results panel. On touch screens the field and each result are at least 44px tall.
- When a page has more than one search field, give each its own `id`.
- `autofocus` moves the cursor into the field when the page loads, so use it on a page whose job is searching, or inside a sheet.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `action` | string | required | the search URL; the query is sent to it as `GET action?name=…` |
| `label` | string | `"Search"` | accessible name |
| `placeholder` | string | `"Search"` | |
| `id` | string | `"zw-results"` | id of the results panel, a valid HTML id, unique per page |
| `name` | string | `"q"` | query parameter name |
| `value` | string | `""` | initial query, for a results page |
| `size` | enum: `small`, `regular`, `large` | `.regular` | 24px, 30px or 36px tall (44px on touch screens) |
| `clear` | bool | `true` | show the clear button once there is text |
| `shortcut` | string | `""` | key that focuses the field, shown as a `⌘` hint, for example `"k"`; needs a placeholder |
| `min_length` | u8 | `0` | shortest query the plain form submits; `0` means no minimum |
| `autofocus` | bool | `false` | focus the field when the page (or sheet) opens |
