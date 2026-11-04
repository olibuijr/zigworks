//! Root layout: document shell, title bar, content column. The title bar is a scroll edge: content
//! scrolls under a soft blur that fades out, with no hard line, and its controls float as glass.
//! `head`: extra raw HTML for <head> (import maps, meta, a real favicon). `toolbar`: trailing title-bar
//! content. `sidebar`: a `ui.sidebar(...)` turns the page into a two-column app with a sidebar.
//! `brand`: title-bar text linking to "/" (defaults to `title`, which always names the tab).
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-bar{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:8px;height:52px;padding:0 max(var(--space),calc((100vw - var(--width))/2 + var(--space)))}
    \\.zw-bar::before{content:"";position:absolute;inset:0 0 -24px;z-index:-1;pointer-events:none;
    \\background:linear-gradient(color-mix(in srgb,var(--window) 80%,transparent),color-mix(in srgb,var(--window) 0%,transparent));
    \\-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px);mask-image:linear-gradient(#000 35%,rgba(0,0,0,.6) 65%,transparent)}
    \\.zw-bar h1{flex:1;min-width:0;font:var(--title3);font-weight:600;letter-spacing:-.23px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    \\.zw-bar h1 a{color:inherit;text-decoration:none}
    \\.zw-bar h1:has(a){flex:1 0 auto}
    \\.zw-main{max-width:var(--width);margin:0 auto;padding:20px var(--space) 64px}
    \\.zw-app .zw-bar{padding:0 var(--space)}
    \\.zw-app .zw-main{max-width:calc(72ch + 2 * var(--space) + 40px);padding:28px calc(var(--space) + 20px) 80px}
    \\@media (min-width:800px){.zw-shell{display:grid;grid-template-columns:250px minmax(0,1fr)}}
    \\.zw-sidebar-toggle svg{width:18px;height:18px}
    \\
;

const src =
    \\<!doctype html>
    \\<html lang="en"><head><meta charset="utf-8">
    \\<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
    \\<title>{title}</title><link rel="icon" href="data:,">
    \\<link rel="stylesheet" href="/_zw/zw.css"><script src="/_zw/z.js" defer></script>{@html head}
    \\</head><body{#if has_sidebar} class="zw-app"{/if}><header class="zw-bar">
    \\{#if has_sidebar}<button type="button" class="zw-btn zw-btn--secondary zw-glass zw-press zw-sidebar-toggle" popovertarget="zw-sidebar" aria-label="Show sidebar"><svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="1.75" y="2.75" width="14.5" height="12.5" rx="2.5"/><path d="M6.5 3v12"/></svg></button>{/if}
    \\<h1>{#if brand}<a href="/">{brand}</a>{:else}{title}{/if}</h1>{toolbar}</header>
    \\{#if has_sidebar}<div class="zw-shell">{sidebar}<main class="zw-main">{body}</main></div>{:else}<main class="zw-main">{body}</main>{/if}<div class="zw-toasts" id="zw-toasts" aria-live="polite"></div></body></html>
;

pub fn Props(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type) type {
    return struct {
        title: []const u8,
        brand: []const u8 = "",
        head: []const u8 = "",
        toolbar: Toolbar,
        sidebar: Sidebar,
        has_sidebar: bool,
        body: Body,
    };
}

pub fn Layout(comptime Toolbar: type, comptime Sidebar: type, comptime Body: type) type {
    return zv.View(src, Props(Toolbar, Sidebar, Body));
}

fn Slot(comptime P: type, comptime name: []const u8) type {
    return if (@hasField(P, name)) @FieldType(P, name) else []const u8;
}

/// `layout(.{ .title = "App", .body = ..., .toolbar = ..., .sidebar = ui.sidebar(...), .head = "...", .brand = "App" })`
pub fn layout(p: anytype) Layout(Slot(@TypeOf(p), "toolbar"), Slot(@TypeOf(p), "sidebar"), @FieldType(@TypeOf(p), "body")) {
    const P = @TypeOf(p);
    inline for (@typeInfo(P).@"struct".field_names) |n| {
        const known = [_][]const u8{ "title", "brand", "head", "toolbar", "sidebar", "body" };
        comptime var ok = false;
        inline for (known) |k| ok = ok or comptime std.mem.eql(u8, k, n);
        if (!ok) @compileError("unknown prop '" ++ n ++ "' for layout");
    }
    return .{ .data = .{
        .title = p.title,
        .brand = if (@hasField(P, "brand")) p.brand else "",
        .head = if (@hasField(P, "head")) p.head else "",
        .toolbar = if (@hasField(P, "toolbar")) p.toolbar else "",
        .sidebar = if (@hasField(P, "sidebar")) p.sidebar else "",
        .has_sidebar = @hasField(P, "sidebar"),
        .body = p.body,
    } };
}
