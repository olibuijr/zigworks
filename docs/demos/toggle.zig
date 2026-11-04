//! Live demos for docs/pages/components/toggle.md (```demo toggle``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "toggle", true, toggle },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/toggle/x", handler }`.
pub const routes = .{};

fn toggle(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}", .{
        .a = ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .description = "Join known networks automatically", .on = true, .z = d.save }),
        .b = ui.toggle(.{ .name = "bt", .label = "Bluetooth", .z = d.save }),
        .c = ui.toggle(.{ .name = "small", .label = "Small switch", .size = .small, .on = true, .z = d.save }),
        .d = ui.toggle(.{ .name = "mini", .label = "Mini switch, label after", .size = .mini, .label_side = .trailing, .on = true, .z = d.save }),
        .e = ui.toggle(.{ .name = "lock", .label = "Managed by your administrator", .disabled = true, .on = true }),
    }).render(w);
}
