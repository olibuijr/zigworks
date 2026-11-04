# Getting started

zigworks needs **Zig 0.17.1** and nothing else. The repository pins it in `mise.toml`, so `mise install` sets it up.

## Run the examples

```sh
git clone <your copy of zigworks> && cd zigworks
zig build run       # todo app on http://127.0.0.1:8080
zig build gallery   # every component in a preferences window
zig build scene     # three.js island
zig build docs      # this site
```

Set `PORT` to use another port: `PORT=3000 zig build run`.

## Add it to your project

Add zigworks to `build.zig.zon` with `zig fetch --save <url or path>`, then import the module in `build.zig`:

```zig
const zigworks = b.dependency("zigworks", .{ .target = target });
exe.root_module.addImport("zigworks", zigworks.module("zigworks"));
```

## Your first app

```zig
const std = @import("std");
const zw = @import("zigworks");
const ui = zw.ui;

const app = .{
    .routes = .{
        .{ "GET /", index },
        .{ "POST /greet", greet },
    },
};

pub fn main(init: std.process.Init) !void {
    try zw.serve(init, app, .{ .port = 8080 });
}

fn index(c: *zw.Ctx) !void {
    try c.page(ui.layout(.{ .title = "Greeter", .body = ui.card(.{
        .title = "Say hello",
        .body = zw.view("<form class=\"zw-row\"{z}>{name}{go}</form><p id=\"out\"></p>", .{
            .z = ui.Z{ .post = "/greet", .target = "#out" },
            .name = ui.field(.{ .name = "name", .label = "Name", .placeholder = "Your name" }),
            .go = ui.button(.{ .label = "Greet", .variant = .primary, .type = .submit }),
        }),
    }) }));
}

fn greet(c: *zw.Ctx) !void {
    try c.html("Hello, {n}!", .{ .n = c.form("name") orelse "stranger" });
}
```

Submitting the form posts it with z.js and puts the answer in `#out`, without a page reload.

## Project layout

| Path | What it is |
|---|---|
| `src/zigworks.zig` | the public API, start reading here |
| `src/server.zig` | HTTP server and request flow |
| `src/router.zig`, `src/ctx.zig` | routes and the request context |
| `src/view.zig` | templates |
| `src/ui/` | one file per component, each with its CSS |
| `src/client/z.js` | the browser runtime |
| `public/` | your static files, served at `/` |

## Limits

- One task per connection and no idle timeout: put a reverse proxy in front on the open internet.
- Static files are read into memory per request (64 MiB cap).
- No TLS, HTTP/2, sessions or CSRF tokens yet.
