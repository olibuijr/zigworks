//! Menu: a glass popover anchored to the button that opens it (`button(.{ .opens = id })`).
//! Popover API + CSS anchor positioning: light dismiss and Esc for free. z.js closes it after an item fires.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-menu{position-area:bottom span-right;position-try-fallbacks:flip-block,flip-inline;margin:6px 0;min-width:190px;padding:6px;border:0;border-radius:var(--radius);
    \\color:var(--label);--glass:var(--glass-thick);transform-origin:top center;overflow:visible;
    \\transition:opacity 180ms ease,scale var(--dur-bouncy) var(--spring-bouncy),translate var(--dur) var(--spring),display 300ms allow-discrete,overlay 300ms allow-discrete}
    \\.zw-menu:not(:popover-open){opacity:0;scale:.9;translate:0 -6px;transition-duration:150ms}
    \\@starting-style{.zw-menu:popover-open{opacity:0;scale:.84;translate:0 -10px}}
    \\.zw-menu button,.zw-menu label{all:unset;box-sizing:border-box;display:flex;align-items:center;gap:8px;width:100%;height:26px;padding:0 10px;border-radius:8px;font:var(--body);cursor:default;
    \\transition:background-color 80ms,color 80ms}
    \\.zw-menu button:hover,.zw-menu button:focus-visible,.zw-menu label:hover,.zw-menu label:has(:focus-visible){background:var(--accent);color:var(--on-accent)}
    \\.zw-menu button:active,.zw-menu label:active{background:color-mix(in srgb,var(--accent) 85%,#000)}
    \\.zw-menu .is-destructive{color:var(--red)}
    \\.zw-menu hr{border:0;border-top:1px solid var(--separator);margin:5px 10px}
    \\
;

pub const Item = struct {
    label: []const u8,
    z: Z = .{},
    destructive: bool = false,
    /// Draw a separator above this item.
    separated: bool = false,
};

pub const Props = struct {
    /// Must be a valid CSS identifier (it also names the anchor).
    id: []const u8,
    items: []const Item,
};

const src = "<div class=\"zw-menu zw-glass\" id=\"{id}\" popover role=\"menu\" style=\"position-anchor:--{id}\">{#each items as it}" ++
    "{#if it.separated}<hr>{/if}<button type=\"button\" role=\"menuitem\"{#if it.destructive} class=\"is-destructive\"{/if}{it.z}>{it.label}</button>{/each}</div>";

pub const Menu = zv.View(src, Props);

pub fn menu(p: Props) Menu {
    return .{ .data = p };
}
