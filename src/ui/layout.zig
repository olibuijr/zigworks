//! Root layout: document shell, title bar, content column. The title bar is a scroll edge: content
//! scrolls under a soft blur that fades out, with no hard line, and its controls float as glass.
//! `head`: extra raw HTML for <head> (import maps, meta, a real favicon). `toolbar`: trailing title-bar
//! content. `sidebar`: a `ui.sidebar(...)` turns the page into a two-column app with a sidebar.
//! `brand`: title-bar text linking to "/" (defaults to `title`, which always names the tab).
//! `footer`: content under the page. `title_align`: `.leading` (default) or `.center`. `skip_link`:
//! a "Skip to content" glass pill that appears on the first Tab. `lang`: the document language.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-bar{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:8px;height:calc(52px + env(safe-area-inset-top));
    \\padding:env(safe-area-inset-top) max(var(--space),calc((100vw - var(--width))/2 + var(--space))) 0}
    \\.zw-bar::before{content:"";position:absolute;inset:0 0 -24px;z-index:-1;pointer-events:none;
    \\background:linear-gradient(color-mix(in srgb,var(--window) 80%,transparent),color-mix(in srgb,var(--window) 0%,transparent));
    \\-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px);mask-image:linear-gradient(#000 35%,rgba(0,0,0,.6) 65%,transparent)}
    \\.zw-bar h1{flex:1;min-width:0;font:var(--title3);font-weight:600;letter-spacing:-.23px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    \\.zw-bar h1 a{color:inherit;text-decoration:none}
    \\.zw-bar h1:has(a){flex:1 0 auto}
    \\.zw-bar--center{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,auto) minmax(0,1fr)}
    \\.zw-bar--center h1{grid-column:2;text-align:center}
    \\.zw-bar--center .zw-sidebar-toggle{grid-column:1;grid-row:1;justify-self:start}
    \\.zw-bar-end{grid-column:3;grid-row:1;justify-self:end;display:flex;align-items:center;gap:8px;min-width:0}
    \\.zw-main{max-width:var(--width);margin:0 auto;padding:20px var(--space) calc(64px + env(safe-area-inset-bottom))}
    \\.zw-main:focus{outline:none}
    \\.zw-app .zw-bar{padding:env(safe-area-inset-top) max(var(--space),env(safe-area-inset-right)) 0 max(var(--space),env(safe-area-inset-left))}
    \\.zw-app .zw-main{max-width:calc(72ch + 2 * var(--space) + 40px);padding:28px calc(var(--space) + 20px) calc(80px + env(safe-area-inset-bottom))}
    \\@media (max-width:599px){.zw-app .zw-main{padding:20px var(--space) calc(64px + env(safe-area-inset-bottom))}}
    \\.zw-main:has(+.zw-footer){padding-bottom:24px}
    \\.zw-footer{max-width:var(--width);margin:0 auto;padding:0 var(--space) calc(40px + env(safe-area-inset-bottom));font:var(--callout);color:var(--secondary)}
    \\.zw-footer::before{content:"";display:block;height:.5px;margin-bottom:14px;background:var(--separator)}
    \\.zw-app .zw-footer{max-width:calc(72ch + 2 * var(--space) + 40px);padding-inline:calc(var(--space) + 20px)}
    \\@media (max-width:599px){.zw-app .zw-footer{padding-inline:var(--space)}}
    \\@media (min-width:800px){.zw-shell{display:grid;grid-template-columns:250px minmax(0,1fr)}
    \\.zw-shell>.zw-main,.zw-shell>.zw-footer{grid-column:2}
    \\.zw-shell:has(>.zw-footer)>.zw-sidebar{grid-row:1/3}
    \\.zw-shell>.zw-footer{align-self:start}}
    \\.zw-sidebar-toggle svg{width:18px;height:18px}
    \\@media (pointer:coarse){.zw-sidebar-toggle{min-width:44px;height:44px}}
    \\.zw-skip{position:fixed;top:calc(8px + env(safe-area-inset-top));left:max(8px,env(safe-area-inset-left));z-index:100;display:inline-flex;align-items:center;height:var(--control-h);padding:0 16px;
    \\border-radius:999px;font:var(--body);font-weight:500;color:var(--label);text-decoration:none;white-space:nowrap;
    \\translate:0 calc(-100% - 24px);opacity:0;transition:translate var(--dur) var(--spring),opacity var(--speed)}
    \\.zw-skip:focus{translate:0 0;opacity:1;text-decoration:none}
    \\@media (pointer:coarse){.zw-skip{height:44px}}
    \\
;

const src =
    \\<!doctype html>
    \\<html lang="{lang}"><head><meta charset="utf-8">
    \\<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
    \\<title>{title}</title><link rel="icon" href="data:,">
    \\<link rel="stylesheet" href="/_zw/zw.css"><script src="/_zw/z.js" defer></script>{@html head}
    \\</head><body{#if has_sidebar} class="zw-app"{/if}>{#if skip_link}<a class="zw-skip zw-glass" href="#zw-main">{skip_label}</a>{/if}<header class="zw-bar zw-bar--{title_align}">
    \\{#if has_sidebar}<button type="button" class="zw-btn zw-btn--secondary zw-glass zw-press zw-sidebar-toggle" popovertarget="zw-sidebar" aria-controls="zw-sidebar" aria-label="Show sidebar"><svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><rect x="1.75" y="2.75" width="14.5" height="12.5" rx="2.5"/><path d="M6.5 3v12"/></svg></button>{/if}
    \\<h1>{#if brand}<a href="/">{brand}</a>{:else}{title}{/if}</h1>{#if centered}<div class="zw-bar-end">{toolbar}</div>{:else}{toolbar}{/if}</header>
    \\{#if has_sidebar}<div class="zw-shell">{sidebar}<main class="zw-main" id="zw-main" tabindex="-1">{body}</main>{#if has_footer}<footer class="zw-footer">{footer}</footer>{/if}</div>{:else}<main class="zw-main" id="zw-main" tabindex="-1">{body}</main>{#if has_footer}<footer class="zw-footer">{footer}</footer>{/if}{/if}<div class="zw-toasts" id="zw-toasts" aria-live="polite"></div></body></html>
;

pub const TitleAlign = enum { leading, center };

pub fn PropsWith(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type, comptime Footer: type) type {
    return struct {
        title: []const u8,
        brand: []const u8 = "",
        head: []const u8 = "",
        lang: []const u8 = "en",
        title_align: TitleAlign = .leading,
        skip_link: bool = true,
        skip_label: []const u8 = "Skip to content",
        toolbar: Toolbar,
        sidebar: Sidebar,
        has_sidebar: bool,
        footer: Footer,
        has_footer: bool,
        centered: bool,
        body: Body,
    };
}

pub fn Props(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type) type {
    return PropsWith(Toolbar, Sidebar, Body, []const u8);
}

pub fn LayoutWith(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type, comptime Footer: type) type {
    return zv.View(src, PropsWith(Toolbar, Sidebar, Body, Footer));
}

pub fn Layout(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type) type {
    return LayoutWith(Toolbar, Sidebar, Body, []const u8);
}

fn Slot(comptime P: type, comptime name: []const u8) type {
    return if (@hasField(P, name)) @FieldType(P, name) else []const u8;
}

/// `layout(.{ .title = "App", .body = ..., .toolbar = ..., .sidebar = ui.sidebar(...), .footer = "© 2026", .title_align = .center })`
pub fn layout(p: anytype) LayoutWith(Slot(@TypeOf(p), "toolbar"), Slot(@TypeOf(p), "sidebar"), @FieldType(@TypeOf(p), "body"), Slot(@TypeOf(p), "footer")) {
    const P = @TypeOf(p);
    inline for (@typeInfo(P).@"struct".field_names) |n| {
        const known = [_][]const u8{ "title", "brand", "head", "lang", "title_align", "skip_link", "skip_label", "toolbar", "sidebar", "footer", "body" };
        comptime var ok = false;
        inline for (known) |k| ok = ok or comptime std.mem.eql(u8, k, n);
        if (!ok) @compileError("unknown prop '" ++ n ++ "' for layout");
    }
    const align_: TitleAlign = if (@hasField(P, "title_align")) p.title_align else .leading;
    return .{ .data = .{
        .title = p.title,
        .brand = if (@hasField(P, "brand")) p.brand else "",
        .head = if (@hasField(P, "head")) p.head else "",
        .lang = if (@hasField(P, "lang")) p.lang else "en",
        .title_align = align_,
        .skip_link = if (@hasField(P, "skip_link")) p.skip_link else true,
        .skip_label = if (@hasField(P, "skip_label")) p.skip_label else "Skip to content",
        .toolbar = if (@hasField(P, "toolbar")) p.toolbar else "",
        .sidebar = if (@hasField(P, "sidebar")) p.sidebar else "",
        .has_sidebar = @hasField(P, "sidebar"),
        .footer = if (@hasField(P, "footer")) p.footer else "",
        .has_footer = @hasField(P, "footer"),
        .centered = align_ == .center,
        .body = p.body,
    } };
}

fn renderToString(buf: []u8, l: anytype) ![]const u8 {
    var w: std.Io.Writer = .fixed(buf);
    try l.render(&w);
    return w.buffered();
}

test "layout defaults keep a flat title bar and add a skip link" {
    var buf: [4096]u8 = undefined;
    const out = try renderToString(&buf, layout(.{ .title = "T", .body = "b" }));
    try std.testing.expect(std.mem.find(u8, out, "<html lang=\"en\">") != null);
    try std.testing.expect(std.mem.find(u8, out, "href=\"#zw-main\">Skip to content</a>") != null);
    try std.testing.expect(std.mem.find(u8, out, "id=\"zw-main\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "zw-bar-end") == null);
    try std.testing.expect(std.mem.find(u8, out, "<footer") == null);
}

test "layout footer, centered title, lang and no skip link" {
    var buf: [4096]u8 = undefined;
    const out = try renderToString(&buf, layout(.{ .title = "T", .body = "b", .toolbar = "tb", .footer = "f & co", .title_align = .center, .lang = "is", .skip_link = false }));
    try std.testing.expect(std.mem.find(u8, out, "<html lang=\"is\">") != null);
    try std.testing.expect(std.mem.find(u8, out, "zw-skip") == null);
    try std.testing.expect(std.mem.find(u8, out, "zw-bar zw-bar--center") != null);
    try std.testing.expect(std.mem.find(u8, out, "<div class=\"zw-bar-end\">tb</div>") != null);
    try std.testing.expect(std.mem.find(u8, out, "<footer class=\"zw-footer\">f &amp; co</footer>") != null);
}
