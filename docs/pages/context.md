# Requests and responses

Every handler gets a `*zw.Ctx`. It reads the request and sends exactly one response. Everything it allocates comes from `c.arena` and is freed when the response is done.

## Reading the request

| Call | Returns |
|---|---|
| `c.param("id")` | route param, decoded, or null |
| `c.query("q")` | query string value, decoded |
| `c.form("title")` | field of a urlencoded form body |
| `c.json(T)` | the JSON body parsed into `T` |
| `c.header("accept")` | request header, case-insensitive |
| `c.isPartial()` | true when z.js sent the request |
| `c.method`, `c.path`, `c.body` | the raw request |

```zig
const Todo = struct { title: []const u8, done: bool = false };

fn create(c: *zw.Ctx) !void {
    const todo = try c.json(Todo);
    c.status = .created;
    try c.sendJson(.{ .ok = true, .title = todo.title });
}
```

Bodies larger than `Options.max_body` (1 MiB by default) get `413` and the connection closes.

## Sending the response

| Call | Sends |
|---|---|
| `c.page(component)` | HTML from any component |
| `c.html(src, data)` | an inline template |
| `c.text(s)` | plain text |
| `c.sendJson(value)` | JSON |
| `c.redirect("/")` | `303`, or a `z-redirect` header for z.js requests |
| `c.send(status, type, body)` | anything else |

Set `c.status` or call `c.setHeader(name, value)` before you respond. Calling a send method twice is a bug and asserts in debug builds.

## Partial responses

z.js adds a `z-request` header. Use `c.isPartial()` to return a fragment to z.js and a full page or redirect to everyone else, so the same form works with and without JavaScript:

```zig
fn create(c: *zw.Ctx) !void {
    const todo = try store.add(c.io, c.arena, c.form("title") orelse "");
    if (!c.isPartial()) return c.redirect("/");
    try c.page(views.row(todo));
}
```

## Errors

If a handler returns an error before responding, zigworks logs it and answers `500`. If it returns without responding, the answer is `204 No Content`.

## Server options

```zig
try zw.serve(init, app, .{
    .host = "127.0.0.1",    // default 0.0.0.0 (LAN); HOST env wins
    .port = 8080,           // the PORT environment variable wins
    .public = "public",     // static directory, null to disable
    .max_body = 4 << 20,    // bytes
});
```
