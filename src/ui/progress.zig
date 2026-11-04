//! Progress: a determinate bar (`value` 0-100), a circular ring (`ring`) or, with `value = null`,
//! an indeterminate spinner. Sizes, tones and an optional caption / percentage.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-progress{--c:var(--accent);--h:6px;display:block;width:100%;height:var(--h);border-radius:calc(var(--h)/2);background:var(--fill-strong);box-shadow:inset 0 .5px 1px rgba(0,0,0,.1);overflow:hidden;
    \\  &>span{display:block;height:100%;width:var(--v);border-radius:inherit;background:linear-gradient(color-mix(in srgb,var(--c) 75%,#fff),var(--c));box-shadow:inset 0 .5px 0 rgba(255,255,255,.45);transition:width var(--dur) var(--spring)}
    \\}
    \\.zw-progress--small{--h:4px}
    \\.zw-progress--large{--h:10px}
    \\.zw-tone-success{--c:var(--green)}
    \\.zw-tone-warning{--c:var(--orange)}
    \\.zw-tone-error{--c:var(--red)}
    \\.zw-meter{display:flex;flex-direction:column;gap:6px;width:100%}
    \\.zw-meter-head{display:flex;justify-content:space-between;gap:12px;font:var(--callout);color:var(--secondary);
    \\  &:empty{display:none}
    \\}
    \\.zw-meter-pct{margin-left:auto;font-variant-numeric:tabular-nums}
    \\.zw-inline{display:inline-flex;align-items:center;gap:8px;font:var(--callout);color:var(--secondary)}
    \\.zw-ring{--c:var(--accent);--d:44px;--sw:4;position:relative;display:inline-grid;place-items:center;flex:none;width:var(--d);height:var(--d);vertical-align:middle;
    \\  & svg{position:absolute;inset:0;width:100%;height:100%;rotate:-90deg;overflow:visible}
    \\  & circle{fill:none;stroke-width:var(--sw)}
    \\}
    \\.zw-ring--small{--d:24px;--sw:5}
    \\.zw-ring--large{--d:72px;--sw:3.5}
    \\.zw-ring-track{stroke:var(--fill-strong)}
    \\.zw-ring-bar{stroke:var(--c);stroke-dasharray:var(--n) 100;transition:stroke-dasharray var(--dur) var(--spring),opacity var(--speed)}
    \\.zw-ring--zero .zw-ring-bar{opacity:0}
    \\.zw-ring-v{position:relative;font:600 calc(var(--d)*.27)/1 var(--font);font-variant-numeric:tabular-nums;color:var(--label)}
    \\.zw-ring--small .zw-ring-v{display:none}
    \\.zw-spinner{--d:16px;--t:2px;display:inline-block;flex:none;width:var(--d);height:var(--d);border-radius:50%;vertical-align:middle;animation:zw-spin .9s linear infinite;
    \\  background:conic-gradient(transparent 10%,var(--c,var(--secondary)));
    \\  mask:radial-gradient(farthest-side,transparent calc(100% - var(--t) - .5px),#000 calc(100% - var(--t)))}
    \\.zw-spinner--small{--d:12px;--t:1.5px}
    \\.zw-spinner--large{--d:28px;--t:3px}
    \\@keyframes zw-spin{to{rotate:360deg}}
    \\@media (forced-colors:active){
    \\  .zw-progress{forced-color-adjust:none;background:Canvas;box-shadow:inset 0 0 0 1px CanvasText;&>span{background:Highlight}}
    \\  .zw-ring-track{stroke:GrayText}
    \\  .zw-ring-bar{stroke:Highlight}
    \\}
    \\
;

pub const Size = enum { small, regular, large };
pub const Tone = enum { accent, success, warning, @"error" };

pub const Props = struct {
    /// Percent 0-100, or null for an indeterminate spinner.
    value: ?u8,
    /// Accessible name.
    label: []const u8,
    size: Size = .regular,
    /// Fill color: accent, success (green), warning (orange) or error (red).
    tone: Tone = .accent,
    /// Visible caption: above a bar, beside a ring or spinner.
    text: []const u8 = "",
    /// Show the percentage: right-aligned above a bar, in the middle of a ring.
    show_value: bool = false,
    /// Draw a determinate value as a circular ring instead of a bar.
    ring: bool = false,
};

const Data = struct { p: Props, v: u8, caption: bool, zero: bool };

const bar = "{#if caption}<span class=\"zw-meter\"><span class=\"zw-meter-head\">{#if p.text}<span>{p.text}</span>{/if}{#if p.show_value}<span class=\"zw-meter-pct\">{v}%</span>{/if}</span>{/if}" ++
    "<span class=\"zw-progress zw-progress--{p.size} zw-tone-{p.tone}\" role=\"progressbar\" aria-label=\"{p.label}\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"{v}\" style=\"--v:{v}%\"><span></span></span>" ++
    "{#if caption}</span>{/if}";

const ring = "{#if p.text}<span class=\"zw-inline\">{/if}" ++
    "<span class=\"zw-ring zw-ring--{p.size} zw-tone-{p.tone}{#if zero} zw-ring--zero{/if}\" role=\"progressbar\" aria-label=\"{p.label}\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"{v}\" style=\"--n:{v}\">" ++
    "<svg viewBox=\"0 0 36 36\" aria-hidden=\"true\" focusable=\"false\"><circle class=\"zw-ring-track\" cx=\"18\" cy=\"18\" r=\"16\" pathLength=\"100\"/><circle class=\"zw-ring-bar\" cx=\"18\" cy=\"18\" r=\"16\" pathLength=\"100\"/></svg>" ++
    "{#if p.show_value}<span class=\"zw-ring-v\">{v}%</span>{/if}</span>" ++
    "{#if p.text}<span>{p.text}</span></span>{/if}";

const spinner = "{#if p.text}<span class=\"zw-inline\">{/if}" ++
    "<span class=\"zw-spinner zw-spinner--{p.size} zw-tone-{p.tone}\" role=\"status\" aria-label=\"{p.label}\"></span>" ++
    "{#if p.text}<span>{p.text}</span></span>{/if}";

const src = "{#if p.value}{#if p.ring}" ++ ring ++ "{:else}" ++ bar ++ "{/if}{:else}" ++ spinner ++ "{/if}";

pub const Progress = zv.View(src, Data);

/// `progress(.{ .value = 42, .label = "Download", .text = "Downloading", .show_value = true })`
pub fn progress(p: Props) Progress {
    const v: u8 = @min(p.value orelse 0, 100);
    return .{ .data = .{ .p = p, .v = v, .caption = !p.ring and (p.text.len > 0 or p.show_value), .zero = v == 0 } };
}

fn expectHas(p: Props, needle: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try progress(p).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), needle) != null);
}

test "bar, caption, ring and spinner" {
    try expectHas(.{ .value = 42, .label = "x" }, "aria-valuenow=\"42\"");
    try expectHas(.{ .value = 200, .label = "x" }, "aria-valuenow=\"100\"");
    try expectHas(.{ .value = 42, .label = "x", .text = "Copying", .show_value = true }, "<span class=\"zw-meter-pct\">42%</span>");
    try expectHas(.{ .value = 42, .label = "x", .tone = .@"error", .size = .large }, "zw-progress--large zw-tone-error");
    try expectHas(.{ .value = 0, .label = "x", .ring = true }, "zw-ring--zero");
    try expectHas(.{ .value = 10, .label = "x", .ring = true, .show_value = true }, "<span class=\"zw-ring-v\">10%</span>");
    try expectHas(.{ .value = null, .label = "x", .text = "Indexing" }, "zw-inline");
}
