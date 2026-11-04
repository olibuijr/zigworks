//! Menu: a glass popover anchored to the button that opens it (`button(.{ .opens = id })`).
//! Popover API + CSS anchor positioning: light dismiss and Esc for free. z.js closes it after an item fires.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-menu{position-area:bottom span-right;position-try-fallbacks:flip-block,flip-inline;margin:4px 0;min-width:180px;padding:5px;border:0;border-radius:var(--radius);
    \\color:var(--label);background:var(--glass);backdrop-filter:var(--material);-webkit-backdrop-filter:var(--material);
    \\box-shadow:inset 0 0 0 .5px var(--glass-edge),0 0 0 .5px rgba(0,0,0,.15),0 10px 30px rgba(0,0,0,.18)}
    \\.zw-menu:popover-open{animation:zw-pop 120ms ease-out}
    \\@keyframes zw-pop{from{opacity:0;transform:scale(.97)}}
    \\.zw-menu button,.zw-menu label{all:unset;box-sizing:border-box;display:flex;align-items:center;gap:8px;width:100%;height:24px;padding:0 10px;border-radius:5px;font:var(--body);cursor:default}
    \\.zw-menu button:hover,.zw-menu button:focus-visible,.zw-menu label:hover,.zw-menu label:has(:focus-visible){background:var(--accent);color:var(--on-accent)}
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

const src = "<div class=\"zw-menu\" id=\"{id}\" popover role=\"menu\" style=\"position-anchor:--{id}\">{#each items as it}" ++
    "{#if it.separated}<hr>{/if}<button type=\"button\" role=\"menuitem\"{#if it.destructive} class=\"is-destructive\"{/if}{it.z}>{it.label}</button>{/each}</div>";

pub const Menu = zv.View(src, Props);

pub fn menu(p: Props) Menu {
    return .{ .data = p };
}
