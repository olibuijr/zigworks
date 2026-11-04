//! Live demos for docs/pages/components/tag.md (```demo tag``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "tag", false, tag },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/tag/x", handler }`.
pub const routes = .{};

fn tag(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-tags\">{a}{b}{c}</div><div class=\"zw-tags\">{d}{e}{f}{g}</div><div class=\"zw-tags\">{h}{i}{j}{k}</div>", .{
        .a = ui.tag(.{ .text = "zig" }),
        .b = ui.tag(.{ .text = "web", .remove = .{ .delete = "/demo/todo" } }),
        .c = ui.tag(.{ .text = "liquid glass", .remove = .{ .delete = "/demo/todo" } }),
        .d = ui.tag(.{ .text = "Design", .tone = .gray, .icon = "✎" }),
        .e = ui.tag(.{ .text = "Shipped", .tone = .green, .icon = "✓" }),
        .f = ui.tag(.{ .text = "Blocked", .tone = .red, .size = .small }),
        .g = ui.tag(.{ .text = "Docs", .href = "/", .tone = .orange, .size = .large }),
        .h = ui.tag(.{ .text = "Open", .name = "state", .value = "open", .selected = true }),
        .i = ui.tag(.{ .text = "Closed", .name = "state", .value = "closed" }),
        .j = ui.tag(.{ .text = "Mine", .name = "mine", .tone = .green }),
        .k = ui.tag(.{ .text = "Archived", .name = "archived", .disabled = true }),
    }).render(w);
}
