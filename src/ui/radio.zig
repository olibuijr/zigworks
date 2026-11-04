//! Radio group: a list of mutually exclusive choices with visible labels (macOS radio buttons),
//! vertical or horizontal, with optional per-option descriptions, trailing text and disabled options,
//! a visible caption, and help or error text under the group.
//! For two to five short choices in a row, prefer `ui.segmented`.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-radio{display:flex;flex-direction:column;gap:2px;padding:0;border:0;min-width:0;
    \\label{display:inline-flex;align-items:flex-start;gap:8px;padding:3px 0;cursor:default;user-select:none;-webkit-tap-highlight-color:transparent;
    \\&:active input{scale:.85;transition-duration:var(--dur-snappy)}}
    \\input{appearance:none;flex:none;display:grid;place-items:center;width:16px;height:16px;border-radius:50%;background:var(--content);
    \\box-shadow:inset 0 0 0 1px var(--tertiary),0 .5px 1px rgba(0,0,0,.06);transition:background-color var(--speed),box-shadow var(--speed),scale var(--dur-bouncy) var(--spring-bouncy);
    \\&::after{content:"";width:6px;height:6px;border-radius:50%;background:var(--on-accent);scale:0;transition:scale var(--dur-bouncy) var(--spring-bouncy)}
    \\&:checked{background:linear-gradient(color-mix(in srgb,var(--accent) 80%,#fff),var(--accent));box-shadow:inset 0 .5px 0 rgba(255,255,255,.4),0 0 0 .5px color-mix(in srgb,var(--accent) 70%,#000)}
    \\&:checked::after{scale:1}}}
    \\.zw-radio--horizontal{flex-direction:row;flex-wrap:wrap;gap:2px 20px}
    \\.zw-radio__legend{padding:0;margin-bottom:6px;font:var(--callout);color:var(--secondary)}
    \\.zw-radio>.zw-help{flex-basis:100%;margin:2px 0 0}
    \\.zw-radio[aria-invalid=true] input:not(:checked){box-shadow:inset 0 0 0 1.5px var(--red)}
    \\.zw-radio__txt{display:flex;flex-direction:column;min-width:0}
    \\.zw-radio__detail{margin-inline-start:auto;padding-inline-start:12px;color:var(--secondary);font-variant-numeric:tabular-nums}
    \\.zw-radio__desc{font:var(--callout);color:var(--secondary)}
    \\.zw-radio__opt--disabled,.zw-radio:disabled .zw-radio__opt{opacity:.4;pointer-events:none}
    \\@media (pointer:coarse){.zw-radio label{min-height:44px;padding:14px 0}.zw-radio{gap:0}}
    \\
;

pub const Option = struct {
    value: []const u8,
    label: []const u8,
    selected: bool = false,
    /// Secondary line under the label.
    description: []const u8 = "",
    /// Trailing text at the end of the row, such as a price. Read as part of the label.
    detail: []const u8 = "",
    /// Dimmed and not selectable.
    disabled: bool = false,
};

pub const Layout = enum { vertical, horizontal };

pub const Props = struct {
    name: []const u8,
    /// Accessible name of the group. Also shown as a caption when `caption` is set.
    label: []const u8,
    options: []const Option,
    /// `.horizontal` lays the options out in a wrapping row.
    layout: Layout = .vertical,
    /// Shows `label` as a visible caption above the options.
    caption: bool = false,
    /// A choice is needed before the form can be sent (`aria-required`, native validation).
    required: bool = false,
    /// Help text under the group. Replaced by `invalid` while that is set.
    help: []const u8 = "",
    /// Error message under the group (red). Also sets `aria-invalid`.
    invalid: []const u8 = "",
    /// Disables every option (the group is also marked `aria-disabled`).
    disabled: bool = false,
    z: Z = .{},
};

const src = "<fieldset class=\"zw-radio zw-radio--{p.layout}\" role=\"radiogroup\" aria-label=\"{p.label}\"{#if p.required} aria-required=\"true\"{/if}{#if p.invalid} aria-invalid=\"true\"{/if}" ++
    "{#if msg} aria-describedby=\"zw-{p.name}-msg\"{/if}{#if p.disabled} disabled aria-disabled=\"true\"{/if}>{#if p.caption}<legend class=\"zw-radio__legend\">{p.label}</legend>{/if}{#each p.options as o}" ++
    "<label class=\"zw-radio__opt{#if o.disabled} zw-radio__opt--disabled{/if}\"><input type=\"radio\" name=\"{p.name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{#if o.disabled} disabled{/if}{#if p.required} required{/if}{p.z}>" ++
    "<span class=\"zw-radio__txt\"><span>{o.label}</span>{#if o.description}<span class=\"zw-radio__desc\">{o.description}</span>{/if}</span>" ++
    "{#if o.detail}<span class=\"zw-radio__detail\">{o.detail}</span>{/if}</label>{/each}" ++
    "{#if msg}<small id=\"zw-{p.name}-msg\" class=\"zw-help{#if p.invalid} zw-help--error{/if}\"{#if p.invalid} role=\"alert\"{/if}>{msg}</small>{/if}</fieldset>";

/// `msg` is the text under the group: the error if there is one, else the help.
const Data = struct { p: Props, msg: []const u8 };

pub const Radio = zv.View(src, Data);

pub fn radio(p: Props) Radio {
    return .{ .data = .{ .p = p, .msg = if (p.invalid.len > 0) p.invalid else p.help } };
}

test "radio renders layout, descriptions and disabled options" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try radio(.{ .name = "n", .label = "L", .layout = .horizontal, .options = &.{
        .{ .value = "a", .label = "A", .description = "First", .selected = true },
        .{ .value = "b", .label = "B", .disabled = true },
    } }).render(&w);
    const s = w.buffered();
    try std.testing.expect(std.mem.find(u8, s, "zw-radio--horizontal") != null);
    try std.testing.expect(std.mem.find(u8, s, "zw-radio__desc\">First") != null);
    try std.testing.expect(std.mem.find(u8, s, "value=\"b\" disabled") != null);
}

test "radio caption, required, error, detail and disabled group" {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try radio(.{ .name = "n", .label = "L", .caption = true, .required = true, .help = "Pick one", .invalid = "Choose a size", .disabled = true, .options = &.{
        .{ .value = "a", .label = "A", .detail = "$9.00" },
    } }).render(&w);
    const s = w.buffered();
    try std.testing.expect(std.mem.find(u8, s, "<legend class=\"zw-radio__legend\">L</legend>") != null);
    try std.testing.expect(std.mem.find(u8, s, "aria-required=\"true\"") != null);
    try std.testing.expect(std.mem.find(u8, s, "aria-invalid=\"true\"") != null);
    try std.testing.expect(std.mem.find(u8, s, "aria-describedby=\"zw-n-msg\"") != null);
    try std.testing.expect(std.mem.find(u8, s, " disabled aria-disabled=\"true\"") != null);
    try std.testing.expect(std.mem.find(u8, s, "value=\"a\" required>") != null);
    try std.testing.expect(std.mem.find(u8, s, "zw-radio__detail\">$9.00") != null);
    try std.testing.expect(std.mem.find(u8, s, "role=\"alert\">Choose a size</small>") != null);
    try std.testing.expect(std.mem.find(u8, s, "Pick one") == null);

    var buf2: [1024]u8 = undefined;
    var w2: std.Io.Writer = .fixed(&buf2);
    try radio(.{ .name = "n", .label = "L", .options = &.{.{ .value = "a", .label = "A" }} }).render(&w2);
    const plain = w2.buffered();
    try std.testing.expect(std.mem.find(u8, plain, "<legend") == null);
    try std.testing.expect(std.mem.find(u8, plain, "<small") == null);
    try std.testing.expect(std.mem.find(u8, plain, "aria-invalid") == null);
}
