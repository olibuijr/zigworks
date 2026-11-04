//! Live demos for docs/pages/components/check.md (```demo check``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "check", false, check },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/check/x", handler }`.
pub const routes = .{};

fn check(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}{f}{g}", .{
        .a = ui.check(.{ .on = false, .label = "Not done" }),
        .b = ui.check(.{ .on = true, .label = "Done" }),
        .c = ui.check(.{ .on = true, .label = "Small", .size = .small }),
        .d = ui.check(.{ .on = true, .label = "Large", .size = .large }),
        .e = ui.check(.{ .on = true, .label = "Flagged", .tint = .orange }),
        .f = ui.check(.{ .on = true, .label = "Urgent", .tint = .red }),
        .g = ui.check(.{ .on = true, .label = "Locked", .disabled = true }),
    }).render(w);
}
