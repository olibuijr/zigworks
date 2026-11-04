//! Sheet: a modal-style panel opened by `button(.{ .opens = id })`. Popover API: Esc and
//! outside click dismiss it, no JS. Put a form in `body`; z.js closes the sheet after it submits.
//! `size`: small, medium (default) or large width. `description`: secondary text under the title.
//! `footer`: a trailing action row after the body. `close`: a close button in the corner.
//! `focus_first`: z.js moves focus to the first field when the sheet opens.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-sheet{--w:480px;inset:0 0 auto;margin:calc(68px + env(safe-area-inset-top)) auto 0;width:min(var(--w),calc(100vw - 32px));max-height:calc(100dvh - 84px - env(safe-area-inset-top));padding:22px;border:0;border-radius:var(--radius-panel);color:var(--label);--glass:var(--glass-thick);
    \\transform-origin:top center;transition:opacity 200ms ease,scale var(--dur-bouncy) var(--spring-bouncy),translate var(--dur) var(--spring),display 320ms allow-discrete,overlay 320ms allow-discrete}
    \\.zw-sheet--small{--w:360px}
    \\.zw-sheet--large{--w:640px}
    \\.zw-sheet:focus{outline:none}
    \\.zw-sheet:not(:popover-open){opacity:0;scale:.94;translate:0 -12px;transition-duration:180ms}
    \\@starting-style{.zw-sheet:popover-open{opacity:0;scale:.9;translate:0 -28px}}
    \\.zw-sheet::backdrop{background:rgba(0,0,0,.18);transition:background-color 250ms,display 320ms allow-discrete,overlay 320ms allow-discrete}
    \\.zw-sheet:not(:popover-open)::backdrop{background:transparent}
    \\@starting-style{.zw-sheet:popover-open::backdrop{background:transparent}}
    \\.zw-sheet h2{font:var(--headline);margin-bottom:14px}
    \\.zw-sheet h2:has(+.zw-sheet-desc){margin-bottom:4px}
    \\.zw-sheet-desc{font:var(--body);color:var(--secondary);margin-bottom:14px}
    \\.zw-sheet--closable h2{padding-right:36px}
    \\.zw-sheet-close{appearance:none;position:absolute;top:16px;right:16px;display:grid;place-items:center;width:28px;height:28px;padding:0;border:0;border-radius:50%;
    \\color:var(--secondary);background:var(--fill);cursor:default;-webkit-tap-highlight-color:transparent;transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-sheet-close svg{width:12px;height:12px}
    \\@media (hover:hover){.zw-sheet-close:hover{background:var(--fill-strong);color:var(--label)}}
    \\.zw-sheet-close:active{scale:.9;transition-duration:var(--dur-snappy)}
    \\@media (pointer:coarse){.zw-sheet-close{top:10px;right:10px;width:44px;height:44px}.zw-sheet--closable h2{padding-right:48px}}
    \\.zw-sheet-actions{display:flex;flex-wrap:wrap;justify-content:flex-end;gap:8px;margin-top:20px}
    \\
;

pub const Size = enum { small, medium, large };

const src =
    "<div class=\"zw-sheet zw-sheet--{p.size}{#if p.close} zw-sheet--closable{/if} zw-glass\" id=\"{p.id}\" popover role=\"dialog\" tabindex=\"-1\" aria-labelledby=\"{p.id}-title\"" ++
    "{#if p.description} aria-describedby=\"{p.id}-desc\"{/if}{#if p.focus_first} data-focus-first{/if}>" ++
    "{#if p.close}<button type=\"button\" class=\"zw-sheet-close\" popovertarget=\"{p.id}\" popovertargetaction=\"hide\" aria-label=\"{p.close_label}\">" ++
    "<svg viewBox=\"0 0 12 12\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\" aria-hidden=\"true\"><path d=\"M2 2l8 8M10 2l-8 8\"/></svg></button>{/if}" ++
    "<h2 id=\"{p.id}-title\">{p.title}</h2>{#if p.description}<p class=\"zw-sheet-desc\" id=\"{p.id}-desc\">{p.description}</p>{/if}" ++
    "{p.body}{#if has_footer}<div class=\"zw-sheet-actions\">{footer}</div>{/if}</div>";

pub fn PropsWith(comptime Body: type) type {
    return struct {
        id: []const u8,
        title: []const u8,
        body: Body,
        description: []const u8 = "",
        size: Size = .medium,
        close: bool = false,
        close_label: []const u8 = "Close",
        focus_first: bool = true,
    };
}

pub fn Props(comptime Body: type) type {
    return PropsWith(Body);
}

fn Data(comptime Body: type, comptime Footer: type) type {
    return struct { p: PropsWith(Body), footer: Footer, has_footer: bool };
}

pub fn SheetWith(comptime Body: type, comptime Footer: type) type {
    return zv.View(src, Data(Body, Footer));
}

pub fn Sheet(comptime Body: type) type {
    return SheetWith(Body, []const u8);
}

fn Slot(comptime P: type, comptime name: []const u8) type {
    return if (@hasField(P, name)) @FieldType(P, name) else []const u8;
}

/// `sheet(.{ .id = "rename", .title = "Rename", .body = form, .size = .small, .description = "…", .close = true, .footer = buttons })`
pub fn sheet(p: anytype) SheetWith(@FieldType(@TypeOf(p), "body"), Slot(@TypeOf(p), "footer")) {
    const P = @TypeOf(p);
    const Body = @FieldType(P, "body");
    const D = PropsWith(Body);
    inline for (@typeInfo(P).@"struct".field_names) |n| {
        if (!@hasField(D, n) and !comptime std.mem.eql(u8, n, "footer")) @compileError("unknown prop '" ++ n ++ "' for sheet");
    }
    var d: D = .{ .id = p.id, .title = p.title, .body = p.body };
    inline for (.{ "description", "size", "close", "close_label", "focus_first" }) |n| {
        if (@hasField(P, n)) @field(d, n) = @field(p, n);
    }
    return .{ .data = .{
        .p = d,
        .footer = if (@hasField(P, "footer")) p.footer else "",
        .has_footer = @hasField(P, "footer"),
    } };
}

test "sheet defaults" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try sheet(.{ .id = "s", .title = "T <1>", .body = "b" }).render(&w);
    try std.testing.expectEqualStrings(
        "<div class=\"zw-sheet zw-sheet--medium zw-glass\" id=\"s\" popover role=\"dialog\" tabindex=\"-1\" aria-labelledby=\"s-title\" data-focus-first>" ++
            "<h2 id=\"s-title\">T &lt;1&gt;</h2>b</div>",
        w.buffered(),
    );
}

test "sheet size, description, close button and footer" {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try sheet(.{ .id = "s", .title = "T", .body = "b", .size = .large, .description = "d & e", .close = true, .focus_first = false, .footer = zv.view("<i>{x}</i>", .{ .x = "ok" }) }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "zw-sheet--large zw-sheet--closable zw-glass") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-describedby=\"s-desc\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "data-focus-first") == null);
    try std.testing.expect(std.mem.find(u8, out, "popovertargetaction=\"hide\" aria-label=\"Close\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "<p class=\"zw-sheet-desc\" id=\"s-desc\">d &amp; e</p>b<div class=\"zw-sheet-actions\"><i>ok</i></div></div>") != null);
}
