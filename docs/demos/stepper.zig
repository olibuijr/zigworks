//! Live demos for docs/pages/components/stepper.md (```demo stepper``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "stepper", false, stepper },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/stepper/x", handler }`.
pub const routes = .{};

fn stepper(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%\">{a}{b}{c}{d}</div>", .{
        .a = ui.setting(.{ .label = "Copies", .control = ui.stepper(.{ .name = "copies", .label = "Copies", .value = 1, .min = 1, .max = 9, .z = d.save }) }),
        .b = ui.setting(.{ .label = "Cache size", .control = ui.stepper(.{ .name = "cache-gb", .label = "Cache size", .value = 4, .min = 1, .max = 32, .unit = "GB", .z = d.save }) }),
        .c = ui.setting(.{ .label = "Hour", .control = ui.stepper(.{ .name = "hour", .label = "Hour", .value = 23, .min = 0, .max = 23, .wrap = true, .editable = false, .z = d.save }) }),
        .d = ui.setting(.{ .label = "Retries", .control = ui.stepper(.{ .name = "retries", .label = "Retries", .value = 3, .min = 0, .max = 5, .disabled = true }) }),
    }).render(w);
}
