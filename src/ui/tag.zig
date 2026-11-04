//! Tag: a small capsule label (tokens, filters, categories). Give it `remove` to show a × button
//! that sends that request and deletes the tag, `href` to make it a link, or `name` to make it a
//! filter chip (a checkbox that toggles and submits with its form, no JS).
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-tag{--tone:var(--accent);position:relative;display:inline-flex;align-items:center;height:24px;border-radius:999px;font:var(--callout);font-weight:500;white-space:nowrap;max-width:100%;
    \\color:color-mix(in srgb,var(--tone) 85%,var(--label));background:color-mix(in srgb,var(--tone) 13%,transparent);box-shadow:inset 0 0 0 .5px color-mix(in srgb,var(--tone) 25%,transparent);
    \\transition:background-color var(--speed),color var(--speed),box-shadow var(--speed),opacity var(--speed)}
    \\.zw-tag--gray{--tone:var(--secondary)}.zw-tag--red{--tone:var(--red)}.zw-tag--green{--tone:var(--green)}.zw-tag--orange{--tone:var(--orange)}
    \\.zw-tag--small{height:20px;font:var(--footnote);font-weight:500}
    \\.zw-tag--large{height:28px;font:var(--body);font-weight:500}
    \\.zw-tag__main{display:inline-flex;align-items:center;gap:4px;height:100%;padding:0 10px;border-radius:inherit;color:inherit;text-decoration:none;cursor:default;
    \\-webkit-tap-highlight-color:transparent}
    \\.zw-tag--small .zw-tag__main{padding:0 8px}.zw-tag--large .zw-tag__main{padding:0 12px}
    \\.zw-tag__main:hover{text-decoration:none}
    \\a.zw-tag__main:hover{background:color-mix(in srgb,var(--tone) 12%,transparent)}
    \\.zw-tag__icon{flex:none;font-size:1.05em;line-height:1}
    \\.zw-tag:has(.zw-tag__x) .zw-tag__main{padding-right:4px}
    \\.zw-tag__x{appearance:none;position:relative;flex:none;display:grid;place-items:center;width:18px;height:18px;margin-right:3px;border:0;border-radius:50%;background:transparent;color:inherit;font:600 13px/1 var(--font);cursor:default;
    \\transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-tag--small .zw-tag__x{width:16px;height:16px;margin-right:2px}
    \\.zw-tag--large .zw-tag__x{width:20px;height:20px;margin-right:4px}
    \\.zw-tag__x:hover{background:color-mix(in srgb,var(--tone) 20%,transparent)}
    \\.zw-tag__x:active{scale:.85}
    \\.zw-tag--chip{cursor:default;user-select:none}
    \\.zw-tag--chip input{position:absolute;inset:0;width:100%;height:100%;margin:0;opacity:0;appearance:none;cursor:default}
    \\.zw-tag--selected,.zw-tag:has(input:checked){color:var(--on-accent);background:var(--tone);box-shadow:inset 0 .5px 0 rgba(255,255,255,.35),0 0 0 .5px rgba(0,0,0,.08)}
    \\.zw-tag--selected a.zw-tag__main:hover{background:rgba(255,255,255,.12)}
    \\.zw-tag:has(input:focus-visible){outline:var(--focus-ring);outline-offset:1px}
    \\.zw-tag--disabled{opacity:.4;pointer-events:none}
    \\.zw-tag.zw-busy{opacity:.6}
    \\.zw-tags{display:flex;flex-wrap:wrap;gap:6px}
    \\@media (pointer:coarse){.zw-tag__x::after,a.zw-tag__main::after{content:"";position:absolute;inset:-13px -8px}.zw-tag__main{position:relative}.zw-tag--chip::after{content:"";position:absolute;inset:-10px 0}}
    \\@media (prefers-contrast:more){.zw-tag:not(.zw-tag--selected){color:var(--label);box-shadow:inset 0 0 0 1px var(--secondary)}}
    \\
;

pub const Tone = enum { accent, gray, red, green, orange };
pub const Size = enum { small, regular, large };

pub const Props = struct {
    text: []const u8,
    /// Request sent by the × button; the tag is removed after it succeeds.
    remove: ?Z = null,
    tone: Tone = .accent,
    size: Size = .regular,
    /// A short glyph or emoji before the text (decorative; the text names the tag).
    icon: []const u8 = "",
    /// Makes the tag a link.
    href: []const u8 = "",
    /// Makes the tag a filter chip: a checkbox sent as `name=value` while selected.
    name: []const u8 = "",
    /// Chip value; the text when empty.
    value: []const u8 = "",
    /// Filled style. For a chip it is the initial checked state.
    selected: bool = false,
    disabled: bool = false,
    /// Request fired when a chip is toggled (the chip's `name=value` is sent with it).
    z: Z = .{},
};

pub const Tag = struct {
    p: Props,
    pub fn render(self: Tag, w: *Writer) Writer.Error!void {
        const p = self.p;
        const chip = p.name.len > 0;
        try w.print("<{s} class=\"zw-tag zw-tag--{s}", .{ if (chip) "label" else "span", @tagName(p.tone) });
        if (p.size != .regular) try w.print(" zw-tag--{s}", .{@tagName(p.size)});
        if (chip) try w.writeAll(" zw-tag--chip");
        if (p.selected and !chip) try w.writeAll(" zw-tag--selected");
        if (p.disabled) try w.writeAll(" zw-tag--disabled");
        try w.writeAll("\">");
        if (chip) {
            try w.writeAll("<input type=\"checkbox\" name=\"");
            try writeEscaped(w, p.name);
            try w.writeAll("\" value=\"");
            try writeEscaped(w, if (p.value.len > 0) p.value else p.text);
            try w.writeByte('"');
            if (p.selected) try w.writeAll(" checked");
            if (p.disabled) try w.writeAll(" disabled");
            try p.z.render(w);
            try w.writeAll("><span class=\"zw-tag__main\">");
        } else if (p.href.len > 0 and !p.disabled) {
            try w.writeAll("<a class=\"zw-tag__main\" href=\"");
            try writeEscaped(w, p.href);
            try w.writeByte('"');
            if (p.selected) try w.writeAll(" aria-current=\"true\"");
            try w.writeByte('>');
        } else try w.writeAll("<span class=\"zw-tag__main\">");
        if (p.icon.len > 0) {
            try w.writeAll("<span class=\"zw-tag__icon\" aria-hidden=\"true\">");
            try writeEscaped(w, p.icon);
            try w.writeAll("</span>");
        }
        try writeEscaped(w, p.text);
        try w.writeAll(if (p.href.len > 0 and !chip and !p.disabled) "</a>" else "</span>");
        if (p.remove != null and !chip) {
            var z = p.remove.?;
            z.target = "closest .zw-tag"; // the markup targets the tag itself
            z.swap = .delete;
            try w.writeAll("<button type=\"button\" class=\"zw-tag__x\" aria-label=\"Remove ");
            try writeEscaped(w, p.text);
            try w.writeByte('"');
            if (p.disabled) try w.writeAll(" disabled");
            try z.render(w);
            try w.writeAll(">×</button>");
        }
        try w.writeAll(if (chip) "</label>" else "</span>");
    }
};

/// `tag(.{ .text = "zig" })`, `tag(.{ .text = "zig", .remove = .{ .delete = "/tags/zig" } })`,
/// `tag(.{ .text = "Open", .name = "state", .selected = true })`.
/// Wrap several in `<div class="zw-tags">`.
pub fn tag(p: Props) Tag {
    return .{ .p = p };
}

fn expectHtml(expected: []const u8, p: Props) !void {
    var buf: [512]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try tag(p).render(&w);
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test tag {
    try expectHtml("<span class=\"zw-tag zw-tag--accent\"><span class=\"zw-tag__main\">a&lt;b</span></span>", .{ .text = "a<b" });
    try expectHtml(
        "<span class=\"zw-tag zw-tag--red zw-tag--small\"><span class=\"zw-tag__main\"><span class=\"zw-tag__icon\" aria-hidden=\"true\">!</span>x</span>" ++
            "<button type=\"button\" class=\"zw-tag__x\" aria-label=\"Remove x\" z-delete=\"/t\" z-target=\"closest .zw-tag\" z-swap=\"delete\">×</button></span>",
        .{ .text = "x", .tone = .red, .size = .small, .icon = "!", .remove = .{ .delete = "/t", .target = "#other", .swap = .inner } },
    );
    try expectHtml("<span class=\"zw-tag zw-tag--accent zw-tag--selected\"><a class=\"zw-tag__main\" href=\"/q\" aria-current=\"true\">q</a></span>", .{ .text = "q", .href = "/q", .selected = true });
    try expectHtml(
        "<label class=\"zw-tag zw-tag--gray zw-tag--chip\"><input type=\"checkbox\" name=\"s\" value=\"open\" checked><span class=\"zw-tag__main\">open</span></label>",
        .{ .text = "open", .tone = .gray, .name = "s", .selected = true },
    );
}
