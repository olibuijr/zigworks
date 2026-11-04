//! Avatar: a person's picture, or their initials on a color picked from their name (stable
//! across pages, like Contacts and Messages). Wrap several in `<div class="zw-avatars">` for an
//! overlapping stack (each avatar may sit inside a wrapper such as a tooltip); `more` draws the
//! "+N" overflow chip at its end. An empty name, or `neutral`, gives a gray avatar (a silhouette
//! when there are no initials).
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-avatar{--ring:max(1.5px,calc(var(--s)*.06));position:relative;display:inline-grid;place-items:center;flex:none;width:var(--s);height:var(--s);border-radius:50%;color:#fff;
    \\font:600 calc(var(--s)*.4)/1 var(--font);letter-spacing:.02em;user-select:none;
    \\background:linear-gradient(oklch(72% .13 var(--h)),oklch(55% .15 var(--h)));box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 .5px rgba(0,0,0,.1)}
    \\.zw-avatar--rounded{border-radius:24%;
    \\& .zw-avatar__status{right:-2px;bottom:-2px}}
    \\.zw-avatar--neutral{background:linear-gradient(oklch(70% 0 0),oklch(52% 0 0))}
    \\.zw-avatar__i{grid-area:1/1;text-box:trim-both cap alphabetic}
    \\.zw-avatar svg{grid-area:1/1;width:60%;height:60%;fill:currentColor;opacity:.92}
    \\.zw-avatar img{grid-area:1/1;width:100%;height:100%;border-radius:inherit;object-fit:cover}
    \\.zw-avatar--more{color:var(--secondary);font-weight:500;background:color-mix(in srgb,var(--label) 12%,var(--content))}
    \\.zw-avatar__status{--d:max(6px,calc(var(--s)*.28));position:absolute;right:0;bottom:0;width:var(--d);height:var(--d);border-radius:50%;background:var(--tertiary);box-shadow:0 0 0 var(--ring) var(--content)}
    \\.zw-avatar__status--online{background:var(--green)}.zw-avatar__status--away{background:var(--orange)}.zw-avatar__status--busy{background:var(--red)}
    \\.zw-avatar__status--offline{background:transparent;box-shadow:inset 0 0 0 max(1.5px,calc(var(--s)*.05)) var(--secondary),0 0 0 var(--ring) var(--content)}
    \\.zw-avatars{display:inline-flex;align-items:center;isolation:isolate;
    \\& .zw-avatar{box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 var(--ring) var(--content)}
    \\& >.zw-avatar:not(:first-child),& >:not(:first-child) .zw-avatar{margin-inline-start:calc(var(--s)*-.3)}}
    \\@media (prefers-contrast:more){.zw-avatar{box-shadow:inset 0 0 0 1px rgba(0,0,0,.35)}}
    \\
;

pub const Shape = enum { circle, rounded };
pub const Status = enum { none, online, away, busy, offline };

pub const Props = struct {
    /// Full name: gives the initials, the color and the accessible label. Empty (the default, and
    /// what `more` wants) draws an anonymous gray avatar labelled "Anonymous".
    name: []const u8 = "",
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
    /// Gray instead of a name-derived color, for someone unnamed or a color-free list.
    neutral: bool = false,
};

pub const Avatar = struct {
    p: Props,
    pub fn render(self: Avatar, w: *Writer) Writer.Error!void {
        const p = self.p;
        const anon = std.mem.trim(u8, p.name, " \t\r\n").len == 0;
        try w.writeAll("<span class=\"zw-avatar");
        if (p.more == 0 and (p.neutral or anon)) try w.writeAll(" zw-avatar--neutral");
        if (p.shape == .rounded) try w.writeAll(" zw-avatar--rounded");
        if (p.more > 0) try w.writeAll(" zw-avatar--more");
        try w.print("\" style=\"--s:{d}px;--h:{d}\" role=\"img\" aria-label=\"", .{ p.size, p.hue orelse hueOf(p.name) });
        if (p.more > 0) {
            try w.print("{d} more", .{p.more});
        } else {
            try writeEscaped(w, if (anon) "Anonymous" else p.name);
            if (p.status != .none) try w.print(", {s}", .{@tagName(p.status)});
        }
        try w.writeAll("\">");
        if (p.more > 0) {
            try w.print("<span class=\"zw-avatar__i\">+{d}</span>", .{p.more});
        } else {
            // Initials sit under the image, so they show while it loads and if it never does.
            if (anon) {
                try w.writeAll("<svg viewBox=\"0 0 24 24\" aria-hidden=\"true\"><circle cx=\"12\" cy=\"9\" r=\"4.5\"/><path d=\"M3.5 22c.8-5 4.4-7.5 8.5-7.5s7.7 2.5 8.5 7.5z\"/></svg>");
            } else {
                try w.writeAll("<span class=\"zw-avatar__i\">");
                try initials(w, p.name);
                try w.writeAll("</span>");
            }
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

/// First letter (with its combining marks, emoji modifiers and joined parts) of the first two words.
fn initials(w: *Writer, name: []const u8) Writer.Error!void {
    var it = std.mem.tokenizeAny(u8, name, " \t\r\n");
    var n: usize = 0;
    while (it.next()) |word| : (n += 1) {
        if (n == 2) break;
        try writeEscaped(w, word[0..clusterLen(word)]);
    }
}

/// Byte length of the first user-perceived character: a code point plus the marks, variation
/// selectors, skin tones and zero-width-joined code points that follow it (and a flag's second half).
fn clusterLen(s: []const u8) usize {
    var i: usize = 0;
    var joined = false;
    var flag = false;
    while (i < s.len) {
        const n = @min(std.unicode.utf8ByteSequenceLength(s[i]) catch 1, s.len - i);
        const cp = std.unicode.utf8Decode(s[i..][0..n]) catch 0xFFFD;
        const ri = cp >= 0x1F1E6 and cp <= 0x1F1FF;
        const extends = switch (cp) {
            0x300...0x36F, 0x1AB0...0x1AFF, 0x1DC0...0x1DFF, 0x20D0...0x20FF, 0xFE00...0xFE0F, 0xFE20...0xFE2F, 0x1F3FB...0x1F3FF, 0xE0020...0xE007F, 0x200D => true,
            else => ri and flag,
        };
        if (i > 0 and !joined and !extends) break;
        flag = i == 0 and ri;
        joined = cp == 0x200D;
        i += n;
    }
    return i;
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
    var buf: [768]u8 = undefined;
    const plain = try renderTo(.{ .name = "Ásta Sigurðardóttir" }, &buf);
    try std.testing.expect(std.mem.find(u8, plain, "<span class=\"zw-avatar__i\">ÁS</span></span>") != null);
    try std.testing.expect(std.mem.find(u8, plain, "aria-label=\"Ásta Sigurðardóttir\"") != null);

    const pic = try renderTo(.{ .name = "Ada", .src = "/a.jpg", .status = .busy, .shape = .rounded, .hue = 200 }, &buf);
    try std.testing.expect(std.mem.find(u8, pic, "zw-avatar--rounded") != null);
    try std.testing.expect(std.mem.find(u8, pic, "--h:200") != null);
    try std.testing.expect(std.mem.find(u8, pic, "aria-label=\"Ada, busy\"") != null);
    try std.testing.expect(std.mem.find(u8, pic, "<img alt=\"\" loading=\"lazy\" decoding=\"async\" draggable=\"false\" src=\"/a.jpg\">") != null);
    try std.testing.expect(std.mem.find(u8, pic, "zw-avatar__status--busy") != null);

    const more = try renderTo(.{ .more = 3 }, &buf);
    try std.testing.expect(std.mem.find(u8, more, "aria-label=\"3 more\"><span class=\"zw-avatar__i\">+3</span></span>") != null);
    try std.testing.expect(std.mem.find(u8, more, "zw-avatar--neutral") == null);

    // No name: gray silhouette, labelled; `neutral` keeps the initials.
    const anon = try renderTo(.{ .status = .online }, &buf);
    try std.testing.expect(std.mem.find(u8, anon, "zw-avatar zw-avatar--neutral") != null);
    try std.testing.expect(std.mem.find(u8, anon, "aria-label=\"Anonymous, online\"") != null);
    try std.testing.expect(std.mem.find(u8, anon, "<svg") != null and std.mem.find(u8, anon, "zw-avatar__i") == null);
    const gray = try renderTo(.{ .name = "Ada Lovelace", .neutral = true }, &buf);
    try std.testing.expect(std.mem.find(u8, gray, "zw-avatar--neutral") != null);
    try std.testing.expect(std.mem.find(u8, gray, ">AL</span>") != null);

    // Initials keep combining marks, emoji modifiers, ZWJ sequences and flags whole.
    const marks = try renderTo(.{ .name = "e\u{301}mile \u{1F44D}\u{1F3FD}" }, &buf);
    try std.testing.expect(std.mem.find(u8, marks, ">e\u{301}\u{1F44D}\u{1F3FD}</span>") != null);
    try std.testing.expectEqual(@as(usize, 11), clusterLen("\u{1F469}\u{200D}\u{1F4BB}x"));
    try std.testing.expectEqual(@as(usize, 8), clusterLen("\u{1F1EE}\u{1F1F8}\u{1F1EE}"));
}
