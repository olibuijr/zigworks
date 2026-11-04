//! Live demos for docs/pages/components/tabs.md (```demo tabs``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "tabs", true, tabs },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/tabs/x", handler }`.
pub const routes = .{};

fn tabs(w: *Writer) Writer.Error!void {
    try ui.tabs(.{ .id = "demo-tabs", .labels = &.{ "General", "Sharing", "Advanced", "Archive" }, .badges = &.{ "", "2" }, .disabled = &.{3}, .panels = .{
        ui.card(.{ .body = zw.view("{a}{b}", .{
            .a = ui.toggle(.{ .name = "sync", .label = "Sync across devices", .on = true, .z = d.save }),
            .b = ui.toggle(.{ .name = "badge", .label = "Show badge", .z = d.save }),
        }) }),
        ui.card(.{ .body = ui.empty(.{ .title = "Not shared", .text = "Invite people to edit this list with you.", .action = ui.button(.{ .label = "Invite…" }) }) }),
        ui.card(.{ .body = ui.setting(.{ .label = "Cache size", .control = ui.stepper(.{ .name = "cache", .label = "Cache size in GB", .value = 4, .min = 1, .max = 32, .z = d.save }) }) }),
        ui.card(.{ .body = "Nothing archived yet." }),
    } }).render(w);
    try ui.tabs(.{ .id = "demo-tabs-full", .full_width = true, .label = "Sort order", .labels = &.{ "Name", "Date", "Size" }, .selected = 1, .panels = .{
        "Sorted by name.", "Sorted by date.", "Sorted by size.",
    } }).render(w);
}
