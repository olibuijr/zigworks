//! Live demos for docs/pages/components/radio.md (```demo radio``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "radio", false, radio },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/radio/x", handler }`.
pub const routes = .{};

fn radio(w: *Writer) Writer.Error!void {
    try ui.radio(.{ .name = "open", .label = "New windows open with", .z = d.save, .options = &.{
        .{ .value = "recent", .label = "Recents", .selected = true },
        .{ .value = "home", .label = "Home folder" },
        .{ .value = "desktop", .label = "Desktop", .description = "The folder on your desktop" },
        .{ .value = "icloud", .label = "iCloud Drive", .disabled = true },
    } }).render(w);
}
