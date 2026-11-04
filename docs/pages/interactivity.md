# Interactivity

z.js is a small unminified script that every `ui.layout` page loads: about 10 KB, plus 8 KB of Liquid Glass runtime served with it as `/_zw/z.js` (about 7 KB gzipped together). It reads `z-*` attributes, sends requests and swaps the HTML the server returns into the page. Your handlers stay plain functions that return HTML.

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
| `z-trigger` | `click`, `submit`, `change`, `input` (debounced), `load`, `every 2s` / `every 500ms` (polls while the page is visible) |
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
- A successful non-GET form is reset (add `z-keep`, or `.keep = true` in `ui.Z`, to keep its values, as settings forms should; a `z-keep` response header does the same for one response), and an open menu or sheet closes (a `z-keep-open` attribute or response header keeps it open, for showing an error inside it).
- Pressing Enter in a field of a `z` form sends it, whatever its trigger, instead of reloading the page.
- Errors are logged to the console. Only the response's `z-oob` parts are applied, so an error status can still carry an error toast.

## Motion

Every change has its own motion, so people see what happened:

- Content added with `beforeend` or `afterbegin` springs in ("this is new").
- Content replaced by `inner` or `outer` fades up from half opacity ("this changed").
- Removed elements (`delete` swaps, dismissed toasts, removed tags) fade, shrink and collapse along their row or column, and their neighbours glide into the gap.
- The confirm dialog scales in and out, copy buttons flip to "Copied", and page navigations crossfade (a cross-document view transition).

Everything respects Reduce Motion: removals are instant and nothing else moves.
