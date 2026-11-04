//! Inset content list. Children are `<li>` rows. Give it an `id` to target it with z.js.
//! Separators start after a leading control, like macOS lists. `header` and `footer` caption the
//! group, `nav` makes rows full-width links with a disclosure chevron, `reveal` shows row delete
//! buttons on hover, `busy` marks it as loading. Rows with `aria-selected="true"` get the accent
//! selection; text and chevrons that use `--secondary` or `--tertiary` follow it.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-list{list-style:none;padding:0;background:var(--content);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden;
    \\  &>li{display:flex;align-items:center;gap:10px;min-height:44px;padding:6px 8px 6px 12px;position:relative;transition:background-color var(--speed);
    \\    &+li::before{content:"";position:absolute;inset:0 0 auto 44px;border-top:1px solid var(--separator)}
    \\    &[aria-selected=true]{background:var(--accent);color:var(--on-accent);--secondary:color-mix(in srgb,var(--on-accent) 75%,transparent);--tertiary:color-mix(in srgb,var(--on-accent) 60%,transparent);
    \\      &::before,&+li::before{opacity:0}}
    \\    &[aria-disabled=true]{opacity:.4;pointer-events:none}}
    \\  & :focus-visible{outline-offset:-3px}
    \\  &:empty:not([aria-busy=true])::after{content:attr(data-empty);display:block;padding:32px var(--space);text-align:center;color:var(--secondary);animation:zw-fade var(--dur) ease}}
    \\@keyframes zw-fade{from{opacity:0}}
    \\.zw-list--flat{background:none;box-shadow:none;border-radius:0}
    \\.zw-list--sep-none>li+li::before{display:none}
    \\.zw-list--sep-full>li+li::before,.zw-list--nav>li+li::before{left:12px}
    \\.zw-list--nav>li{padding:0;
    \\  &>a{flex:1;min-width:0;align-self:stretch;display:flex;align-items:center;gap:10px;min-height:44px;padding:6px 12px;color:inherit;text-decoration:none;-webkit-tap-highlight-color:transparent;
    \\    &::after{content:"";flex:none;margin-left:auto;width:7px;height:7px;border:solid var(--tertiary);border-width:2px 2px 0 0;rotate:45deg}
    \\    &:active{background:var(--fill-strong)}
    \\    @media (hover:hover){&:hover{background:var(--fill)}}}}
    \\@media (hover:hover){
    \\  .zw-list--reveal{
    \\    & .zw-btn--destructive{opacity:0;transition:opacity var(--speed)}
    \\    &>li:is(:hover,:focus-within) .zw-btn--destructive{opacity:1}}}
    \\.zw-list-head,.zw-list-foot{font:var(--callout);color:var(--secondary);padding:0 var(--space)}
    \\.zw-list-head{font-weight:600;margin-bottom:6px}
    \\.zw-list-foot{margin-top:6px}
    \\
;

pub const Separators = enum { inset, full, none };

pub fn Props(comptime Body: type) type {
    return struct {
        id: []const u8,
        empty: []const u8 = "Nothing here yet",
        /// Caption above the list.
        header: []const u8 = "",
        /// Caption below the list.
        footer: []const u8 = "",
        /// Hairlines between rows: `inset` starts after a leading control, `full` at the row edge.
        separators: Separators = .inset,
        /// Rows are `<li><a href>`: the link fills the row and gets a disclosure chevron.
        nav: bool = false,
        /// Hover-capable pointers see a row's destructive button only on hover or focus.
        reveal: bool = false,
        /// false drops the card background so the list sits flat inside a card.
        inset: bool = true,
        /// Marks the list as loading (aria-busy) and hides the empty text; put skeleton rows in the body.
        busy: bool = false,
        body: Body,
    };
}

pub fn Data(comptime Body: type) type {
    return struct { p: Props(Body), wrap: bool };
}

const src =
    "{#if wrap}<div class=\"zw-list-group\">{#if p.header}<h3 class=\"zw-list-head\" id=\"{p.id}-head\">{p.header}</h3>{/if}{/if}" ++
    "<ul class=\"zw-list zw-list--sep-{p.separators}{#if p.nav} zw-list--nav{/if}{#if p.reveal} zw-list--reveal{/if}{#if !p.inset} zw-list--flat{/if}\" role=\"list\" id=\"{p.id}\" data-empty=\"{p.empty}\"" ++
    "{#if p.busy} aria-busy=\"true\"{/if}{#if p.header} aria-labelledby=\"{p.id}-head\"{/if}{#if p.footer} aria-describedby=\"{p.id}-foot\"{/if}>{p.body}</ul>" ++
    "{#if wrap}{#if p.footer}<p class=\"zw-list-foot\" id=\"{p.id}-foot\">{p.footer}</p>{/if}</div>{/if}";

pub fn List(comptime Body: type) type {
    return zv.View(src, Data(Body));
}

/// `list(.{ .id = "todos", .empty = "No todos yet.", .header = "Today", .body = zw.each(todos, row) })`
pub fn list(p: anytype) List(@FieldType(@TypeOf(p), "body")) {
    const props = zv.props(Props(@FieldType(@TypeOf(p), "body")), p);
    return .{ .data = .{ .p = props, .wrap = props.header.len > 0 or props.footer.len > 0 } };
}

test "list renders captions around the list" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try list(.{ .id = "l", .body = zv.view("<li>{x}</li>", .{ .x = "a" }) }).render(&w);
    try std.testing.expectEqualStrings(
        "<ul class=\"zw-list zw-list--sep-inset\" role=\"list\" id=\"l\" data-empty=\"Nothing here yet\"><li>a</li></ul>",
        w.buffered(),
    );

    w = .fixed(&buf);
    try list(.{ .id = "l", .header = "Today", .footer = "2 items", .nav = true, .separators = .full, .body = "" }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "<div class=\"zw-list-group\"><h3 class=\"zw-list-head\" id=\"l-head\">Today</h3><ul class=\"zw-list zw-list--sep-full zw-list--nav\"") != null);
    try std.testing.expect(std.mem.find(u8, out, " aria-labelledby=\"l-head\" aria-describedby=\"l-foot\"></ul><p class=\"zw-list-foot\" id=\"l-foot\">2 items</p></div>") != null);
}

test "list busy and selected row" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try list(.{ .id = "l", .busy = true, .body = "" }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), " data-empty=\"Nothing here yet\" aria-busy=\"true\"></ul>") != null);
    try std.testing.expect(std.mem.find(u8, css, "&:empty:not([aria-busy=true])::after") != null);
    try std.testing.expect(std.mem.find(u8, css, "[aria-selected=true]{background:var(--accent);color:var(--on-accent);--secondary:") != null);
}
