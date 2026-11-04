//! Live demos for docs/pages/components/badge.md (```demo badge``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "badge", false, badge },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/badge/x", handler }`.
pub const routes = .{};

fn badge(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}{f}{g}<span class=\"zw-row\" style=\"gap:6px\">{h}<span>Online</span></span>", .{
        .a = ui.badge(.{ .text = "3" }),
        .b = ui.badge(.{ .text = "12 left" }),
        .c = ui.badge(.{ .text = "New", .tone = .accent }),
        .d = ui.badge(.{ .text = "Beta", .tone = .orange, .size = .small }),
        .e = ui.badge(.{ .text = "Synced", .tone = .green }),
        .f = ui.badge(.{ .count = 128, .tone = .red, .solid = true }),
        .g = ui.badge(.{ .count = 7, .tone = .red, .solid = true, .size = .small }),
        .h = ui.badge(.{ .dot = true, .tone = .green, .text = "Online" }),
    }).render(w);
}
