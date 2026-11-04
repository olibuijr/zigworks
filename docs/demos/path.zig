//! Live demos for docs/pages/components/path.md (```demo path``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "path", false, path },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/path/x", handler }`.
pub const routes = .{};

fn path(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"gap:10px\">{a}{b}</div>", .{
        .a = ui.path(.{ .items = &.{ .{ .label = "Docs", .href = "/", .icon = "⌂" }, .{ .label = "Components", .href = "/components/layout" }, .{ .label = "Path" } } }),
        .b = ui.path(.{ .separator = .slash, .max = 3, .items = &.{
            .{ .label = "Home", .href = "/", .icon = "⌂" },
            .{ .label = "Projects", .href = "/projects" },
            .{ .label = "zigworks", .href = "/projects/zigworks" },
            .{ .label = "docs", .href = "/projects/zigworks/docs" },
            .{ .label = "Settings" },
        } }),
    }).render(w);
}
