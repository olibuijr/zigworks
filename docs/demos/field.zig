//! Live demos for docs/pages/components/field.md (```demo field``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "field", true, field },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/field/x", handler }`.
pub const routes = .{};

fn field(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}", .{
        .a = ui.field(.{ .name = "email", .label = "Email", .placeholder = "name@example.com", .type = "email", .autocomplete = "email", .help = "We only use it to send the receipt." }),
        .b = ui.field(.{ .name = "weight", .label = "Weight", .type = "number", .value = "72", .suffix = "kg", .inputmode = "decimal" }),
        .c = ui.field(.{ .name = "price", .label = "Price", .placeholder = "0.00", .prefix = "$", .inputmode = "decimal", .pattern = "[0-9]+(\\.[0-9]{2})?" }),
        .d = ui.field(.{ .name = "username", .label = "Username", .value = "ab", .invalid = "Use at least 3 characters.", .maxlength = 20 }),
        .e = ui.field(.{ .name = "id", .label = "Account ID", .value = "ZW-1042", .readonly = true, .help = "Read only." }),
    }).render(w);
}
