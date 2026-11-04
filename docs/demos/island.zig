//! Live demos for docs/pages/components/island.md (```demo island``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "island", true, island },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/island/x", handler }`.
pub const routes = .{};

fn island(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%\">{a}{b}</div>", .{
        .a = ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":5}", .height = "220px", .label = "Animated orbit drawn on a canvas" }),
        .b = ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":3}", .aspect = "21/9", .label = "Wide orbit that keeps its proportions", .fallback = "Turn on JavaScript to see the orbit." }),
    }).render(w);
}
