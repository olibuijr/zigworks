//! Inline callout for notes, tips and warnings. Markdown `> [!TIP]` renders the same markup.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-callout{display:flex;align-items:flex-start;gap:10px;padding:10px 14px;border-radius:var(--radius-control);background:color-mix(in srgb,var(--c) 10%,transparent);box-shadow:inset 3px 0 0 var(--c);color:var(--label);--c:var(--accent);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cmask id='m'%3E%3Crect width='16' height='16' fill='white'/%3E%3Cpath d='M8 7.3v4M8 4.9v.1' stroke='black' stroke-width='1.7' stroke-linecap='round'/%3E%3C/mask%3E%3Ccircle cx='8' cy='8' r='8' mask='url(%23m)'/%3E%3C/svg%3E")
    \\  &::before{content:"";flex:none;width:16px;height:15px;background:var(--c);mask:var(--g) center/16px no-repeat}
    \\  &>div,&>p{min-width:0}
    \\  & p{margin:0}
    \\  & strong:first-child{color:var(--c)}
    \\  @media (forced-colors:active){border:1px solid CanvasText;box-shadow:none;&::before{background:CanvasText}}
    \\}
    \\.zw-callout--tip{--c:var(--green);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cmask id='m'%3E%3Crect width='16' height='16' fill='white'/%3E%3Cpath d='M8 3.4l1.4 2.9 3.2.4-2.3 2.2.6 3.1L8 10.5 5.1 12l.6-3.1L3.4 6.7l3.2-.4z' fill='black'/%3E%3C/mask%3E%3Ccircle cx='8' cy='8' r='8' mask='url(%23m)'/%3E%3C/svg%3E")}
    \\.zw-callout--warning{--c:var(--orange);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cmask id='m'%3E%3Crect width='16' height='16' fill='white'/%3E%3Cpath d='M8 6.6v3M8 11.6v.1' stroke='black' stroke-width='1.7' stroke-linecap='round'/%3E%3C/mask%3E%3Cpath d='M8 1.8l6.6 11.8H1.4z' stroke-width='2' stroke='black' stroke-linejoin='round' mask='url(%23m)'/%3E%3C/svg%3E")}
    \\.zw-callout--important{--c:color-mix(in srgb,var(--accent) 60%,var(--red));--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cmask id='m'%3E%3Crect width='16' height='16' fill='white'/%3E%3Cpath d='M8 4.5v4M8 11.2v.1' stroke='black' stroke-width='1.7' stroke-linecap='round'/%3E%3C/mask%3E%3Ccircle cx='8' cy='8' r='8' mask='url(%23m)'/%3E%3C/svg%3E")}
    \\.zw-callout--caution{--c:var(--red);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cmask id='m'%3E%3Crect width='16' height='16' fill='white'/%3E%3Cpath d='M8 4.5v4M8 11.2v.1' stroke='black' stroke-width='1.7' stroke-linecap='round'/%3E%3C/mask%3E%3Cpath d='M5.2 1h5.6L15 5.2v5.6L10.8 15H5.2L1 10.8V5.2z' mask='url(%23m)'/%3E%3C/svg%3E")}
    \\.zw-callout--noicon::before{display:none}
    \\.zw-callout--compact{align-items:center;gap:8px;padding:6px 10px;box-shadow:none;
    \\  &::before{width:14px;mask-size:14px}
    \\}
    \\
;

pub const Kind = enum { note, tip, warning, important, caution };

pub fn Props(comptime Body: type) type {
    return struct {
        kind: Kind = .note,
        title: []const u8 = "",
        body: Body,
        /// Show the kind's icon. Markdown callouts always show it.
        icon: bool = true,
        /// Tighter padding, no accent bar: for notes inside dense UI.
        compact: bool = false,
    };
}

const src = "<aside class=\"zw-callout zw-callout--{kind}{#if compact} zw-callout--compact{/if}{#if !icon} zw-callout--noicon{/if}\" role=\"note\">" ++
    "<div>{#if title}<strong>{title}</strong> {/if}{body}</div></aside>";

pub fn Callout(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

/// `callout(.{ .kind = .tip, .title = "Tip", .body = "Run zig build e2e." })`
pub fn callout(p: anytype) Callout(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}

test "kinds, compact and icon" {
    var buf: [512]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try callout(.{ .kind = .caution, .title = "Careful", .body = "Wet floor", .compact = true, .icon = false }).render(&w);
    try std.testing.expectEqualStrings(
        "<aside class=\"zw-callout zw-callout--caution zw-callout--compact zw-callout--noicon\" role=\"note\"><div><strong>Careful</strong> Wet floor</div></aside>",
        w.buffered(),
    );
}
