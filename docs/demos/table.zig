//! Live demos for docs/pages/components/table.md (```demo table``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "table", true, table },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/table/x", handler }`.
pub const routes = .{};

fn table(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%;min-width:0\">{a}{b}{c}</div>", .{
        .a = ui.table(.{ .head = &.{ "Method", "Path", "Handler" }, .rows = &.{
            &.{ "GET", "/", "index" },
            &.{ "POST", "/todos", "create" },
            &.{ "DELETE", "/todos/:id", "remove" },
        } }),
        .b = ui.table(.{
            .caption = "Disk usage",
            .head = &.{ "Volume", "Used", "Free" },
            .aligns = &.{ .left, .right, .right },
            .rows = &.{
                &.{ "System", "41.2 GB", "22.8 GB" },
                &.{ "Backups", "310 GB", "190 GB" },
                &.{ "Photos", "88.6 GB", "11.4 GB" },
            },
            .striped = true,
            .row_header = true,
        }),
        .c = ui.table(.{ .head = &.{ "Name", "Role" }, .rows = &.{}, .empty = "No members yet", .compact = true }),
    }).render(w);
}
