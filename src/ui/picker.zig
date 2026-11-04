//! Pop-up picker (replaces `<select>`): a button showing the choice plus a menu of radio options.
//! Submits like a select (`name=value`). z.js updates the button label and closes the menu on change;
//! it copies each option label's text, so an option's icon and description are kept out of the
//! label's text (an SVG, and CSS `attr()` content) and never leak into the button.
//! Like a `<select>`, the first enabled option is checked when none is `selected` and there is no `placeholder`.
//! Optional `help` / `invalid` text sits under the button; the button dims while a z request runs.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

/// AppKit control sizes, shared with the button: small and large step either side of regular.
pub const Size = @import("button.zig").Size;

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
    \\.zw-picker:has(input.zw-busy){opacity:.55;pointer-events:none;transition:opacity var(--speed)}
    \\.zw-picker--invalid>.zw-btn{box-shadow:0 0 0 1px var(--red),var(--glass-rim),var(--glass-shadow)}
    \\.zw-picker>.zw-help{width:0;min-width:100%;margin:4px 0 0;padding-inline:11px}
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
    /// AppKit control size of the button.
    size: Size = .regular,
    /// Help text under the button. Replaced by `invalid` while that is set.
    help: []const u8 = "",
    /// Error message under the button (red, announced). Also outlines the button and sets `aria-invalid`.
    invalid: []const u8 = "",
};

// One menu row: separator, heading and the radio label. `checked` is the option's `selected`,
// or the default option picked for a picker that has neither a selection nor a placeholder.
const item_src = "{#if o.separated}<hr>{/if}{#if o.heading}<div class=\"zw-menu-heading\">{o.heading}</div>{/if}" ++
    "<label><input type=\"radio\" name=\"{p.name}\" value=\"{o.value}\"{#if checked} checked{/if}{#if o.disabled} disabled{/if}{#if p.disabled} disabled{/if}{p.z}>" ++
    "{#if o.icon}<span class=\"zw-pick-icon\" aria-hidden=\"true\">{@html o.icon}</span>{/if}" ++
    "<span class=\"zw-pick-text\"{#if o.description} data-desc=\"{o.description}\"{/if}>{o.label}</span></label>";
const Item = zv.View(item_src, struct { p: Props, o: Option, checked: bool });

const Items = struct {
    p: Props,
    /// Index of the option checked by default, or `maxInt` for none.
    default: usize,

    pub fn render(self: Items, w: *std.Io.Writer) std.Io.Writer.Error!void {
        for (self.p.options, 0..) |o, i| try (Item{ .data = .{ .p = self.p, .o = o, .checked = o.selected or i == self.default } }).render(w);
    }
};

const Data = struct { p: Props, current: []const u8, placeholder_shown: bool, msg: []const u8, items: Items };

// The button reads "<label>: <value>" to screen readers; the menu is a radio group.
const src = "<div class=\"zw-picker{#if p.full} zw-picker--full{/if}{#if p.invalid} zw-picker--invalid{/if}\"><button type=\"button\" class=\"zw-btn zw-btn--{p.size} zw-btn--secondary zw-glass zw-press\" popovertarget=\"{p.id}\" style=\"anchor-name:--{p.id}\"{#if msg} aria-describedby=\"zw-{p.id}-msg\"{/if}{#if p.disabled} disabled{/if}>" ++
    "<span class=\"zw-sr\">{p.label}: </span><span class=\"zw-picker-value{#if placeholder_shown} is-placeholder{/if}\">{current}</span></button>" ++
    "<div class=\"zw-menu zw-glass\" id=\"{p.id}\" popover role=\"radiogroup\" aria-label=\"{p.label}\"{#if p.invalid} aria-invalid=\"true\"{/if} style=\"position-anchor:--{p.id}\">{items}</div>" ++
    "{#if msg}<small id=\"zw-{p.id}-msg\" class=\"zw-help{#if p.invalid} zw-help--error{/if}\"{#if p.invalid} role=\"alert\"{/if}>{msg}</small>{/if}</div>";

pub const Picker = zv.View(src, Data);

pub fn picker(p: Props) Picker {
    var shown: usize = 0; // the option whose label the button shows
    var any_selected = false;
    for (p.options, 0..) |o, i| if (o.selected) {
        shown = i;
        any_selected = true;
    };
    var default: usize = std.math.maxInt(usize);
    if (!any_selected and p.placeholder.len == 0) {
        for (p.options, 0..) |o, i| if (!o.disabled) {
            default = i;
            shown = i;
            break;
        };
    }
    const show_placeholder = !any_selected and p.placeholder.len > 0;
    const current = if (show_placeholder) p.placeholder else if (p.options.len > 0) p.options[shown].label else "";
    const msg = if (p.invalid.len > 0) p.invalid else p.help;
    return .{ .data = .{ .p = p, .current = current, .placeholder_shown = show_placeholder, .msg = msg, .items = .{ .p = p, .default = default } } };
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

test "picker default option, size, help and invalid" {
    var buf: [4096]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    // No selection and no placeholder: the first enabled option is checked, like a <select>.
    try picker(.{ .id = "p", .name = "n", .label = "Sort", .size = .large, .options = &.{
        .{ .value = "a", .label = "A", .disabled = true },
        .{ .value = "b", .label = "B" },
        .{ .value = "c", .label = "C" },
    } }).render(&w);
    var out = w.buffered();
    for ([_][]const u8{ "zw-btn--large", "value=\"b\" checked>", ">B</span></button>" }) |needle| {
        try std.testing.expect(std.mem.find(u8, out, needle) != null);
    }
    try std.testing.expect(std.mem.find(u8, out, "value=\"a\" checked") == null);
    try std.testing.expect(std.mem.find(u8, out, "value=\"c\" checked") == null);
    try std.testing.expect(std.mem.find(u8, out, "aria-invalid") == null);
    try std.testing.expect(std.mem.find(u8, out, "zw-help") == null);
    // A placeholder leaves everything unchecked.
    w = .fixed(&buf);
    try picker(.{ .id = "p", .name = "n", .label = "Sort", .placeholder = "Choose…", .options = &.{.{ .value = "a", .label = "A" }} }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), " checked") == null);
    // Help shows under the button; invalid replaces it and marks the group.
    w = .fixed(&buf);
    try picker(.{ .id = "p", .name = "n", .label = "Sort", .help = "Pick one", .options = &.{.{ .value = "a", .label = "A", .selected = true }} }).render(&w);
    out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "aria-describedby=\"zw-p-msg\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "<small id=\"zw-p-msg\" class=\"zw-help\">Pick one</small>") != null);
    w = .fixed(&buf);
    try picker(.{ .id = "p", .name = "n", .label = "Sort", .help = "Pick one", .invalid = "Required", .options = &.{.{ .value = "a", .label = "A" }} }).render(&w);
    out = w.buffered();
    for ([_][]const u8{ "zw-picker--invalid", "aria-invalid=\"true\"", "zw-help zw-help--error\" role=\"alert\">Required</small>" }) |needle| {
        try std.testing.expect(std.mem.find(u8, out, needle) != null);
    }
    try std.testing.expect(std.mem.find(u8, out, "Pick one") == null);
}
