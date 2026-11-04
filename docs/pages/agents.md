# For AI agents

zigworks is designed so an agent can hold the whole framework in context and change it safely. This page is the short version of everything you need.

## Rules of the codebase

1. **Small files, one job each.** A component is one file in `src/ui/` with its markup, its CSS and its props.
2. **The compiler checks the work.** Routes, templates and component props are validated at `comptime`. If it builds, names line up.
3. **Standard library only.** No dependencies in Zig, no npm packages in tests.
4. **Every change gets a check.** Unit tests sit next to the code (`zig build test`); browser flows live in `tests/e2e.mjs` (`zig build e2e`).
5. **Look at the result.** `zig build e2e` saves light and dark screenshots to `zig-out/e2e/`. Read them before calling UI work done.

## Request flow

1. `server.zig` accepts a connection and starts one task for it.
2. Each request gets a fresh arena and a `Ctx`.
3. `/_zw/z.js` and `/_zw/zw.css` are built in.
4. Routes are tried in order; the first match runs.
5. Otherwise a file from `public/` is served, or 404.
6. A handler that sends nothing gets 204; a handler error gets 500 and a log line.

## Add a route

Add a tuple to `app.routes` and write `fn (c: *zw.Ctx) !void`. Read input with `c.param`, `c.query`, `c.form` or `c.json`; answer once with `c.page`, `c.html`, `c.text`, `c.sendJson` or `c.redirect`.

## Add a component

This is the one checklist; the README links here. A new component touches all of these:

1. `src/ui/<name>.zig`: `pub const css`, a `Props` struct and a constructor returning a named type (`pub const Name = zv.View(src, Props)`). Use only design tokens in the CSS (`var(--accent)`, `var(--radius-control)`), never literal colors, and reuse the shared base CSS (focus ring, `.zw-input`, `.zw-sr`) instead of copying it.
2. `src/ui.zig`: import it, export it and add it to `all`.
3. `docs/demos.zig`: a demo function and a row in the demo table.
4. `docs/pages/components/<name>.md`: its docs page, listing every prop.
5. `docs/pages.zig`: a sidebar entry.
6. `tests/e2e.mjs`: a test of its behaviour.
7. `CHANGELOG.md`: a line under `[Unreleased]`.
8. Optional: a spot in the gallery (`examples/gallery`).

Then run `zig build test e2e` and look at the screenshots.

## Gotchas

> [!WARNING]
> Zig 0.17 changed a lot of the standard library. `std.meta.fields` is gone (use `@typeInfo(T).@"struct".field_names`), `allocPrint` became `allocator.print`, and `Io.Group.concurrent` cannot take a function with `anytype` parameters.

- Template strings and the `app` value must be known at compile time. Declare `app` at file scope.
- `{...}` in a template is a tag. Write `{{` for a literal brace.
- Reading the request body invalidates `req.head`: `Ctx` copies what it needs first, so use `Ctx` methods.
- Popover ids (`opens`, menu and picker ids) must be valid CSS identifiers.
