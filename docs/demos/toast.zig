//! Live demos for docs/pages/components/toast.md (```demo toast``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "toast", false, toast },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/toast/x", handler }`.
pub const routes = .{
    .{ "POST /demo/toast", toastDemo },
};

/// The toast a demo button asks for (`POST /demo/toast?k=...`).
fn toastFor(k: []const u8) ui.Toast {
    if (std.mem.eql(u8, k, "error")) return ui.toast(.{ .text = "Couldn't save: the disk is full", .kind = .@"error" });
    if (std.mem.eql(u8, k, "warning")) return ui.toast(.{ .text = "Storage is almost full", .kind = .warning });
    // The action closes the toast through the empty 200 that DELETE /demo/todo answers.
    if (std.mem.eql(u8, k, "undo")) return ui.toast(.{
        .text = "Reminder deleted",
        .action = "Undo",
        .z = .{ .delete = "/demo/todo", .target = "closest .zw-toast", .swap = .delete },
        .sticky = true,
    });
    return ui.toast(.{ .text = "Saved", .kind = .success });
}

fn toastDemo(c: *zw.Ctx) !void {
    try c.page(toastFor(c.query("k") orelse ""));
}

fn toast(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}", .{
        .a = ui.button(.{ .label = "Save", .variant = .primary, .z = .{ .post = "/demo/toast?k=success", .swap = .none } }),
        .b = ui.button(.{ .label = "Fail", .z = .{ .post = "/demo/toast?k=error", .swap = .none } }),
        .c = ui.button(.{ .label = "Warn", .z = .{ .post = "/demo/toast?k=warning", .swap = .none } }),
        .d = ui.button(.{ .label = "Delete with Undo", .z = .{ .post = "/demo/toast?k=undo", .swap = .none } }),
    }).render(w);
}
