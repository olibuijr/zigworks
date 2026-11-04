//! Live demos for docs/pages/components/code.md (```demo code``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "code", true, code },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/code/x", handler }`.
pub const routes = .{};

fn code(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%;min-width:0\">{a}{b}{c}</div>", .{
        .a = ui.code(.{ .src = "fn index(c: *zw.Ctx) !void {\n    try c.html(\"<h1>Hello, {name}</h1>\", .{ .name = \"Zig\" });\n}" }),
        .b = ui.code(.{
            .title = "handlers.zig",
            .numbers = true,
            .highlight = "2-3",
            .src = "fn create(c: *zw.Ctx) !void {\n    const title = c.form(\"title\") orelse return;\n    try store.add(title);\n    try c.html(\"{row}\", .{ .row = row(title) });\n}",
        }),
        .c = ui.code(.{ .lang = "sh", .wrap = true, .copy = false, .src = "curl -fsSL https://example.com/install-zigworks.sh | sh -s -- --prefix /usr/local --with-docs --no-telemetry" }),
    }).render(w);
}
