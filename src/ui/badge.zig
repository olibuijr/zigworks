//! Count or status badge. Tones follow the system colors; `solid` is the filled notification
//! badge, `dot` the bare status dot, and `count` clamps big numbers to "99+".
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-badge{--tone:var(--secondary);display:inline-block;min-width:22px;padding:2px 8px;border-radius:999px;font:var(--callout);font-weight:600;font-variant-numeric:tabular-nums;text-align:center;white-space:nowrap;
    \\background:var(--fill);color:var(--secondary);box-shadow:inset 0 0 0 .5px var(--separator)}
    \\.zw-badge--accent{--tone:var(--accent)}.zw-badge--red{--tone:var(--red)}.zw-badge--green{--tone:var(--green)}.zw-badge--orange{--tone:var(--orange)}
    \\.zw-badge:is(.zw-badge--accent,.zw-badge--red,.zw-badge--green,.zw-badge--orange){color:color-mix(in srgb,var(--tone) 85%,var(--label));background:color-mix(in srgb,var(--tone) 14%,transparent);
    \\box-shadow:inset 0 0 0 .5px color-mix(in srgb,var(--tone) 28%,transparent)}
    \\.zw-badge.zw-badge--solid{color:#fff;background:var(--tone);box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 .5px rgba(0,0,0,.08)}
    \\.zw-badge--small{min-width:16px;padding:1px 6px;font:var(--footnote);font-weight:600}
    \\.zw-badge.zw-badge--dot{vertical-align:middle;min-width:0;width:8px;height:8px;padding:0;background:var(--tone);box-shadow:0 0 0 .5px rgba(0,0,0,.1);
    \\&.zw-badge--small{width:6px;height:6px}}
    \\.zw-badge[hidden]{display:none}
    \\.zw-badge[z-oob]{animation:zw-pop var(--dur-bouncy) var(--spring-bouncy)}
    \\@media (prefers-contrast:more){.zw-badge:not(.zw-badge--solid,.zw-badge--dot){box-shadow:inset 0 0 0 1px var(--secondary);color:var(--label)}}
    \\
;

pub const Tone = enum { gray, accent, red, green, orange };
pub const Size = enum { small, regular };

pub const Props = struct {
    /// Label. For a `dot` it is the accessible name (a dot with no text is decorative). With no
    /// `text` and no `count` the badge renders `hidden` instead of an empty pill.
    text: []const u8 = "",
    id: []const u8 = "",
    /// Out-of-band: in a z.js response, replaces the element with the same `id`.
    oob: bool = false,
    tone: Tone = .gray,
    size: Size = .regular,
    /// Filled with the tone color and white text (the red notification badge).
    solid: bool = false,
    /// A bare status dot with no text.
    dot: bool = false,
    /// Shows this number instead of `text`; above `max` it reads "<max>+".
    count: ?u32 = null,
    max: u32 = 99,
    /// With `count`: stays in the page (so `oob` can find it) but hidden while the count is 0.
    hide_zero: bool = false,
};

pub const Badge = struct {
    p: Props,
    pub fn render(self: Badge, w: *Writer) Writer.Error!void {
        const p = self.p;
        try w.print("<span class=\"zw-badge zw-badge--{s}", .{@tagName(p.tone)});
        if (p.size == .small) try w.writeAll(" zw-badge--small");
        if (p.solid) try w.writeAll(" zw-badge--solid");
        if (p.dot) try w.writeAll(" zw-badge--dot");
        try w.writeByte('"');
        if (p.id.len > 0) {
            try w.writeAll(" id=\"");
            try writeEscaped(w, p.id);
            try w.writeByte('"');
        }
        if (p.oob) try w.writeAll(" z-oob");
        // An empty badge (no text, no count, not a dot) or a zero count with `hide_zero` stays in
        // the page, hidden, so `oob` can fill it later.
        if (p.hide_zero and p.count != null and p.count.? == 0) try w.writeAll(" hidden") else if (!p.dot and p.count == null and p.text.len == 0) try w.writeAll(" hidden");
        if (p.dot) {
            if (p.text.len > 0) {
                try w.writeAll(" role=\"img\" aria-label=\"");
                try writeEscaped(w, p.text);
                try w.writeByte('"');
            } else try w.writeAll(" aria-hidden=\"true\"");
            try w.writeAll("></span>");
            return;
        }
        try w.writeByte('>');
        if (p.count) |n| {
            if (n > p.max) try w.print("{d}+", .{p.max}) else try w.print("{d}", .{n});
        } else try writeEscaped(w, p.text);
        try w.writeAll("</span>");
    }
};

/// `badge(.{ .text = "3 left" })`, `badge(.{ .count = 120, .tone = .red, .solid = true })`,
/// `badge(.{ .dot = true, .tone = .green, .text = "Online" })`.
pub fn badge(p: Props) Badge {
    return .{ .p = p };
}

fn expectHtml(expected: []const u8, p: Props) !void {
    var buf: [256]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try badge(p).render(&w);
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test badge {
    try expectHtml("<span class=\"zw-badge zw-badge--gray\" id=\"n\" z-oob>3 &lt;</span>", .{ .text = "3 <", .id = "n", .oob = true });
    try expectHtml("<span class=\"zw-badge zw-badge--red zw-badge--solid\">99+</span>", .{ .count = 120, .tone = .red, .solid = true });
    try expectHtml("<span class=\"zw-badge zw-badge--gray\">42</span>", .{ .count = 42 });
    try expectHtml("<span class=\"zw-badge zw-badge--gray\" hidden>0</span>", .{ .count = 0, .hide_zero = true });
    try expectHtml("<span class=\"zw-badge zw-badge--gray\" id=\"n\" z-oob hidden></span>", .{ .id = "n", .oob = true });
    try expectHtml("<span class=\"zw-badge zw-badge--gray\">0</span>", .{ .count = 0 });
    try expectHtml("<span class=\"zw-badge zw-badge--green zw-badge--dot\" role=\"img\" aria-label=\"Online\"></span>", .{ .dot = true, .tone = .green, .text = "Online" });
    try expectHtml("<span class=\"zw-badge zw-badge--gray zw-badge--small zw-badge--dot\" aria-hidden=\"true\"></span>", .{ .dot = true, .size = .small });
}
