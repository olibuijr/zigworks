//! Live demos for docs/pages/components/sheet.md (```demo sheet``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "sheet", false, sheet },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/sheet/x", handler }`.
pub const routes = .{};

fn sheet(w: *Writer) Writer.Error!void {
    try zw.view("{open}{info}{sheet}{about}", .{
        .open = ui.button(.{ .label = "Rename…", .opens = "demo-sheet" }),
        .info = ui.button(.{ .label = "About…", .opens = "demo-sheet-about" }),
        .sheet = ui.sheet(.{
            .id = "demo-sheet",
            .title = "Rename Project",
            .description = "Names can be changed any time.",
            .size = .small,
            .close = true,
            .body = zw.view("<form{z}>{f}<div class=\"zw-sheet-actions\">{c}{ok}</div></form>", .{
                .z = d.save,
                .f = ui.field(.{ .name = "name", .label = "Project name", .value = "zigworks" }),
                .c = ui.button(.{ .label = "Cancel", .opens = "demo-sheet" }),
                .ok = ui.button(.{ .label = "Rename", .variant = .primary, .type = .submit }),
            }),
        }),
        .about = ui.sheet(.{
            .id = "demo-sheet-about",
            .title = "About zigworks",
            .description = "A large sheet with a footer row.",
            .size = .large,
            .body = zw.view("<p>A small web framework in pure Zig. Components render at comptime, so a page is a few string writes.</p>", .{}),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .opens = "demo-sheet-about" }),
        }),
    }).render(w);
}
