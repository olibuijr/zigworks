//! Root layout: document shell, glass title bar (functional layer), centered content column.
//! `head`: extra raw HTML for <head> (import maps, meta, a real favicon). `toolbar`: trailing title-bar content.
const zv = @import("../view.zig");

pub const css =
    \\.zw-bar{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:8px;height:52px;padding:0 max(var(--space),calc((100vw - var(--width))/2 + var(--space)));
    \\background:var(--glass);backdrop-filter:var(--material);-webkit-backdrop-filter:var(--material);box-shadow:0 .5px 0 var(--separator)}
    \\.zw-bar h1{flex:1;min-width:0;font:var(--title3);font-weight:600;letter-spacing:-.23px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    \\.zw-main{max-width:var(--width);margin:0 auto;padding:24px var(--space) 64px}
    \\
;

const src =
    \\<!doctype html>
    \\<html lang="en"><head><meta charset="utf-8">
    \\<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
    \\<title>{title}</title><link rel="icon" href="data:,">
    \\<link rel="stylesheet" href="/_zw/zw.css"><script src="/_zw/z.js" defer></script>{@html head}
    \\</head><body><header class="zw-bar"><h1>{title}</h1>{toolbar}</header>
    \\<main class="zw-main">{body}</main></body></html>
;

pub fn Props(comptime Toolbar: type, comptime Body: type) type {
    return struct { title: []const u8, head: []const u8 = "", toolbar: Toolbar, body: Body };
}

pub fn Layout(comptime Toolbar: type, comptime Body: type) type {
    return zv.View(src, Props(Toolbar, Body));
}

fn ToolbarOf(comptime P: type) type {
    return if (@hasField(P, "toolbar")) @FieldType(P, "toolbar") else []const u8;
}

/// `layout(.{ .title = "App", .body = ..., .toolbar = ..., .head = "..." })`
pub fn layout(p: anytype) Layout(ToolbarOf(@TypeOf(p)), @FieldType(@TypeOf(p), "body")) {
    const P = @TypeOf(p);
    return .{ .data = .{
        .title = p.title,
        .head = if (@hasField(P, "head")) p.head else "",
        .toolbar = if (@hasField(P, "toolbar")) p.toolbar else "",
        .body = p.body,
    } };
}
