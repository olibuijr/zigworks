//! Pop-up picker (replaces `<select>`): a button showing the choice plus a menu of radio options.
//! Submits like a select (`name=value`). z.js updates the button label and closes the menu on change;
//! it copies each option label's text, so an option's icon and description are kept out of the
//! label's text (an SVG, and CSS `attr()` content) and never leak into the button.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-picker{display:inline-block;max-width:100%;
    \\&>.zw-btn{min-width:120px;max-width:100%;justify-content:space-between;gap:10px;padding:0 12px 0 15px;
    \\&::after{content:"";flex:none;width:5px;height:5px;margin-top:-3px;border:solid var(--secondary);border-width:0 1.5px 1.5px 0;rotate:45deg;transition:rotate var(--dur) var(--spring)}}
    \\&:has(:popover-open)>.zw-btn::after{rotate:225deg;margin-top:3px}
    \\&:has(:checked) .zw-picker-value.is-placeholder{color:inherit}
    \\& input{position:absolute;opacity:0;pointer-events:none}
    \\.zw-menu{position-area:bottom;min-width:anchor-size(width);max-width:calc(100vw - 16px);max-height:min(60vh,360px);overflow-y:auto;overscroll-behavior:contain;
    \\& label{padding-left:26px;position:relative;
    \\&:has(:checked)::before{content:"";position:absolute;left:11px;top:50%;width:4px;height:8px;margin-top:-6px;border:solid currentColor;border-width:0 1.5px 1.5px 0;rotate:45deg}
    \\&:has([data-desc]){height:auto;min-height:34px;padding-block:4px;@media (pointer:coarse){min-height:52px}}
    \\&:has(:disabled){opacity:.4;&:is(:hover,:active){background:none;color:var(--label)}}
    \\@media (pointer:coarse){height:44px}}}
    \\.zw-menu-heading{padding:8px 10px 2px;font:var(--callout);font-weight:600;color:var(--secondary);&:first-child{padding-top:2px}}}
    \\.zw-picker--full{display:block;&>.zw-btn{width:100%}}
    \\.zw-picker-value{min-width:0;overflow:hidden;text-overflow:ellipsis;&.is-placeholder{color:var(--secondary)}}
    \\.zw-pick-icon{display:inline-flex;flex:none;width:16px;height:16px;& svg{width:100%;height:100%;fill:currentColor}}
    \\.zw-pick-text{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;&[data-desc]::after{content:attr(data-desc);display:block;font:var(--callout);opacity:.65}}
    \\
;

pub const Option = struct {
    value: []const u8,
    label: []const u8,
    selected: bool = false,
    /// Inline SVG (trusted markup, never user input) shown before the label in the menu. Use `currentColor`.
    icon: []const u8 = "",
    /// A second, smaller line under the label in the menu.
    description: []const u8 = "",
    /// Dimmed and not selectable.
    disabled: bool = false,
    /// Draw a separator above this option.
    separated: bool = false,
    /// A section heading above this option (after the separator, if any).
    heading: []const u8 = "",
};

pub const Props = struct {
    /// Must be a valid CSS identifier (it also names the anchor).
    id: []const u8,
    name: []const u8,
    /// Accessible name.
    label: []const u8,
    /// Mark one option `.selected = true`.
    options: []const Option,
    z: Z = .{},
    /// Shown, dimmed, while no option is selected. Without it the button shows the first option's label.
    placeholder: []const u8 = "",
    /// Dim the picker; it cannot open and submits nothing, like a disabled `<select>`.
    disabled: bool = false,
    /// Stretch the button to the width of its container.
    full: bool = false,
};

const Data = struct { p: Props, current: []const u8, placeholder_shown: bool };

// The button reads "<label>: <value>" to screen readers; the menu is a radio group.
const src = "<div class=\"zw-picker{#if p.full} zw-picker--full{/if}\"><button type=\"button\" class=\"zw-btn zw-btn--secondary zw-glass zw-press\" popovertarget=\"{p.id}\" style=\"anchor-name:--{p.id}\"{#if p.disabled} disabled{/if}>" ++
    "<span class=\"zw-sr\">{p.label}: </span><span class=\"zw-picker-value{#if placeholder_shown} is-placeholder{/if}\">{current}</span></button>" ++
    "<div class=\"zw-menu zw-glass\" id=\"{p.id}\" popover role=\"radiogroup\" aria-label=\"{p.label}\" style=\"position-anchor:--{p.id}\">" ++
    "{#each p.options as o}{#if o.separated}<hr>{/if}{#if o.heading}<div class=\"zw-menu-heading\">{o.heading}</div>{/if}" ++
    "<label><input type=\"radio\" name=\"{p.name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{#if o.disabled} disabled{/if}{#if p.disabled} disabled{/if}{p.z}>" ++
    "{#if o.icon}<span class=\"zw-pick-icon\" aria-hidden=\"true\">{@html o.icon}</span>{/if}" ++
    "<span class=\"zw-pick-text\"{#if o.description} data-desc=\"{o.description}\"{/if}>{o.label}</span></label>{/each}</div></div>";

pub const Picker = zv.View(src, Data);

pub fn picker(p: Props) Picker {
    var current: []const u8 = if (p.options.len > 0) p.options[0].label else "";
    var any_selected = false;
    for (p.options) |o| if (o.selected) {
        current = o.label;
        any_selected = true;
    };
    const show_placeholder = !any_selected and p.placeholder.len > 0;
    if (show_placeholder) current = p.placeholder;
    return .{ .data = .{ .p = p, .current = current, .placeholder_shown = show_placeholder } };
}

test "picker placeholder, sections, description, disabled" {
    var buf: [4096]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try picker(.{ .id = "p", .name = "n", .label = "Sort", .placeholder = "Choose…", .full = true, .options = &.{
        .{ .value = "a", .label = "A", .heading = "Fields", .description = "By name" },
        .{ .value = "b", .label = "B", .separated = true, .disabled = true, .icon = "<svg></svg>" },
    } }).render(&w);
    const out = w.buffered();
    for ([_][]const u8{ "zw-picker zw-picker--full", "is-placeholder\">Choose…<", "<div class=\"zw-menu-heading\">Fields</div>", "data-desc=\"By name\"", "<hr>", "value=\"b\" disabled>", "<svg></svg>" }) |needle| {
        try std.testing.expect(std.mem.find(u8, out, needle) != null);
    }
    w = .fixed(&buf);
    try picker(.{ .id = "p", .name = "n", .label = "Sort", .placeholder = "Choose…", .options = &.{.{ .value = "a", .label = "A", .selected = true }} }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "is-placeholder") == null);
}
