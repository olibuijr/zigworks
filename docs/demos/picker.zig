//! Live demos for docs/pages/components/picker.md (```demo picker``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "picker", false, picker },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/picker/x", handler }`.
pub const routes = .{};

fn picker(w: *Writer) Writer.Error!void {
    const doc = "<svg viewBox=\"0 0 16 16\"><path d=\"M3 1h6l4 4v10H3zm5 1v4h4z\"/></svg>";
    const clock = "<svg viewBox=\"0 0 16 16\"><path d=\"M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm1 3v4l3 2-.8 1.2L7 9V4z\"/></svg>";
    try zw.view("{a}{b}{c}", .{
        .a = ui.picker(.{ .id = "demo-picker", .name = "sort", .label = "Sort by", .z = d.save, .options = &.{ .{ .value = "name", .label = "Name", .selected = true }, .{ .value = "date", .label = "Date Modified" }, .{ .value = "size", .label = "Size" } } }),
        .b = ui.picker(.{ .id = "demo-picker-rich", .name = "group", .label = "Group by", .placeholder = "Group by…", .z = d.save, .options = &.{
            .{ .value = "none", .label = "None", .description = "A flat list" },
            .{ .value = "kind", .label = "Kind", .icon = doc, .heading = "Attributes", .description = "Documents, folders, images" },
            .{ .value = "date", .label = "Date Added", .icon = clock },
            .{ .value = "tags", .label = "Tags", .separated = true, .disabled = true },
        } }),
        .c = ui.picker(.{ .id = "demo-picker-off", .name = "sort-off", .label = "Sort by", .disabled = true, .options = &.{.{ .value = "name", .label = "Name", .selected = true }} }),
    }).render(w);
}
