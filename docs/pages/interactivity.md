# Interactivity

z.js is a 6 KB script (unminified) that every `ui.layout` page loads. It reads `z-*` attributes, sends requests and swaps the HTML the server returns into the page. Your handlers stay plain functions that return HTML.

```zig
const add: ui.Z = .{ .post = "/todos", .target = "#todos", .swap = .beforeend };
// <form{z}> in a template, or .z = add on a component
```

## Attributes

| Attribute | Does |
|---|---|
| `z-get`, `z-post`, `z-put`, `z-patch`, `z-delete` | send a request to the URL |
| `z-target` | where the answer goes: a selector, or `closest li` |
| `z-swap` | `inner` (default), `outer`, `beforeend`, `afterbegin`, `delete`, `none` |
| `z-trigger` | `click`, `submit`, `change`, `input` (debounced), `load` |
| `z-confirm` | ask first, in a custom dialog |
| `z-oob` | on a response element with an `id`: replace that element anywhere |

Forms send their fields; an input sends its own `name=value`; a checkbox sends nothing when unchecked. The default trigger is `submit` for forms, `change` for inputs and `click` for everything else.

## Updating two places at once

Mark extra elements in the response with `z-oob`. The todo example adds a row and updates the counter in the title bar with one response:

```zig
try c.html("{row}{count}", .{
    .row = views.row(todo),
    .count = ui.badge(.{ .text = "2 left", .id = "remaining", .oob = true }),
});
```

## After a request

- A `z-redirect` response header sends the browser to that URL (`c.redirect` does this for you).
- `204 No Content` swaps nothing.
- A successful non-GET form is reset, and an open menu or sheet closes.
- Errors are logged to the console and nothing is swapped.

## Motion

Only content added with `beforeend` or `afterbegin` animates in, so motion always means "this is new". Everything respects Reduce Motion.
