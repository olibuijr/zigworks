//! Avatar: a person's picture, or their initials on a color picked from their name (stable
//! across pages, like Contacts and Messages).
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-avatar{display:inline-grid;place-items:center;flex:none;width:var(--s);height:var(--s);border-radius:50%;overflow:hidden;color:#fff;
    \\font:600 calc(var(--s) * .4)/1 var(--font);letter-spacing:.02em;user-select:none;
    \\background:linear-gradient(oklch(72% .13 var(--h)),oklch(55% .15 var(--h)));box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 .5px rgba(0,0,0,.1)}
    \\.zw-avatar span{text-box:trim-both cap alphabetic}
    \\.zw-avatar img{width:100%;height:100%;object-fit:cover}
    \\
;

pub const Props = struct {
    /// Full name: gives the initials, the color and the accessible label.
    name: []const u8,
    /// Image URL; initials are shown when empty.
    src: []const u8 = "",
    /// Diameter in px.
    size: u16 = 32,
};

pub const Avatar = struct {
    p: Props,
    pub fn render(self: Avatar, w: *Writer) Writer.Error!void {
        try w.print("<span class=\"zw-avatar\" style=\"--s:{d}px;--h:{d}\" role=\"img\" aria-label=\"", .{ self.p.size, hue(self.p.name) });
        try writeEscaped(w, self.p.name);
        try w.writeAll("\">");
        if (self.p.src.len > 0) {
            try w.writeAll("<img alt=\"\" src=\"");
            try writeEscaped(w, self.p.src);
            try w.writeAll("\">");
        } else {
            try w.writeAll("<span>");
            var it = std.mem.tokenizeScalar(u8, self.p.name, ' ');
            var n: usize = 0;
            while (it.next()) |word| : (n += 1) {
                if (n == 2) break;
                try writeEscaped(w, word[0..std.unicode.utf8ByteSequenceLength(word[0]) catch 1]);
            }
            try w.writeAll("</span>");
        }
        try w.writeAll("</span>");
    }
};

fn hue(name: []const u8) u32 {
    return @intCast(std.hash.Fnv1a_32.hash(name) % 360);
}

pub fn avatar(p: Props) Avatar {
    return .{ .p = p };
}

test avatar {
    var buf: [256]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try avatar(.{ .name = "Ólafur Búi Ó" }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "><span>ÓB</span></span>") != null);
}
