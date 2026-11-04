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
    \\.zw-bar{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:8px;height:calc(52px + env(safe-area-inset-top));padding:env(safe-area-inset-top) max(var(--space),(100vw - var(--width))/2 + var(--space)) 0;
    \\&::before{content:"";position:absolute;inset:0 0 -24px;z-index:-1;pointer-events:none;
    \\background:linear-gradient(color-mix(in srgb,var(--window) 80%,transparent),color-mix(in srgb,var(--window) 0%,transparent));
    \\-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px);mask-image:linear-gradient(#000 35%,rgba(0,0,0,.6) 65%,transparent)}
    \\h1{flex:1;min-width:0;font:var(--title3);font-weight:600;letter-spacing:-.23px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;
    \\a{color:inherit;text-decoration:none}
    \\&:has(a){flex:1 0 auto}}}
    \\.zw-bar--center{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,auto) minmax(0,1fr);
    \\h1{grid-column:2;text-align:center}
    \\.zw-sidebar-toggle{grid-column:1;grid-row:1;justify-self:start}}
    \\.zw-bar-end{grid-column:3;grid-row:1;justify-self:end;display:flex;align-items:center;gap:8px;min-width:0}
    \\.zw-main{max-width:var(--width);margin:0 auto;padding:20px var(--space) calc(64px + env(safe-area-inset-bottom));&:focus{outline:none}}
    \\.zw-footer{max-width:var(--width);margin:0 auto;padding:0 var(--space) calc(40px + env(safe-area-inset-bottom));font:var(--callout);color:var(--secondary);
    \\&::before{content:"";display:block;height:.5px;margin-bottom:14px;background:var(--separator)}}
    \\.zw-app{
    \\.zw-bar{padding:env(safe-area-inset-top) max(var(--space),env(safe-area-inset-right)) 0 max(var(--space),env(safe-area-inset-left))}
    \\.zw-main{max-width:calc(72ch + 2 * var(--space) + 40px);padding:28px calc(var(--space) + 20px) calc(80px + env(safe-area-inset-bottom))}
    \\.zw-footer{max-width:calc(72ch + 2 * var(--space) + 40px);padding-inline:calc(var(--space) + 20px)}
    \\@media (max-width:599px){.zw-main{padding:20px var(--space) calc(64px + env(safe-area-inset-bottom))}.zw-footer{padding-inline:var(--space)}}}
    \\.zw-main:has(+.zw-footer){padding-bottom:24px}
    \\@media (min-width:800px){.zw-shell{display:grid;grid-template-columns:250px minmax(0,1fr);
    \\>:is(.zw-main,.zw-footer){grid-column:2}
    \\>.zw-footer{align-self:start}
    \\&:has(>.zw-footer)>.zw-sidebar{grid-row:1/3}}}
    \\.zw-skip{position:fixed;top:calc(8px + env(safe-area-inset-top));left:max(8px,env(safe-area-inset-left));z-index:100;display:inline-flex;align-items:center;height:var(--control-h);padding:0 16px;
    \\border-radius:999px;font:var(--body);font-weight:500;color:var(--label);white-space:nowrap;
    \\translate:0 calc(-100% - 24px);opacity:0;transition:translate var(--dur) var(--spring),opacity var(--speed);
    \\&:focus{translate:0 0;opacity:1;text-decoration:none}}
    \\@media (pointer:coarse){.zw-sidebar-toggle{min-width:44px;height:44px}.zw-skip{height:44px}}
    \\
;

const src =
    \\<!doctype html>
    \\<html lang="{p.lang}"><head><meta charset="utf-8">
    \\<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
    \\<title>{p.title}</title><link rel="icon" href="data:,">
    \\<link rel="stylesheet" href="/_zw/zw.css"><script src="/_zw/z.js" defer></script>{@html p.head}
    \\</head><body{#if p.sidebar} class="zw-app"{/if}>{#if p.skip_link}<a class="zw-skip zw-glass" href="#zw-main">{p.skip_label}</a>{/if}<header class="zw-bar zw-bar--{p.title_align}">
    \\{#if p.sidebar}<button type="button" class="zw-btn zw-btn--secondary zw-glass zw-press zw-sidebar-toggle" popovertarget="zw-sidebar" aria-controls="zw-sidebar" aria-label="Show sidebar"><svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><rect x="1.75" y="2.75" width="14.5" height="12.5" rx="2.5"/><path d="M6.5 3v12"/></svg></button>{/if}
    \\<h1>{#if p.brand}<a href="/">{p.brand}</a>{:else}{p.title}{/if}</h1>{#if centered}<div class="zw-bar-end">{p.toolbar}</div>{:else}{p.toolbar}{/if}</header>
    \\{#if p.sidebar}<div class="zw-shell">{p.sidebar}<main class="zw-main" id="zw-main" tabindex="-1">{p.body}</main>{#if p.footer}<footer class="zw-footer">{p.footer}</footer>{/if}</div>{:else}<main class="zw-main" id="zw-main" tabindex="-1">{p.body}</main>{#if p.footer}<footer class="zw-footer">{p.footer}</footer>{/if}{/if}<div class="zw-toasts" id="zw-toasts" aria-live="polite"></div></body></html>
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
        toolbar: ?Toolbar = null,
        sidebar: ?Sidebar = null,
        footer: ?Footer = null,
        body: Body,
    };
}

fn Data(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type, comptime Footer: type) type {
    return struct { p: PropsWith(Toolbar, Sidebar, Body, Footer), centered: bool };
}

pub fn LayoutWith(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type, comptime Footer: type) type {
    return zv.View(src, Data(Toolbar, Sidebar, Body, Footer));
}

pub fn Layout(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type) type {
    return LayoutWith(Toolbar, Sidebar, Body, []const u8);
}

/// `layout(.{ .title = "App", .body = ..., .toolbar = ..., .sidebar = ui.sidebar(...), .footer = "© 2026", .title_align = .center })`
pub fn layout(p: anytype) LayoutWith(zv.Slot(@TypeOf(p), "toolbar"), zv.Slot(@TypeOf(p), "sidebar"), @FieldType(@TypeOf(p), "body"), zv.Slot(@TypeOf(p), "footer")) {
    const P = @TypeOf(p);
    const q = zv.props(PropsWith(zv.Slot(P, "toolbar"), zv.Slot(P, "sidebar"), @FieldType(P, "body"), zv.Slot(P, "footer")), p);
    return .{ .data = .{ .p = q, .centered = q.title_align == .center } };
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
