# zigworks

A small, fast web framework in pure Zig, written for AI agents (and people) to read and extend.
Server-rendered HTML, Svelte-style templates checked at compile time, htmx-style interactivity,
a macOS-quality component library, and islands for three.js and other client JS. No dependencies.

- **Zig 0.17.1** (pinned in `mise.toml`), standard library only.
- **Browser:** z.js (~6 KB, unminified) + one generated stylesheet. Pages work without JS.

```sh
zig build test      # unit tests
zig build e2e       # browser tests + screenshots in zig-out/e2e (needs chromium + node)
zig build run       # todo example on http://127.0.0.1:8080 (PORT=... to change)
zig build gallery   # every ui component in a preferences window
zig build scene     # three.js island
```

## Layout

```
src/
  zigworks.zig  public API (start here)
  server.zig    HTTP/1.1 on std.http, keep-alive, one task per connection, per-request arena
  router.zig    comptime routes
  ctx.zig       request context and responses
  view.zig      templates, props(), each()
  css.zig       design tokens -> CSS variables (macOS HIG defaults)
  static.zig    public/ files (JS modules, wasm, glb/gltf/hdr/ktx2, images, fonts)
  client/z.js   browser runtime
  client.zig    z.js + styles for what it creates
  ui.zig        component library index
  ui/*.zig      one component per file, each with its own css
examples/       todo (CRUD, works without JS), gallery (all components), scene (three.js)
tests/e2e.mjs   Chromium over DevTools protocol, zero npm packages
```

## An app

```zig
const std = @import("std");
const zw = @import("zigworks");

const app = .{
    .routes = .{
        .{ "GET /", index },
        .{ "POST /todos", create },
        .{ "DELETE /todos/:id", remove },
    },
    .css = ".todo{gap:8px}",   // optional, appended to /_zw/zw.css
    .tokens = .{},             // optional, override design tokens
};

pub fn main(init: std.process.Init) !void {
    try zw.serve(init, app, .{ .port = 8080 });
}

fn index(c: *zw.Ctx) !void {
    try c.page(zw.ui.layout(.{ .title = "Hello", .body = zw.view("<p>Hi {name}</p>", .{ .name = "you" }) }));
}
```

Request order: `/_zw/*` built-ins, then routes in order, then files in `public/`, then 404.
A handler that sends nothing answers 204. A handler error answers 500 and is logged.

## Routes

`"METHOD /path/:param/*"`. GET routes also answer HEAD. `*` (last segment) captures the rest as param `"*"`.
Patterns are checked at compile time.

## Ctx

| Read | |
|---|---|
| `c.param("id")` | route param, decoded |
| `c.query("q")` | query value, decoded |
| `c.form("title")` | urlencoded body field, decoded |
| `c.json(T)` | parse JSON body |
| `c.header("name")` | request header (case-insensitive) |
| `c.isPartial()` | request came from z.js: send a fragment |
| `c.method`, `c.path`, `c.body`, `c.arena`, `c.io` | |

| Respond (once) | |
|---|---|
| `c.page(component)` | HTML from any value with `render(self, *Writer)` |
| `c.html(src, data)` | inline template |
| `c.text(s)`, `c.sendJson(v)` | |
| `c.redirect("/")` | 303, or `z-redirect` header for z.js |
| `c.send(status, content_type, body)` | anything |
| `c.status = .created`, `c.setHeader(k, v)` | before responding |

All memory from `c.arena` is freed after the response. Bodies over `Options.max_body` (1 MiB) get 413.

## Templates

Compiled at comptime; unknown variables and bad blocks are compile errors. Output is escaped.

```
{expr}                      escaped value: strings, ints, floats, bools, enums, optionals
{@html expr}                raw
{#if expr}..{:else}..{/if}  `!expr` negates; truthy = true, non-null, non-empty, non-zero
{#each list as x, i}..{/each}
{{                          literal {
```

`expr` is a path: `todo.title`, `todos.len`. A value with `render(self, *Writer)` is written raw: that's how components nest.

```zig
zw.view(src, data)            // a component from a template
zw.View(src, Data)            // its type, for return types
zw.each(items, rowFn)         // render rowFn(item) for each item; type zw.Each(Items, rowFn)
zw.props(T, .{...})           // build props with defaults; missing/unknown props are compile errors
```

## Components (`zw.ui`)

macOS HIG defaults. Glass only on the functional layer (title bar, menus, dialog); content is opaque.
No stock browser UI: pickers replace `<select>`, a custom dialog replaces `confirm()`.

| Component | Props (defaults) | Type |
|---|---|---|
| `layout` | title, body, toolbar="", head="" | `Layout(Toolbar, Body)` |
| `card` | body, title="", z | `Card(Body)` |
| `list` | id, body, empty="Nothing here yet" | `List(Body)` |
| `setting` | label, control | `Setting(Control)` |
| `sheet` | id, title, body | `Sheet(Body)` |
| `button` | label, variant=.secondary (primary/secondary/plain/destructive), type=.button, aria, opens, disabled, z | `Button` |
| `field` | name, label, placeholder, value, type="text", required, autofocus, z | `Field` |
| `check` | on, label, z | `Check` |
| `toggle` | name, label, on=false, z | `Toggle` |
| `segmented` | name, label, options=[{value,label,selected}], z | `Segmented` |
| `slider` | name, label, min=0, max=100, step=1, value=50, z | `Slider` |
| `picker` | id, name, label, options=[{value,label,selected}], z | `Picker` |
| `menu` | id, items=[{label, z, destructive, separated}] | `Menu` |
| `badge` | text, id, oob | `Badge` |
| `island` | src, props="{}", height="360px", label | `Island` |

`button(.{ .opens = "id" })` toggles a `menu` or `sheet` (Popover API + CSS anchor positioning, no JS).
`id`s used with `opens` must be valid CSS identifiers.

**Add a component:** create `src/ui/<name>.zig` with `pub const css` and a constructor that returns a
named `View` type, then import, export and list it in `src/ui.zig`. Add it to the gallery and to `tests/e2e.mjs`.

## z.js

Attributes on any element (or `ui.Z` as `.z` on components, or `{z}` inside a tag):

```
z-get|z-post|z-put|z-patch|z-delete="/url"   send a request (forms send their fields, inputs their name=value)
z-target="#id" | "closest li"                where to put the response (default: the element)
z-swap="inner|outer|beforeend|afterbegin|delete|none"
z-trigger="click|submit|change|input|load"   default: submit for forms, change for inputs, click otherwise
z-confirm="Delete all?"                      ask first (custom dialog)
z-oob                                        on a response element with an id: replace that element anywhere
z-island="/mod.js" data-props='{"a":1}'      import the module, call default(el, props); return cleanup
```

Requests carry `z-request: 1`. Successful non-GET forms reset; popovers close after an action.
Only content added by `beforeend`/`afterbegin` animates, so motion marks what changed.

## Design tokens

`css.Tokens` fields become CSS variables (`radius_control` becomes `--radius-control`). `light`/`dark`
palettes use macOS semantic names (`window`, `content`, `label`, `secondary`, `separator`, `accent`...)
and follow `prefers-color-scheme`. Reduce Transparency and Increase Contrast are honoured.

```zig
.tokens = .{ .radius = "12px", .light = blk: { var p = zw.css.light; p.accent = "#5e5ce6"; break :blk p; } },
```

## three.js

Put modules in `public/`, map bare imports with `layout(.{ .head = importmap })`, mount with `ui.island`.
See `examples/scene`. Vendor three into `public/` to run offline.

## Limits

- One task per connection, no idle timeout: run behind a reverse proxy on the open internet.
- Static files are read into memory per request (64 MiB cap); no ETag or range requests yet.
- No TLS, HTTP/2, sessions or CSRF tokens; add them when an app needs them.
