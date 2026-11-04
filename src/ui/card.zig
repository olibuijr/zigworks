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
    \\.zw-card--flush{padding:0;overflow:hidden}
    \\.zw-card--flush .zw-list{box-shadow:none;border-radius:0}
    \\.zw-card-head{display:flex;flex-wrap:wrap;align-items:center;gap:6px 12px;margin-bottom:10px}
    \\.zw-card-text{flex:1 1 12ch;min-width:0}
    \\.zw-card-title{font:var(--headline);color:var(--secondary);margin:0}
    \\.zw-card-sub{font:var(--callout);color:var(--secondary);margin-top:2px}
    \\.zw-card-acc{flex:none;display:flex;align-items:center;gap:8px}
    \\.zw-card-foot{display:flex;flex-wrap:wrap;align-items:center;justify-content:flex-end;gap:8px;margin-top:var(--space);padding-top:12px;border-top:1px solid var(--separator)}
    \\.zw-card-foot--text{justify-content:flex-start;font:var(--callout);color:var(--secondary)}
    \\.zw-card--flush>.zw-card-head{margin:0;padding:var(--space) var(--space) 10px}
    \\.zw-card--flush>.zw-card-foot{margin-top:0;padding:12px var(--space)}
    \\.zw-card--link{display:block;color:inherit;text-decoration:none;-webkit-tap-highlight-color:transparent;transition:background-color var(--speed)}
    \\.zw-card--link:hover{text-decoration:none}
    \\@media (hover:hover){.zw-card--link:hover{background-color:color-mix(in srgb,var(--content) 94%,var(--label))}.zw-card--inset.zw-card--link:hover{background-color:var(--fill-strong)}}
    \\.zw-card--link:active,.zw-card--inset.zw-card--link:active{background-color:var(--fill-strong)}
    \\
;

pub const Variant = enum { elevated, inset, plain };

/// Everything a template needs: the props, the slots and the flags `card` works out from them.
pub fn Data(comptime Body: type, comptime Acc: type, comptime Foot: type) type {
    return struct {
        id: []const u8,
        title: []const u8,
        subtitle: []const u8,
        variant: Variant,
        href: []const u8,
        flush: bool,
        z: Z,
        tag: []const u8,
        labelled: bool,
        head: bool,
        acc: bool,
        foot: bool,
        foot_text: bool,
        body: Body,
        accessory: Acc,
        footer: Foot,
    };
}

const src = "<{tag} class=\"zw-card zw-card--{variant}{#if flush} zw-card--flush{/if}{#if href} zw-card--link{/if}\"" ++
    "{#if id} id=\"{id}\"{/if}{#if href} href=\"{href}\"{/if}{#if labelled} aria-labelledby=\"{id}-title\"{/if}{z}>" ++
    "{#if head}<header class=\"zw-card-head\"><div class=\"zw-card-text\">" ++
    "{#if title}<h2 class=\"zw-card-title\"{#if id} id=\"{id}-title\"{/if}>{title}</h2>{/if}" ++
    "{#if subtitle}<p class=\"zw-card-sub\">{subtitle}</p>{/if}</div>" ++
    "{#if acc}<div class=\"zw-card-acc\">{accessory}</div>{/if}</header>{/if}" ++
    "{body}" ++
    "{#if foot}<footer class=\"zw-card-foot{#if foot_text} zw-card-foot--text{/if}\">{footer}</footer>{/if}</{tag}>";

pub fn CardOf(comptime Body: type, comptime Acc: type, comptime Foot: type) type {
    return zv.View(src, Data(Body, Acc, Foot));
}

/// A card without an accessory or a footer component (text footers included).
pub fn Card(comptime Body: type) type {
    return CardOf(Body, []const u8, []const u8);
}

const names = [_][]const u8{ "id", "title", "subtitle", "variant", "href", "flush", "z", "accessory", "footer", "body" };

fn checkProps(comptime P: type) void {
    comptime {
        for (@typeInfo(P).@"struct".field_names) |n| {
            var ok = false;
            for (names) |k| ok = ok or std.mem.eql(u8, n, k);
            if (!ok) @compileError("unknown prop '" ++ n ++ "' for card");
        }
    }
}

fn opt(p: anytype, comptime name: []const u8, default: anytype) @TypeOf(default) {
    return if (comptime @hasField(@TypeOf(p), name)) @field(p, name) else default;
}

fn SlotOf(comptime P: type, comptime name: []const u8) type {
    return if (@hasField(P, name)) @FieldType(P, name) else []const u8;
}

/// True when the slot was given and is not an empty string.
fn present(p: anytype, comptime name: []const u8) bool {
    if (comptime @hasField(@TypeOf(p), name)) {
        const v = @field(p, name);
        return if (comptime @typeInfo(@TypeOf(v)) == .pointer) v.len > 0 else true;
    } else return false;
}

/// `card(.{ .title = "Storage", .subtitle = "Macintosh HD", .footer = "Updated just now", .body = ... })`
pub fn card(p: anytype) CardOf(@FieldType(@TypeOf(p), "body"), SlotOf(@TypeOf(p), "accessory"), SlotOf(@TypeOf(p), "footer")) {
    const P = @TypeOf(p);
    checkProps(P);
    const id = opt(p, "id", @as([]const u8, ""));
    const title = opt(p, "title", @as([]const u8, ""));
    const subtitle = opt(p, "subtitle", @as([]const u8, ""));
    const href = opt(p, "href", @as([]const u8, ""));
    const acc = present(p, "accessory");
    const Foot = SlotOf(P, "footer");
    return .{ .data = .{
        .id = id,
        .title = title,
        .subtitle = subtitle,
        .variant = opt(p, "variant", Variant.elevated),
        .href = href,
        .flush = opt(p, "flush", false),
        .z = opt(p, "z", Z{}),
        .tag = if (href.len > 0) "a" else "section",
        .labelled = id.len > 0 and title.len > 0 and href.len == 0,
        .head = title.len > 0 or subtitle.len > 0 or acc,
        .acc = acc,
        .foot = present(p, "footer"),
        .foot_text = @typeInfo(Foot) == .pointer,
        .body = p.body,
        .accessory = if (comptime @hasField(P, "accessory")) p.accessory else "",
        .footer = if (comptime @hasField(P, "footer")) p.footer else "",
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
