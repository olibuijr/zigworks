//! Avatar: a person's picture, or their initials on a color picked from their name (stable
//! across pages, like Contacts and Messages). Wrap several in `<div class="zw-avatars">` for an
//! overlapping stack; `more` draws the "+N" overflow chip at its end.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-avatar{--ring:max(1.5px,calc(var(--s)*.06));position:relative;display:inline-grid;place-items:center;flex:none;width:var(--s);height:var(--s);border-radius:50%;color:#fff;
    \\font:600 calc(var(--s)*.4)/1 var(--font);letter-spacing:.02em;user-select:none;
    \\background:linear-gradient(oklch(72% .13 var(--h)),oklch(55% .15 var(--h)));box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 .5px rgba(0,0,0,.1)}
    \\.zw-avatar--rounded{border-radius:24%;
    \\& .zw-avatar__status{right:-2px;bottom:-2px}}
    \\.zw-avatar__i{grid-area:1/1;text-box:trim-both cap alphabetic}
    \\.zw-avatar img{grid-area:1/1;width:100%;height:100%;border-radius:inherit;object-fit:cover}
    \\.zw-avatar--more{color:var(--secondary);font-weight:500;background:color-mix(in srgb,var(--label) 12%,var(--content))}
    \\.zw-avatar__status{--d:max(8px,calc(var(--s)*.28));position:absolute;right:0;bottom:0;width:var(--d);height:var(--d);border-radius:50%;background:var(--tertiary);box-shadow:0 0 0 var(--ring) var(--content)}
    \\.zw-avatar__status--online{background:var(--green)}.zw-avatar__status--away{background:var(--orange)}.zw-avatar__status--busy{background:var(--red)}
    \\.zw-avatar__status--offline{background:transparent;box-shadow:inset 0 0 0 max(1.5px,calc(var(--s)*.05)) var(--secondary),0 0 0 var(--ring) var(--content)}
    \\.zw-avatars{display:inline-flex;align-items:center;isolation:isolate;
    \\& .zw-avatar{box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 var(--ring) var(--content)}
    \\& .zw-avatar+.zw-avatar{margin-inline-start:calc(var(--s)*-.3)}}
    \\@media (prefers-contrast:more){.zw-avatar{box-shadow:inset 0 0 0 1px rgba(0,0,0,.35)}}
    \\
;

pub const Shape = enum { circle, rounded };
pub const Status = enum { none, online, away, busy, offline };

pub const Props = struct {
    /// Full name: gives the initials, the color and the accessible label.
    name: []const u8,
    /// Image URL; initials are shown when empty, and while or if the image fails to load.
    src: []const u8 = "",
    /// Diameter in px.
    size: u16 = 32,
    /// `.rounded` is a squircle-like square, for organizations and apps.
    shape: Shape = .circle,
    /// Presence dot at the bottom corner; it is part of the accessible label.
    status: Status = .none,
    /// Overrides the name-derived color with this hue (0-359).
    hue: ?u16 = null,
    /// More than 0 draws a "+N" overflow chip instead of a person (for the end of a stack).
    more: u16 = 0,
};

pub const Avatar = struct {
    p: Props,
    pub fn render(self: Avatar, w: *Writer) Writer.Error!void {
        const p = self.p;
        try w.writeAll("<span class=\"zw-avatar");
        if (p.shape == .rounded) try w.writeAll(" zw-avatar--rounded");
        if (p.more > 0) try w.writeAll(" zw-avatar--more");
        try w.print("\" style=\"--s:{d}px;--h:{d}\" role=\"img\" aria-label=\"", .{ p.size, p.hue orelse hueOf(p.name) });
        if (p.more > 0) {
            try w.print("{d} more", .{p.more});
        } else {
            try writeEscaped(w, p.name);
            if (p.status != .none) try w.print(", {s}", .{@tagName(p.status)});
        }
        try w.writeAll("\">");
        if (p.more > 0) {
            try w.print("<span class=\"zw-avatar__i\">+{d}</span>", .{p.more});
        } else {
            // Initials sit under the image, so they show while it loads and if it never does.
            try w.writeAll("<span class=\"zw-avatar__i\">");
            try initials(w, p.name);
            try w.writeAll("</span>");
            if (p.src.len > 0) {
                try w.writeAll("<img alt=\"\" loading=\"lazy\" decoding=\"async\" draggable=\"false\" src=\"");
                try writeEscaped(w, p.src);
                try w.writeAll("\">");
            }
            if (p.status != .none) try w.print("<i class=\"zw-avatar__status zw-avatar__status--{s}\"></i>", .{@tagName(p.status)});
        }
        try w.writeAll("</span>");
    }
};

/// First letters of the first two words.
fn initials(w: *Writer, name: []const u8) Writer.Error!void {
    var it = std.mem.tokenizeScalar(u8, name, ' ');
    var n: usize = 0;
    while (it.next()) |word| : (n += 1) {
        if (n == 2) break;
        const len = std.unicode.utf8ByteSequenceLength(word[0]) catch 1;
        try writeEscaped(w, word[0..@min(len, word.len)]);
    }
}

fn hueOf(name: []const u8) u32 {
    return @intCast(std.hash.Fnv1a_32.hash(name) % 360);
}

/// `avatar(.{ .name = "Ada Lovelace", .status = .online })`. Stack with `<div class="zw-avatars">`.
pub fn avatar(p: Props) Avatar {
    return .{ .p = p };
}

fn renderTo(p: Props, buf: []u8) ![]const u8 {
    var w: Writer = .fixed(buf);
    try avatar(p).render(&w);
    return w.buffered();
}

test avatar {
    var buf: [512]u8 = undefined;
    const plain = try renderTo(.{ .name = "Ólafur Búi Ó" }, &buf);
    try std.testing.expect(std.mem.find(u8, plain, "<span class=\"zw-avatar__i\">ÓB</span></span>") != null);
    try std.testing.expect(std.mem.find(u8, plain, "aria-label=\"Ólafur Búi Ó\"") != null);

    const pic = try renderTo(.{ .name = "Ada", .src = "/a.jpg", .status = .busy, .shape = .rounded, .hue = 200 }, &buf);
    try std.testing.expect(std.mem.find(u8, pic, "zw-avatar--rounded") != null);
    try std.testing.expect(std.mem.find(u8, pic, "--h:200") != null);
    try std.testing.expect(std.mem.find(u8, pic, "aria-label=\"Ada, busy\"") != null);
    try std.testing.expect(std.mem.find(u8, pic, "<img alt=\"\" loading=\"lazy\" decoding=\"async\" draggable=\"false\" src=\"/a.jpg\">") != null);
    try std.testing.expect(std.mem.find(u8, pic, "zw-avatar__status--busy") != null);

    const more = try renderTo(.{ .name = "", .more = 3 }, &buf);
    try std.testing.expect(std.mem.find(u8, more, "aria-label=\"3 more\"><span class=\"zw-avatar__i\">+3</span></span>") != null);
}
