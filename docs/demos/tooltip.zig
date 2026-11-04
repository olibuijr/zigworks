//! Live demos for docs/pages/components/tooltip.md (```demo tooltip``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "tooltip", false, tooltip },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/tooltip/x", handler }`.
pub const routes = .{};

fn tooltip(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}{f}", .{
        .a = ui.tooltip(.{ .text = "Shares a link to this list", .body = ui.button(.{ .label = "Share" }) }),
        .b = ui.tooltip(.{ .text = "Shown below", .side = .below, .body = ui.button(.{ .label = "Hover me", .variant = .plain }) }),
        .c = ui.tooltip(.{ .text = "Shown on the left", .side = .left, .body = ui.button(.{ .label = "Left", .variant = .plain }) }),
        .d = ui.tooltip(.{ .text = "Shown on the right", .side = .right, .body = ui.button(.{ .label = "Right", .variant = .plain }) }),
        .e = ui.tooltip(.{ .text = "Appears at once", .delay = 0, .body = ui.button(.{ .label = "No Delay" }) }),
        .f = ui.tooltip(.{
            .id = "demo-tip",
            .text = "Save",
            .shortcut = "⌘S",
            .detail = "Writes the document to disk.",
            .body = ui.button(.{ .label = "Save", .variant = .primary, .describedby = "demo-tip" }),
        }),
    }).render(w);
}
