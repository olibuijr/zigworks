//! Skeleton: placeholder lines with a soft shimmer while content loads. Pair it with
//! `z-trigger="load"` to swap in the real content. Still under Reduce Motion.
const std = @import("std");
const Writer = std.Io.Writer;

pub const css =
    \\.zw-skeleton{display:flex;flex-direction:column;gap:9px}
    \\.zw-skeleton span{display:block;height:12px;border-radius:6px;background:linear-gradient(90deg,var(--fill) 30%,var(--fill-strong) 50%,var(--fill) 70%) 0 0/300% 100%;
    \\animation:zw-shimmer 1.6s ease-in-out infinite}
    \\.zw-skeleton span:last-child:not(:first-child){width:62%}
    \\@keyframes zw-shimmer{from{background-position:100% 0}to{background-position:0 0}}
    \\
;

pub const Props = struct { lines: u8 = 3, label: []const u8 = "Loading" };

pub const Skeleton = struct {
    p: Props,
    pub fn render(self: Skeleton, w: *Writer) Writer.Error!void {
        try w.writeAll("<div class=\"zw-skeleton\" role=\"status\" aria-busy=\"true\" aria-label=\"");
        try @import("../view.zig").writeEscaped(w, self.p.label);
        try w.writeAll("\">");
        for (0..@max(self.p.lines, 1)) |_| try w.writeAll("<span></span>");
        try w.writeAll("</div>");
    }
};

pub fn skeleton(p: Props) Skeleton {
    return .{ .p = p };
}
