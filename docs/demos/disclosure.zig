//! Live demos for docs/pages/components/disclosure.md (```demo disclosure``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "disclosure", true, disclosure },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/disclosure/x", handler }`.
pub const routes = .{};

fn disclosure(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}<div class=\"zw-stack\" style=\"gap:0;margin-top:16px\">{c}{d}{e}</div>", .{
        .a = ui.disclosure(.{ .title = "What is zigworks?", .open = true, .body = "A small web framework in pure Zig, with a component library in Liquid Glass." }),
        .b = ui.disclosure(.{ .title = "Does it need JavaScript?", .detail = "No", .body = "No. Pages work without it; z.js adds requests, swaps, islands and the glass effects." }),
        .c = ui.disclosure(.{ .title = "Accordion: one open at a time", .name = "demo-faq", .style = .card, .open = true, .detail = "3 items", .body = "Disclosures that share a name close each other." }),
        .d = ui.disclosure(.{ .title = "Second item", .name = "demo-faq", .style = .card, .body = "Opening this one closes the first." }),
        .e = ui.disclosure(.{ .title = "Third item", .name = "demo-faq", .style = .card, .body = "Card style gives each item its own surface." }),
    }).render(w);
}
