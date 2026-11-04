//! Live demos for docs/pages/components/segmented.md (```demo segmented``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "segmented", false, segmented },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/segmented/x", handler }`.
pub const routes = .{};

fn segmented(w: *Writer) Writer.Error!void {
    const grid = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 2h5v5H2zm7 0h5v5H9zM2 9h5v5H2zm7 0h5v5H9z\"/></svg>";
    const rows = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 3h12v2H2zm0 4h12v2H2zm0 4h12v2H2z\"/></svg>";
    try zw.view("<div class=\"zw-stack\" style=\"width:100%\">{a}{b}{c}{d}</div>", .{
        .a = ui.segmented(.{ .name = "view", .label = "View", .z = d.save, .options = &.{ .{ .value = "icons", .label = "Icons", .selected = true }, .{ .value = "list", .label = "List" }, .{ .value = "columns", .label = "Columns" } } }),
        .b = ui.segmented(.{ .name = "view-icons", .label = "Layout", .icons_only = true, .z = d.save, .options = &.{ .{ .value = "grid", .label = "Grid", .icon = grid, .selected = true }, .{ .value = "rows", .label = "Rows", .icon = rows } } }),
        .c = ui.segmented(.{ .name = "view-small", .label = "Range", .size = .small, .z = d.save, .options = &.{ .{ .value = "day", .label = "Day" }, .{ .value = "week", .label = "Week", .selected = true }, .{ .value = "month", .label = "Month" }, .{ .value = "year", .label = "Year", .disabled = true } } }),
        .d = ui.segmented(.{ .name = "view-full", .label = "Sort", .size = .large, .full = true, .z = d.save, .options = &.{ .{ .value = "name", .label = "Name", .icon = rows, .selected = true }, .{ .value = "kind", .label = "Kind", .icon = grid } } }),
    }).render(w);
}
