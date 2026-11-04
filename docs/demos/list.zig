//! Live demos for docs/pages/components/list.md (```demo list``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "list", true, list },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/list/x", handler }`.
pub const routes = .{};

fn row(done: bool, title: []const u8) zw.View("<li>{c}<span class=\"zw-grow\">{t}</span></li>", struct { c: ui.Check, t: []const u8 }) {
    return .{ .data = .{ .c = ui.check(.{ .on = done, .label = title }), .t = title } };
}

fn list(w: *Writer) Writer.Error!void {
    try ui.list(.{ .id = "demo-list", .body = zw.view("{a}{b}{c}", .{ .a = row(true, "Renew domain"), .b = row(false, "Write release notes"), .c = row(false, "Tag v0.2.0") }) }).render(w);
    try ui.list(.{
        .id = "demo-nav",
        .header = "Network",
        .footer = "Rows are links: the whole row is the target.",
        .nav = true,
        .body = zw.view("<li><a href=\"#demo-nav\">Wi-Fi</a></li><li><a href=\"#demo-nav\">Bluetooth</a></li><li><a href=\"#demo-nav\">VPN</a></li>", .{}),
    }).render(w);
    try ui.list(.{
        .id = "demo-reveal",
        .header = "Drafts",
        .reveal = true,
        .separators = .full,
        .body = zw.view("<li><span class=\"zw-grow\">Launch notes</span>{a}</li><li><span class=\"zw-grow\">Old plan</span>{b}</li>", .{
            .a = ui.button(.{ .label = "Delete", .variant = .destructive }),
            .b = ui.button(.{ .label = "Delete", .variant = .destructive }),
        }),
    }).render(w);
}
