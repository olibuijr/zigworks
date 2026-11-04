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

`disabled`, `readonly` and `invalid` style the field itself. The rest are cases your handler decides.

- **Disabled, read only, invalid.** `disabled` dims the field and hides the shortcut hint, `readonly` shows the text on a filled background, and `invalid` adds a red ring and `aria-invalid`. Put the explanation next to the field, as text.
- **Results page.** `value` fills the field with the query, and `name` sets the parameter it is sent as (`term` here). Use it on the page a plain form submit lands on.
- **Too short.** `min_length` is the native `minlength` for the no-JS form. For live results, return nothing for short queries and the panel stays closed.
- **Nothing found.** Return a `<p>` and it shows as a plain message in the panel. The last field searches an empty archive, so anything you type ends here.
- **Loading.** While a request runs, a small spinner turns at the end of the field. It stops with `prefers-reduced-motion`.

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
    .body = ui.search(.{ .action = "/open", .id = "quick-results", .placeholder = "Open note", .autofocus = true, .inline_results = true }),
})
```

The results panel floats under the field by default, and a sheet would clip it. `inline_results = true` puts the results in the page flow instead, so the panel grows with the sheet. It still hides when the field loses focus.

## Notes

- The clear button appears once there is text. It is the browser's `type=search` button, restyled to match; Firefox does not draw one. Turn it off with `clear = false`.
- `shortcut` draws a `⌘K` hint at the end of the field while it is empty and unfocused, and sets `aria-keyshortcuts` and `data-shortcut` on the input. `platform = .pc` draws `Ctrl+K` instead; the page has to choose, there is no detection. The hint relies on the placeholder being visible, so keep a non-empty `placeholder`. z.js focuses the field on ⌘+key or Ctrl+key. If several fields use the same key, the first one on the page wins, so give each field its own key.
- `min_length` sets the native `minlength`, which applies when the form is submitted without JavaScript. Live results still run on every keystroke unless the handler returns nothing for short queries.
- Extra query parameters belong in `action` (`/find?in=archive`): z.js adds `q` to them. A plain form submit without JavaScript replaces them, so read defaults on the server.
- Esc closes the results panel. On touch screens the field and each result are at least 44px tall.
- The field is 240px wide and never wider than its container, in a row, a column or a block. Set `width` on `.zw-search` for another width, for example `100%` for a full-width field.
- The floating panel is right-aligned to the field and up to 360px wide. A narrow field near the left edge of a small screen would push it off-screen, so give such a field enough width, or use `inline_results`.
- The results are plain links and the panel is not a listbox: reach them with Tab from the field. Arrow keys do not move into the panel.
- The panel stays open while a result inside it has focus. A link that loads content with z.js should also replace the panel with an empty one (`z-oob`, as the first demo does); a link that navigates leaves the page anyway.
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
| `disabled` | bool | `false` | not editable, dimmed |
| `readonly` | bool | `false` | shows the text, cannot be edited |
| `invalid` | bool | `false` | red ring and `aria-invalid` |
| `platform` | enum: `mac`, `pc` | `.mac` | shortcut hint as `⌘K` or `Ctrl+K` |
| `inline_results` | bool | `false` | results in the page flow instead of a floating panel; use inside sheets |
