//! Live demos for docs/pages/components/slider.md (```demo slider``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "slider", true, slider },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/slider/x", handler }`.
pub const routes = .{};

fn slider(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%\">{a}{b}{c}{d}</div>", .{
        .a = ui.setting(.{ .label = "Volume", .control = ui.slider(.{ .name = "volume", .label = "Volume", .value = 70, .show_value = true, .unit = "%", .z = d.save }) }),
        .b = ui.setting(.{ .label = "Quality", .control = ui.slider(.{ .name = "quality", .label = "Quality", .min = 0, .max = 4, .value = 2, .ticks = 4, .min_label = "Low", .max_label = "High", .z = d.save }) }),
        .c = ui.setting(.{ .label = "Text size", .control = ui.slider(.{ .name = "text-size", .label = "Text size", .min = 10, .max = 20, .value = 13, .ticks = 10, .show_value = true, .unit = " pt", .z = d.save }) }),
        .d = ui.setting(.{ .label = "Brightness", .control = ui.slider(.{ .name = "brightness", .label = "Brightness", .value = 40, .disabled = true }) }),
    }).render(w);
}
