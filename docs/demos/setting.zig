//! Live demos for docs/pages/components/setting.md (```demo setting``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "setting", true, setting },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/setting/x", handler }`.
pub const routes = .{};

fn setting(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{d}", .{
        .a = ui.setting(.{ .label = "Appearance", .description = "Applies to every window.", .control = ui.segmented(.{ .name = "look", .label = "Appearance", .z = d.save, .options = &.{ .{ .value = "light", .label = "Light" }, .{ .value = "dark", .label = "Dark" }, .{ .value = "auto", .label = "Auto", .selected = true } } }) }),
        .b = ui.toggle(.{ .name = "sounds", .label = "Play sounds", .on = true, .z = d.save }),
        .c = ui.setting(.{ .label = "Sync", .description = "Turned off by your administrator.", .disabled = true, .control = ui.stepper(.{ .name = "sync", .label = "Sync interval in minutes", .value = 15, .min = 5, .max = 60 }) }),
        .d = ui.setting(.{ .label = "Wi-Fi", .icon = "📶", .href = "#setting-wifi", .control = "Home" }),
    }) }).render(w);
}
