//! Live demos for docs/pages/components/kbd.md (```demo kbd``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "kbd", false, kbd },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/kbd/x", handler }`.
pub const routes = .{};

fn kbd(w: *Writer) Writer.Error!void {
    try zw.view("<span>Search the docs</span>{a}<span style=\"margin-left:16px\">New window</span>{b}<span style=\"margin-left:16px\">Quit</span>{c}" ++
        "<span style=\"margin-left:16px\">On Windows</span>{d}<span style=\"margin-left:16px\">Go to Inbox</span>{e}<span style=\"margin-left:16px\">Menu style</span>{f}<span style=\"margin-left:16px\">Large</span>{g}", .{
        .a = ui.kbd(.{ .keys = "⌘ K" }),
        .b = ui.kbd(.{ .keys = "⌘ ⇧ N" }),
        .c = ui.kbd(.{ .keys = "cmd q", .size = .small }),
        .d = ui.kbd(.{ .keys = "cmd shift p", .platform = .pc }),
        .e = ui.kbd(.{ .keys = "g i", .joiner = "then" }),
        .f = ui.kbd(.{ .keys = "⌘ ⌥ esc", .plain = true }),
        .g = ui.kbd(.{ .keys = "⌃ ⌥ ⌫", .size = .large }),
    }).render(w);
}
