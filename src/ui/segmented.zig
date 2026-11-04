//! Segmented control: radio inputs (form value, arrow keys) drawn as macOS segments.
//! Options can carry an icon and be disabled; the control has three sizes, can fill its row,
//! and can show icons only (the labels stay for screen readers). Optional help or error text sits under the control;
//! while a `z` request is in flight the control dims and ignores clicks.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-seg{--seg-h:var(--control-h);position:relative;display:inline-grid;grid-auto-flow:column;grid-auto-columns:minmax(0,1fr);flex:none;min-width:0;max-width:100%;padding:2px;border:0;border-radius:999px;
    \\background:var(--fill);box-shadow:inset 0 .5px 1px rgba(0,0,0,.08);transition:opacity var(--speed);
    \\& label{position:relative;z-index:1;display:flex;align-items:center;justify-content:center;gap:6px;min-width:0;height:calc(var(--seg-h) - 4px);padding:0 14px;border-radius:999px;
    \\font:var(--body);font-weight:500;color:var(--label);cursor:default;user-select:none;-webkit-tap-highlight-color:transparent;transition:opacity var(--speed);
    \\&:has(:focus-visible){outline:var(--focus-ring);outline-offset:-1px}
    \\&:has(:disabled){opacity:.4}}
    \\& input{position:absolute;inset:0;opacity:0}}
    \\.zw-seg-field{display:inline-flex;flex-direction:column;flex:none;min-width:0;max-width:100%;
    \\&:has(.zw-seg--full){display:flex;width:100%}
    \\& .zw-seg{align-self:flex-start}}
    \\.zw-seg[aria-invalid=true]{box-shadow:inset 0 .5px 1px rgba(0,0,0,.08),0 0 0 1px var(--red)}
    \\.zw-seg--small{--seg-h:22px;& label{padding:0 10px;font:var(--callout);font-weight:500}}
    \\.zw-seg--large{--seg-h:36px;& label{padding:0 18px;font:var(--title3);font-weight:500}}
    \\.zw-seg--full{display:grid;width:100%}
    \\.zw-seg-text{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.zw-seg-icon{display:inline-flex;flex:none;width:16px;height:16px}
    \\.zw-seg-icon svg{width:100%;height:100%;fill:currentColor}
    \\.zw-seg--icons{& .zw-seg-icon+.zw-seg-text{position:absolute;width:1px;height:1px;clip:rect(0 0 0 0)}
    \\& label{padding:0 12px}}
    \\.zw-seg-pill{position:absolute;inset:2px auto 2px 2px;width:calc((100% - 4px) / var(--n));border-radius:999px;--glass:color-mix(in srgb,var(--control-raised) 80%,transparent);
    \\translate:calc(var(--i,0) * 100%) 0;transition:var(--dur-bouncy) var(--spring-bouncy);transition-property:translate,scale}
    \\.zw-seg{
    \\&:has(.zw-busy){opacity:.6;pointer-events:none}
    \\&:not(:has(:checked)) .zw-seg-pill{opacity:0}
    \\&:has(label:not(:has(:disabled)):active) .zw-seg-pill{scale:1.06 1.16;transition-duration:var(--dur-snappy)}
    \\&:has(label:nth-of-type(2) :checked){--i:1}
    \\&:has(label:nth-of-type(3) :checked){--i:2}
    \\&:has(label:nth-of-type(4) :checked){--i:3}
    \\&:has(label:nth-of-type(5) :checked){--i:4}
    \\&:has(label:nth-of-type(6) :checked){--i:5}
    \\&:has(label:nth-of-type(7) :checked){--i:6}
    \\&:has(label:nth-of-type(8) :checked){--i:7}}
    \\@media (pointer:coarse){.zw-seg.zw-seg{--seg-h:44px}}
    \\
;

pub const Size = enum { small, regular, large };

pub const Option = struct {
    value: []const u8,
    label: []const u8,
    selected: bool = false,
    /// Inline SVG (trusted markup, never user input) shown before the label. Use `currentColor` so it follows the text.
    icon: []const u8 = "",
    /// Dimmed and not selectable.
    disabled: bool = false,
};

pub const Props = struct {
    name: []const u8,
    /// Accessible name of the whole group.
    label: []const u8,
    options: []const Option,
    /// Request sent on `change`. The attributes go on every radio, so each segment fires it with `name=value`;
    /// to send several controls together put `z` (with `trigger = "change"`) on a wrapping `<form>` instead.
    z: Z = .{},
    size: Size = .regular,
    /// Stretch to the full width of the container; segments stay equal.
    full: bool = false,
    /// Hide the text of options that have an icon (it stays available to screen readers).
    icons_only: bool = false,
    /// Disable every segment.
    disabled: bool = false,
    /// Help text under the control. Replaced by `invalid` while that is set.
    help: []const u8 = "",
    /// Error message under the control (red). Also sets `aria-invalid` and outlines the control.
    invalid: []const u8 = "",
};

// The glass pill slides to the checked segment (CSS `--i`, set by :has); segments share one width.
const src = "{#if msg}<div class=\"zw-seg-field\">{/if}<fieldset class=\"zw-seg zw-seg--{p.size}{#if p.full} zw-seg--full{/if}{#if p.icons_only} zw-seg--icons{/if}\" role=\"radiogroup\" aria-label=\"{p.label}\" style=\"--n:{n}\"{#if p.invalid} aria-invalid=\"true\"{/if}{#if msg} aria-describedby=\"zw-{p.name}-msg\"{/if}{#if p.disabled} disabled{/if}>" ++
    "<span class=\"zw-seg-pill zw-glass\" aria-hidden=\"true\"></span>" ++
    "{#each p.options as o}<label><input type=\"radio\" name=\"{p.name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{#if o.disabled} disabled{/if}{p.z}>" ++
    "{#if o.icon}<span class=\"zw-seg-icon\" aria-hidden=\"true\">{@html o.icon}</span>{/if}<span class=\"zw-seg-text\">{o.label}</span></label>{/each}</fieldset>" ++
    "{#if msg}<small id=\"zw-{p.name}-msg\" class=\"zw-help{#if p.invalid} zw-help--error{/if}\"{#if p.invalid} role=\"alert\"{/if}>{msg}</small></div>{/if}";

/// `msg` is the error if there is one, else the help.
const Data = struct { p: Props, n: usize, msg: []const u8 };

pub const Segmented = zv.View(src, Data);

pub fn segmented(p: Props) Segmented {
    // The pill handles up to 8 segments; a 9th would leave it stuck on the first one, so fail in every build mode.
    if (p.options.len < 2 or p.options.len > 8) @panic("segmented: needs 2 to 8 options");
    return .{ .data = .{ .p = p, .n = p.options.len, .msg = if (p.invalid.len > 0) p.invalid else p.help } };
}

test "segmented renders size, icon, disabled and icons-only" {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try segmented(.{ .name = "v", .label = "View", .size = .large, .full = true, .icons_only = true, .options = &.{
        .{ .value = "a", .label = "A", .selected = true, .icon = "<svg></svg>" },
        .{ .value = "b", .label = "B", .disabled = true },
    } }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "zw-seg zw-seg--large zw-seg--full zw-seg--icons") != null);
    try std.testing.expect(std.mem.find(u8, out, "<span class=\"zw-seg-icon\" aria-hidden=\"true\"><svg></svg></span><span class=\"zw-seg-text\">A</span>") != null);
    try std.testing.expect(std.mem.find(u8, out, "value=\"b\" disabled>") != null);
}

test "segmented shows help and error text" {
    var buf: [2048]u8 = undefined;
    const opts: []const Option = &.{ .{ .value = "a", .label = "A" }, .{ .value = "b", .label = "B" } };
    var w: std.Io.Writer = .fixed(&buf);
    try segmented(.{ .name = "v", .label = "View", .options = opts }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "aria-invalid") == null);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "zw-seg-field") == null);
    w = .fixed(&buf);
    try segmented(.{ .name = "v", .label = "View", .options = opts, .help = "Pick one" }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "aria-describedby=\"zw-v-msg\"") != null);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "<small id=\"zw-v-msg\" class=\"zw-help\">Pick one</small></div>") != null);
    w = .fixed(&buf);
    try segmented(.{ .name = "v", .label = "View", .options = opts, .help = "Pick one", .invalid = "Required" }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "aria-invalid=\"true\" aria-describedby=\"zw-v-msg\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "zw-help zw-help--error\" role=\"alert\">Required</small>") != null);
    try std.testing.expect(std.mem.find(u8, out, "Pick one") == null);
}
