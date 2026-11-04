# Routing

Routes are a tuple of `"METHOD /path"` and handler pairs. They are matched in order, and the patterns are parsed at compile time, so a malformed route fails the build.

```zig
const app = .{
    .routes = .{
        .{ "GET /", index },
        .{ "GET /todos/:id", show },
        .{ "PATCH /todos/:id", toggle },
        .{ "GET /files/*", file },
    },
};
```

## Patterns

| Pattern | Matches | Params |
|---|---|---|
| `/todos` | `/todos` only | none |
| `/todos/:id` | `/todos/42` | `id = "42"` |
| `/u/:user/posts/:post` | `/u/ada/posts/7` | `user`, `post` |
| `/files/*` | `/files/a/b.txt` | `* = "a/b.txt"` |

A `:param` never matches an empty segment, and `*` is only allowed as the last segment. Up to 8 params per route.

## Methods

Any `std.http.Method` works: `GET`, `POST`, `PUT`, `PATCH`, `DELETE` and the rest. A `GET` route also answers `HEAD`, without a body.

## Reading params

```zig
fn show(c: *zw.Ctx) !void {
    const id = std.fmt.parseInt(u32, c.param("id") orelse "", 10) catch {
        return c.send(.not_found, "text/plain", "no such todo");
    };
    try c.html("<h1>Todo {id}</h1>", .{ .id = id });
}
```

Params are percent-decoded. Parse and validate them like any other input.

## What happens without a match

After the routes, zigworks looks for a file in `public/` with the same path. If there is none, the answer is `404 not found`. The built-in assets `/_zw/z.js` and `/_zw/zw.css` are checked before your routes.
