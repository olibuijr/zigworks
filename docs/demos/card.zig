//! Live demos for docs/pages/components/card.md (```demo card``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "card", true, card },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/card/x", handler }`.
pub const routes = .{};

fn card(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Storage",
        .subtitle = "Macintosh HD",
        .accessory = ui.button(.{ .label = "Manage…", .variant = .plain }),
        .footer = "Updated just now",
        .body = zw.view("<p style=\"margin-bottom:10px\">41.2 GB of 64 GB used</p>{p}", .{ .p = ui.progress(.{ .value = 64, .label = "Storage used" }) }),
    }).render(w);
    try ui.card(.{
        .variant = .inset,
        .title = "Share this list",
        .body = "Anyone with the link can view and edit.",
        .footer = zw.view("{a}{b}", .{ .a = ui.button(.{ .label = "Cancel" }), .b = ui.button(.{ .label = "Copy Link", .variant = .primary }) }),
    }).render(w);
    try ui.card(.{ .href = "#card-link", .title = "zigworks", .subtitle = "A link card: the whole surface is the target", .body = "Updated today" }).render(w);
}
