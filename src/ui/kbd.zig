//! Keyboard shortcut: keycaps for a shortcut, like menus show them. Keys are separated by spaces:
//! `kbd(.{ .keys = "⌘ ⇧ K" })`.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-kbd{display:inline-flex;gap:3px;vertical-align:1px}
    \\.zw-kbd kbd{display:inline-grid;place-items:center;min-width:20px;height:20px;padding:0 5px;border-radius:5px;font:500 11px/1 var(--font);color:var(--secondary);
    \\background:var(--content);box-shadow:0 0 0 .5px var(--separator),0 1px 0 var(--fill-strong)}
    \\
;

pub const Props = struct { keys: []const u8 };

pub const Kbd = struct {
    p: Props,
    pub fn render(self: Kbd, w: *Writer) Writer.Error!void {
        try w.writeAll("<span class=\"zw-kbd\">");
        var it = std.mem.tokenizeScalar(u8, self.p.keys, ' ');
        while (it.next()) |k| {
            try w.writeAll("<kbd>");
            try writeEscaped(w, k);
            try w.writeAll("</kbd>");
        }
        try w.writeAll("</span>");
    }
};

pub fn kbd(p: Props) Kbd {
    return .{ .p = p };
}
