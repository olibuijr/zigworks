//! three.js through an island: the server renders the page, z.js mounts public/scene.js into it.
//! three loads from a CDN via an import map; vendor it into public/ to run offline.
const std = @import("std");
const zw = @import("zigworks");
const ui = zw.ui;

const app = .{ .routes = .{.{ "GET /", index }} };

const importmap =
    \\<script type="importmap">{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js"}}</script>
;

pub fn main(init: std.process.Init) !void {
    try zw.serve(init, app, .{});
}

fn index(c: *zw.Ctx) !void {
    const raw = std.fmt.parseFloat(f32, c.query("speed") orelse "1") catch 1;
    const speed = if (std.math.isFinite(raw)) std.math.clamp(raw, 0, 10) else 1;
    try c.page(ui.layout(.{
        .title = "Scene",
        .head = importmap,
        .body = ui.card(.{ .title = "Icosahedron", .body = ui.island(.{
            .src = "/scene.js",
            .props = try c.arena.print("{{\"speed\":{d}}}", .{speed}),
            .height = "420px",
            .label = "Rotating 3D icosahedron",
        }) }),
    }));
}
