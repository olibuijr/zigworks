//! Live demos for docs/pages/components/progress.md (```demo progress``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "progress", true, progress },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/progress/x", handler }`.
pub const routes = .{};

fn progress(w: *Writer) Writer.Error!void {
    try zw.view(
        "<div class=\"zw-stack\" style=\"width:100%\">{a}{b}{c}" ++
            "<div class=\"zw-row\" style=\"gap:20px\">{d}{e}{f}{g}{h}</div></div>",
        .{
            .a = ui.progress(.{ .value = 42, .label = "Download", .text = "Downloading Xcode", .show_value = true }),
            .b = ui.progress(.{ .value = 88, .label = "Storage", .text = "Storage almost full", .show_value = true, .tone = .warning }),
            .c = ui.progress(.{ .value = 100, .label = "Backup", .tone = .success, .size = .large }),
            .d = ui.progress(.{ .value = null, .label = "Indexing", .text = "Indexing…" }),
            .e = ui.progress(.{ .value = 64, .label = "Storage used", .ring = true, .show_value = true }),
            .f = ui.progress(.{ .value = 100, .label = "Done", .ring = true, .size = .small, .tone = .success }),
            .g = ui.progress(.{ .value = 30, .label = "Upload failed", .ring = true, .size = .large, .show_value = true, .tone = .@"error" }),
            .h = ui.progress(.{ .value = null, .label = "Syncing", .size = .large }),
        },
    ).render(w);
}
