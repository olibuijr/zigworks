# Introduction

zigworks is a small, fast web framework in pure Zig. It renders HTML on the server, makes pages interactive with a few HTML attributes, and ships a component library with a macOS look. It was written by AI, for AI agents and the people working with them: every part is small enough to read in one sitting.

```demo
hero
```

## What you get

- **An HTTP server** on the Zig standard library, with keep-alive and a memory arena per request.
- **Routes checked at compile time.** `"GET /todos/:id"` is parsed when you build, not when a request arrives.
- **Svelte-style templates** compiled by `comptime`, escaped by default. A typo in a template is a build error.
- **Interactivity without a JS framework.** `z-post`, `z-target` and `z-swap` attributes, like htmx, in one script of about 18 KB (~7 KB gzipped), Liquid Glass runtime included.
- **35 components** in Liquid Glass that follow the macOS Human Interface Guidelines, light and dark.
- **Islands** for code that needs real JavaScript, such as three.js scenes.
- **Browser tests** that drive Chromium directly, with no npm packages.

## Thirty seconds

```zig
const std = @import("std");
const zw = @import("zigworks");

const app = .{ .routes = .{.{ "GET /", hello }} };

pub fn main(init: std.process.Init) !void {
    try zw.serve(init, app, .{});
}

fn hello(c: *zw.Ctx) !void {
    try c.page(zw.ui.layout(.{
        .title = "Hello",
        .body = zw.view("<p>Hello, {name}!</p>", .{ .name = c.query("name") orelse "world" }),
    }));
}
```

`zig build run`, open `http://127.0.0.1:8080/?name=Zig`, and the page says hello. The name is escaped, so `?name=<script>` is just text.

## This site

These docs are a zigworks app. Pages are Markdown files compiled into the binary, the sidebar and search are components, and every demo is the real component. Read `docs/` in the repository to see how.

> [!TIP]
> New here? Start with [Getting started](/getting-started). Building with an agent? Point it at [For AI agents](/agents).
