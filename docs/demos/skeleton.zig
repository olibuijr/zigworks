//! Live demos for docs/pages/components/skeleton.md (```demo skeleton``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "skeleton", true, skeleton },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/skeleton/x", handler }`.
pub const routes = .{};

fn skeleton(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%\">{a}{b}{c}{d}</div>", .{
        .a = ui.card(.{ .body = ui.skeleton(.{ .lines = 3 }) }),
        .b = ui.card(.{ .body = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 44 }) }),
        .c = ui.card(.{ .body = ui.skeleton(.{ .shape = .block, .height = "96px", .label = "Loading photo" }) }),
        .d = ui.card(.{ .body = ui.skeleton(.{ .lines = 2, .last_width = 40, .shimmer = false }) }),
    }).render(w);
}
