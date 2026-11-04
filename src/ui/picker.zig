//! Pop-up picker (replaces `<select>`): a button showing the choice plus a menu of radio options.
//! Submits like a select (`name=value`). z.js updates the button label and closes the menu on change.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-picker{display:inline-block}
    \\.zw-picker>.zw-btn{min-width:120px;justify-content:space-between;gap:10px;padding:0 12px 0 15px}
    \\.zw-picker>.zw-btn::after{content:"";width:5px;height:5px;margin-top:-3px;border:solid var(--secondary);border-width:0 1.5px 1.5px 0;rotate:45deg;transition:rotate var(--dur) var(--spring)}
    \\.zw-picker:has(:popover-open)>.zw-btn::after{rotate:225deg;margin-top:3px}
    \\.zw-picker input{position:absolute;opacity:0;pointer-events:none}
    \\.zw-picker .zw-menu{position-area:bottom;min-width:anchor-size(width)}
    \\.zw-picker .zw-menu label{padding-left:26px;position:relative}
    \\.zw-picker .zw-menu label:has(:checked)::before{content:"";position:absolute;left:11px;top:50%;width:4px;height:8px;margin-top:-6px;border:solid currentColor;border-width:0 1.5px 1.5px 0;rotate:45deg}
    \\
;

pub const Option = struct { value: []const u8, label: []const u8, selected: bool = false };

pub const Props = struct {
    /// Must be a valid CSS identifier (it also names the anchor).
    id: []const u8,
    name: []const u8,
    /// Accessible name.
    label: []const u8,
    /// Mark one option `.selected = true`.
    options: []const Option,
    z: Z = .{},
};

const Data = struct { p: Props, current: []const u8 };

const src = "<div class=\"zw-picker\"><button type=\"button\" class=\"zw-btn zw-btn--secondary zw-glass zw-press\" popovertarget=\"{p.id}\" style=\"anchor-name:--{p.id}\" aria-label=\"{p.label}\">" ++
    "<span class=\"zw-picker-value\">{current}</span></button><div class=\"zw-menu zw-glass\" id=\"{p.id}\" popover role=\"listbox\" style=\"position-anchor:--{p.id}\">" ++
    "{#each p.options as o}<label><input type=\"radio\" name=\"{p.name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{p.z}>{o.label}</label>{/each}</div></div>";

pub const Picker = zv.View(src, Data);

pub fn picker(p: Props) Picker {
    var current: []const u8 = if (p.options.len > 0) p.options[0].label else "";
    for (p.options) |o| if (o.selected) {
        current = o.label;
    };
    return .{ .data = .{ .p = p, .current = current } };
}
