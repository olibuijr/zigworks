//! macOS switch row. A real checkbox (form value, keyboard, screen readers) drawn as a switch;
//! laid out like `setting`, so switches and settings rows stack with separators.
//! With `z`, z.js sends `name=on` when switched on and nothing when off.
//! Optional description line, mini/small/regular sizes, disabled state and label on either side.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-toggle{--zw-w:46px;--zw-h:26px;--zw-kw:28px;--zw-kh:22px;cursor:default;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-toggle--small{--zw-w:38px;--zw-h:22px;--zw-kw:24px;--zw-kh:18px}
    \\.zw-toggle--mini{--zw-w:30px;--zw-h:18px;--zw-kw:20px;--zw-kh:14px}
    \\.zw-toggle input{appearance:none;flex:none;position:relative;width:var(--zw-w);height:var(--zw-h);margin:0;border-radius:calc(var(--zw-h)/2);background:var(--fill-strong);overflow:visible;
    \\box-shadow:inset 0 0 0 .5px var(--separator),inset 0 1px 2px rgba(0,0,0,.08);transition:background-color var(--speed)}
    \\.zw-toggle input::after{content:"";position:absolute;top:2px;left:2px;width:var(--zw-kw);height:var(--zw-kh);border-radius:calc(var(--zw-kh)/2);background:var(--knob);
    \\box-shadow:0 0 0 .5px rgba(0,0,0,.04),0 .5px 1px rgba(0,0,0,.12),0 2px 6px rgba(0,0,0,.16);
    \\transition:translate var(--dur-bouncy) var(--spring-bouncy),inset var(--dur-bouncy) var(--spring-bouncy),width var(--dur-bouncy) var(--spring-bouncy),height var(--dur-bouncy) var(--spring-bouncy),
    \\border-radius var(--dur-bouncy) var(--spring-bouncy),background-color var(--speed),box-shadow var(--speed)}
    \\.zw-toggle input:checked{background:var(--accent)}
    \\.zw-toggle input:checked::after{translate:calc(var(--zw-w) - var(--zw-kw) - 4px) 0}
    \\.zw-toggle:active input::after{top:calc((var(--zw-h) - var(--zw-kh) - 8px)/2);left:-3px;width:calc(var(--zw-kw) + 10px);height:calc(var(--zw-kh) + 8px);border-radius:calc(var(--zw-kh)/2 + 4px);background:var(--glass-clear);box-shadow:var(--glass-rim),0 0 0 .5px rgba(0,0,0,.08),0 4px 12px rgba(0,0,0,.18);
    \\-webkit-backdrop-filter:var(--glass-filter-clear);backdrop-filter:var(--glass-filter-clear);transition-duration:var(--dur-snappy);transition-timing-function:var(--spring-snappy)}
    \\.zw-refract .zw-toggle:active input::after{backdrop-filter:url(#zw-lens-knob) var(--glass-filter-clear)}
    \\.zw-toggle input:focus-visible{outline-offset:2px}
    \\.zw-toggle__txt{display:flex;flex-direction:column;flex:1 1 0;min-width:0}
    \\.zw-toggle__desc{font:var(--callout);color:var(--secondary)}
    \\.zw-toggle.zw-toggle--trailing{justify-content:flex-start;gap:6px 10px}
    \\.zw-toggle.zw-toggle--trailing>input{order:-1;margin-left:0}
    \\.zw-toggle--disabled{opacity:.4;pointer-events:none}
    \\@media (pointer:coarse){.zw-toggle{min-height:44px}}
    \\
;

pub const Size = enum { mini, small, regular };
/// Which side the label sits on: `.leading` (default, switch trailing) or `.trailing` (switch first).
pub const Side = enum { leading, trailing };

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    on: bool = false,
    /// Secondary line under the label.
    description: []const u8 = "",
    /// Switch size: 30x18, 38x22 or 46x26.
    size: Size = .regular,
    /// `.trailing` puts the switch before the label, like a checkbox.
    label_side: Side = .leading,
    /// Dimmed and not interactive; not submitted.
    disabled: bool = false,
    z: Z = .{},
};

const src = "<label class=\"zw-toggle zw-setting zw-toggle--{size} zw-toggle--{label_side}{#if disabled} zw-toggle--disabled{/if}\">" ++
    "<span class=\"zw-toggle__txt\"><span>{label}</span>{#if description}<span class=\"zw-toggle__desc\">{description}</span>{/if}</span>" ++
    "<input type=\"checkbox\" role=\"switch\" name=\"{name}\"{#if on} checked{/if}{#if disabled} disabled{/if}{z}></label>";

pub const Toggle = zv.View(src, Props);

/// `toggle(.{ .name = "wifi", .label = "Wi-Fi", .description = "Join known networks", .on = true })`
pub fn toggle(p: Props) Toggle {
    return .{ .data = p };
}

test "toggle renders size, side, description and disabled" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try toggle(.{ .name = "w", .label = "Wi-Fi", .description = "Known networks", .size = .mini, .label_side = .trailing, .disabled = true }).render(&w);
    const s = w.buffered();
    try std.testing.expect(std.mem.find(u8, s, "zw-toggle--mini zw-toggle--trailing zw-toggle--disabled") != null);
    try std.testing.expect(std.mem.find(u8, s, "zw-toggle__desc\">Known networks") != null);
    try std.testing.expect(std.mem.find(u8, s, " disabled>") != null);
}
