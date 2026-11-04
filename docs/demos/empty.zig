//! Live demos for docs/pages/components/empty.md (```demo empty``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "empty", true, empty },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/empty/x", handler }`.
pub const routes = .{};

fn empty(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = ui.empty(.{
        .icon = "✓",
        .title = "No Reminders",
        .text = "Reminders you add show up here.",
        .action = ui.button(.{ .label = "New Reminder", .variant = .primary }),
        .secondary = ui.button(.{ .label = "Learn More", .variant = .plain }),
    }) }).render(w);
    try ui.card(.{ .variant = .inset, .body = ui.empty(.{ .title = "No results", .text = "Try a different search.", .size = .compact }) }).render(w);
}
