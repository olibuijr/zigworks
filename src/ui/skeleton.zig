//! Skeleton: placeholder shapes with a soft shimmer while content loads. Pair it with
//! `z-trigger="load"` to swap in the real content. Still under Reduce Motion.
//! Shapes: text `lines` (default), a `block` (image, card), a `circle` (avatar) or `media`
//! (an avatar next to lines, like a list row).
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-skeleton{--sk-h:12px;--sk-d:40px;display:flex;flex-direction:column;gap:9px;width:100%;max-width:100%}
    \\.zw-skeleton :is(i,span){display:block;height:var(--sk-h);border-radius:calc(var(--sk-h)/2);background:linear-gradient(90deg,var(--fill) 30%,var(--fill-strong) 50%,var(--fill) 70%) 0 0/300% 100%;animation:zw-shimmer 1.6s ease-in-out infinite}
    \\.zw-skeleton span:last-child:not(:first-child){width:var(--sk-last,62%)}
    \\.zw-skeleton--still :is(i,span){animation:none;background:var(--fill)}
    \\.zw-skeleton--block,.zw-skeleton--circle{display:block}
    \\.zw-skeleton--block>i{border-radius:var(--radius-control)}
    \\.zw-skeleton--circle{width:var(--sk-d)}
    \\.zw-skeleton--circle>i,.zw-skeleton--media>i{flex:none;width:var(--sk-d);height:var(--sk-d);border-radius:50%}
    \\.zw-skeleton--media{flex-direction:row;align-items:center;gap:12px;
    \\  &>div{display:flex;flex-direction:column;gap:9px;flex:1;min-width:0}
    \\}
    \\@keyframes zw-shimmer{from{background-position:100% 0}to{background-position:0 0}}
    \\@media (forced-colors:active){.zw-skeleton :is(i,span){forced-color-adjust:none;background:GrayText;opacity:.3}}
    \\
;

pub const Shape = enum { lines, block, circle, media };

pub const Props = struct {
    /// Number of text lines (`.lines` and `.media`).
    lines: u8 = 3,
    label: []const u8 = "Loading",
    shape: Shape = .lines,
    /// Width of the last line in percent (`.lines` and `.media`).
    last_width: u8 = 62,
    /// Height of a `.block`, as a CSS length.
    height: []const u8 = "120px",
    /// Diameter in px of a `.circle` or of the avatar in `.media`.
    size: u16 = 40,
    /// Set false for a still placeholder without the shimmer.
    shimmer: bool = true,
};

pub const Skeleton = struct {
    p: Props,
    pub fn render(self: Skeleton, w: *Writer) Writer.Error!void {
        const p = self.p;
        try w.print("<div class=\"zw-skeleton zw-skeleton--{s}{s}\" role=\"status\" aria-busy=\"true\" aria-label=\"", .{ @tagName(p.shape), if (p.shimmer) "" else " zw-skeleton--still" });
        try writeEscaped(w, p.label);
        try w.print("\" style=\"--sk-last:{d}%;--sk-d:{d}px", .{ @min(p.last_width, 100), p.size });
        if (p.shape == .block) {
            try w.writeAll(";--sk-h:");
            try writeEscaped(w, p.height);
        }
        try w.writeAll("\">");
        switch (p.shape) {
            .lines => try writeLines(w, p.lines),
            .block, .circle => try w.writeAll("<i></i>"),
            .media => {
                try w.writeAll("<i></i><div>");
                try writeLines(w, p.lines);
                try w.writeAll("</div>");
            },
        }
        try w.writeAll("</div>");
    }
};

fn writeLines(w: *Writer, n: u8) Writer.Error!void {
    for (0..@max(n, 1)) |_| try w.writeAll("<span></span>");
}

pub fn skeleton(p: Props) Skeleton {
    return .{ .p = p };
}

fn expectHas(p: Props, needle: []const u8) !void {
    var buf: [1024]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try skeleton(p).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), needle) != null);
}

test "shapes" {
    try expectHas(.{ .lines = 2 }, "<span></span><span></span></div>");
    try expectHas(.{ .shape = .block, .height = "80px" }, "--sk-h:80px\"><i></i></div>");
    try expectHas(.{ .shape = .circle, .size = 56 }, "--sk-d:56px");
    try expectHas(.{ .shape = .media, .lines = 2 }, "<i></i><div><span></span><span></span></div>");
    try expectHas(.{ .shimmer = false }, "zw-skeleton--still");
}
