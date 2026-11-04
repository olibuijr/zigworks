//! Live demos for docs/pages/components/callout.md (```demo callout``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "callout", true, callout },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/callout/x", handler }`.
pub const routes = .{};

fn callout(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"width:100%\">{a}{b}{c}{d}{e}{f}</div>", .{
        .a = ui.callout(.{ .title = "Note", .body = "Routes are matched in order." }),
        .b = ui.callout(.{ .kind = .tip, .title = "Tip", .body = "Run zig build e2e before you ship." }),
        .c = ui.callout(.{ .kind = .warning, .title = "Warning", .body = "No idle timeout yet: use a reverse proxy." }),
        .d = ui.callout(.{ .kind = .important, .title = "Important", .body = "Handlers must not keep the Ctx after returning." }),
        .e = ui.callout(.{ .kind = .caution, .title = "Caution", .body = "Deleting a site removes its backups too." }),
        .f = ui.callout(.{ .kind = .tip, .body = "Compact, for dense UI.", .compact = true }),
    }).render(w);
}
