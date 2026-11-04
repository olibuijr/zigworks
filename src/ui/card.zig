//! Content surface with an optional header and footer. Opaque: glass belongs to controls and bars only.
//! `title`/`subtitle`/`accessory` make a header, `footer` is a caption or a row of actions, `href`
//! turns the whole card into a link, `variant` picks elevated, inset (grouped fill) or plain.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-card{background:var(--content);border-radius:var(--radius);box-shadow:var(--shadow);padding:var(--space)}
    \\.zw-card--inset{background:var(--fill);box-shadow:none}
    \\.zw-card--plain{background:none;box-shadow:none;padding-inline:0}
    \\.zw-card--flush{padding:0;overflow:hidden;
    \\  & .zw-list{box-shadow:none;border-radius:0}
    \\  &>.zw-card-head{margin:0;padding:var(--space) var(--space) 10px}
    \\  &>.zw-card-foot{margin-top:0;padding:12px var(--space)}}
    \\.zw-card-head{display:flex;flex-wrap:wrap;align-items:center;gap:6px 12px;margin-bottom:10px}
    \\.zw-card-text{flex:1 1 12ch;min-width:0}
    \\.zw-card-title{font:var(--headline);color:var(--secondary)}
    \\.zw-card-sub{font:var(--callout);color:var(--secondary);margin-top:2px}
    \\.zw-card-acc{flex:none;display:flex;align-items:center;gap:8px}
    \\.zw-card-foot{display:flex;flex-wrap:wrap;align-items:center;justify-content:flex-end;gap:8px;margin-top:var(--space);padding-top:12px;border-top:1px solid var(--separator)}
    \\.zw-card-foot--text{justify-content:flex-start;font:var(--callout);color:var(--secondary)}
    \\.zw-card--link{display:block;color:inherit;text-decoration:none;-webkit-tap-highlight-color:transparent;transition:background-color var(--speed);
    \\  &:hover{text-decoration:none}
    \\  @media (hover:hover){
    \\    &:hover{background-color:color-mix(in srgb,var(--content) 94%,var(--label))}
    \\    &.zw-card--inset:hover{background-color:var(--fill-strong)}}
    \\  &:active{background-color:var(--fill-strong)}}
    \\
;

pub const Variant = enum { elevated, inset, plain };

pub fn Props(comptime Body: type, comptime Acc: type, comptime Foot: type) type {
    return struct {
        id: []const u8 = "",
        title: []const u8 = "",
        subtitle: []const u8 = "",
        variant: Variant = .elevated,
        href: []const u8 = "",
        flush: bool = false,
        z: Z = .{},
        accessory: ?Acc = null,
        footer: ?Foot = null,
        body: Body,
    };
}

/// The props plus the flags `card` works out from them.
pub fn Data(comptime Body: type, comptime Acc: type, comptime Foot: type) type {
    return struct { p: Props(Body, Acc, Foot), tag: []const u8, labelled: bool, head: bool, acc: bool, foot: bool, foot_text: bool };
}

const src = "<{tag} class=\"zw-card zw-card--{p.variant}{#if p.flush} zw-card--flush{/if}{#if p.href} zw-card--link{/if}\"" ++
    "{#if p.id} id=\"{p.id}\"{/if}{#if p.href} href=\"{p.href}\"{/if}{#if labelled} aria-labelledby=\"{p.id}-title\"{/if}{p.z}>" ++
    "{#if head}<header class=\"zw-card-head\"><div class=\"zw-card-text\">" ++
    "{#if p.title}<h2 class=\"zw-card-title\"{#if p.id} id=\"{p.id}-title\"{/if}>{p.title}</h2>{/if}" ++
    "{#if p.subtitle}<p class=\"zw-card-sub\">{p.subtitle}</p>{/if}</div>" ++
    "{#if acc}<div class=\"zw-card-acc\">{p.accessory}</div>{/if}</header>{/if}" ++
    "{p.body}" ++
    "{#if foot}<footer class=\"zw-card-foot{#if foot_text} zw-card-foot--text{/if}\">{p.footer}</footer>{/if}</{tag}>";

pub fn CardOf(comptime Body: type, comptime Acc: type, comptime Foot: type) type {
    return zv.View(src, Data(Body, Acc, Foot));
}

/// A card without an accessory or a footer component (text footers included).
pub fn Card(comptime Body: type) type {
    return CardOf(Body, []const u8, []const u8);
}

/// `card(.{ .title = "Storage", .subtitle = "Macintosh HD", .footer = "Updated just now", .body = ... })`
pub fn card(p: anytype) CardOf(@FieldType(@TypeOf(p), "body"), zv.Slot(@TypeOf(p), "accessory"), zv.Slot(@TypeOf(p), "footer")) {
    const P = @TypeOf(p);
    const Foot = zv.Slot(P, "footer");
    const q = zv.props(Props(@FieldType(P, "body"), zv.Slot(P, "accessory"), Foot), p);
    const acc = zv.filled(q.accessory);
    return .{ .data = .{
        .p = q,
        .tag = if (q.href.len > 0) "a" else "section",
        .labelled = q.id.len > 0 and q.title.len > 0 and q.href.len == 0,
        .head = q.title.len > 0 or q.subtitle.len > 0 or acc,
        .acc = acc,
        .foot = zv.filled(q.footer),
        .foot_text = @typeInfo(Foot) == .pointer,
    } };
}

test "card renders header, footer and link" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try card(.{ .id = "c", .title = "T", .subtitle = "S", .footer = "Note", .body = "hi" }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "<section class=\"zw-card zw-card--elevated\" id=\"c\" aria-labelledby=\"c-title\">") != null);
    try std.testing.expect(std.mem.find(u8, out, "<h2 class=\"zw-card-title\" id=\"c-title\">T</h2><p class=\"zw-card-sub\">S</p>") != null);
    try std.testing.expect(std.mem.find(u8, out, "hi<footer class=\"zw-card-foot zw-card-foot--text\">Note</footer></section>") != null);

    w = .fixed(&buf);
    try card(.{ .href = "/x", .variant = .inset, .flush = true, .body = "b" }).render(&w);
    try std.testing.expectEqualStrings(
        "<a class=\"zw-card zw-card--inset zw-card--flush zw-card--link\" href=\"/x\">b</a>",
        w.buffered(),
    );
}
