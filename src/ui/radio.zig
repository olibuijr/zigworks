//! Radio group: a list of mutually exclusive choices with visible labels (macOS radio buttons),
//! vertical or horizontal, with optional per-option descriptions and disabled options.
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
    \\.zw-radio__txt{display:flex;flex-direction:column;min-width:0}
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
    /// Dimmed and not selectable.
    disabled: bool = false,
};

pub const Layout = enum { vertical, horizontal };

pub const Props = struct {
    name: []const u8,
    /// Accessible name of the group.
    label: []const u8,
    options: []const Option,
    /// `.horizontal` lays the options out in a wrapping row.
    layout: Layout = .vertical,
    /// Disables every option.
    disabled: bool = false,
    z: Z = .{},
};

const src = "<fieldset class=\"zw-radio zw-radio--{layout}\" role=\"radiogroup\" aria-label=\"{label}\"{#if disabled} disabled{/if}>{#each options as o}" ++
    "<label class=\"zw-radio__opt{#if o.disabled} zw-radio__opt--disabled{/if}\"><input type=\"radio\" name=\"{name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{#if o.disabled} disabled{/if}{z}>" ++
    "<span class=\"zw-radio__txt\"><span>{o.label}</span>{#if o.description}<span class=\"zw-radio__desc\">{o.description}</span>{/if}</span></label>{/each}</fieldset>";

pub const Radio = zv.View(src, Props);

pub fn radio(p: Props) Radio {
    return .{ .data = p };
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
