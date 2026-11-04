//! Progress: a determinate bar (`value` 0-100), a circular ring (`ring`) or, with `value = null`,
//! an indeterminate spinner (or, with `bar`, an indeterminate bar). Sizes, tones, an optional
//! caption / percentage, and `id` / `oob` so a server response can update it in place.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-progress{--c:var(--accent);--h:6px;display:block;width:100%;height:var(--h);border-radius:calc(var(--h)/2);background:var(--fill-strong);box-shadow:inset 0 .5px 1px rgba(0,0,0,.1);overflow:hidden;
    \\  &>span{display:block;height:100%;width:var(--v);border-radius:inherit;background:linear-gradient(color-mix(in srgb,var(--c) 75%,#fff),var(--c));box-shadow:inset 0 .5px 0 rgba(255,255,255,.45);transition:width var(--dur) var(--spring)}
    \\}
    \\.zw-progress.zw-progress--busy>span{width:40%;transition:none;animation:zw-slide 1.4s ease-in-out infinite}
    \\.zw-progress--small{--h:4px}
    \\.zw-progress--large{--h:10px}
    \\.zw-tone-accent{--c:var(--accent)}
    \\.zw-tone-neutral{--c:var(--secondary)}
    \\.zw-tone-success{--c:var(--green)}
    \\.zw-tone-warning{--c:var(--orange)}
    \\.zw-tone-error{--c:var(--red)}
    \\.zw-meter{display:flex;flex-direction:column;gap:6px;width:100%}
    \\.zw-meter-head{display:flex;justify-content:space-between;gap:12px;font:var(--callout);color:var(--secondary);
    \\  &:empty{display:none}
    \\}
    \\.zw-meter-pct{margin-left:auto;font-variant-numeric:tabular-nums}
    \\.zw-inline{display:inline-flex;align-items:center;gap:8px;font:var(--callout);font-variant-numeric:tabular-nums;color:var(--secondary)}
    \\.zw-ring{--d:44px;--sw:4;position:relative;display:inline-grid;place-items:center;flex:none;width:var(--d);height:var(--d);vertical-align:middle;
    \\  & svg{position:absolute;inset:0;width:100%;height:100%;rotate:-90deg;overflow:visible}
    \\  & circle{fill:none;stroke-width:var(--sw)}
    \\}
    \\.zw-ring--small{--d:24px;--sw:5}
    \\.zw-ring--large{--d:72px;--sw:3.5}
    \\.zw-ring-track{stroke:var(--fill-strong)}
    \\.zw-ring-bar{stroke:var(--c);stroke-dasharray:var(--n) 100;transition:stroke-dasharray var(--dur) var(--spring),opacity var(--speed)}
    \\.zw-ring--zero .zw-ring-bar{opacity:0}
    \\.zw-ring-v{position:relative;font:600 calc(var(--d)*.27)/1 var(--font);font-variant-numeric:tabular-nums;color:var(--label)}
    \\.zw-spinner{--d:16px;--t:2px;display:inline-block;flex:none;width:var(--d);height:var(--d);border-radius:50%;vertical-align:middle;animation:zw-spin .9s linear infinite;
    \\  background:conic-gradient(transparent 10%,var(--c));
    \\  mask:radial-gradient(farthest-side,transparent calc(100% - var(--t) - .5px),#000 calc(100% - var(--t)))}
    \\.zw-spinner--small{--d:12px;--t:1.5px}
    \\.zw-spinner--large{--d:28px;--t:3px}
    \\@keyframes zw-spin{to{rotate:360deg}}
    \\@keyframes zw-slide{from{translate:-100%}to{translate:250%}}
    \\@media (prefers-reduced-motion:reduce){.zw-progress.zw-progress--busy>span{width:100%;opacity:.4}}
    \\@media (forced-colors:active){
    \\  .zw-progress{forced-color-adjust:none;background:Canvas;box-shadow:inset 0 0 0 1px CanvasText;&>span{background:Highlight}}
    \\  .zw-ring-track{stroke:GrayText}
    \\  .zw-ring-bar{stroke:Highlight}
    \\}
    \\
;

pub const Size = enum { small, regular, large };
pub const Tone = enum { accent, neutral, success, warning, @"error" };

pub const Props = struct {
    /// Percent 0-100, or null for an indeterminate spinner (or bar, see `bar`).
    value: ?u8,
    /// Accessible name.
    label: []const u8,
    size: Size = .regular,
    /// Fill color: accent (blue), neutral (gray), success (green), warning (orange) or error (red).
    tone: Tone = .accent,
    /// Visible caption: above a bar, beside a ring or spinner.
    text: []const u8 = "",
    /// Show the percentage: right-aligned above a bar, in the middle of a ring (beside a small ring).
    show_value: bool = false,
    /// Draw a determinate value as a circular ring instead of a bar.
    ring: bool = false,
    /// With `value = null`: draw an indeterminate bar instead of a spinner.
    bar: bool = false,
    /// Element id, so a server response can target it or replace it (see `oob`).
    id: []const u8 = "",
    /// Out-of-band: in a z.js response, replaces the element with the same `id`. Needs `id`.
    oob: bool = false,
};

const Data = struct {
    p: Props,
    v: u8,
    is_ring: bool,
    is_bar: bool,
    busy: bool,
    zero: bool,
    caption: bool,
    pct: bool,
    inner: bool,
    side: bool,
    inline_: bool,
};

const attrs = "{#if p.id} id=\"{p.id}\"{/if}{#if p.oob} z-oob{/if}";

const bar = "{#if caption}<span class=\"zw-meter\"" ++ attrs ++ "><span class=\"zw-meter-head\">{#if p.text}<span>{p.text}</span>{/if}{#if pct}<span class=\"zw-meter-pct\">{v}%</span>{/if}</span>{/if}" ++
    "<span class=\"zw-progress zw-progress--{p.size} zw-tone-{p.tone}{#if busy} zw-progress--busy{/if}\"{#if !caption}" ++ attrs ++ "{/if} role=\"progressbar\" aria-label=\"{p.label}\" aria-valuemin=\"0\" aria-valuemax=\"100\"{#if p.value} aria-valuenow=\"{v}\"{/if} style=\"--v:{v}%\"><span></span></span>" ++
    "{#if caption}</span>{/if}";

const tail = "{#if inline_}{#if p.text}<span>{p.text}</span>{/if}{#if side}<span>{v}%</span>{/if}</span>{/if}";

const ring = "{#if inline_}<span class=\"zw-inline\"" ++ attrs ++ ">{/if}" ++
    "<span class=\"zw-ring zw-ring--{p.size} zw-tone-{p.tone}{#if zero} zw-ring--zero{/if}\"{#if !inline_}" ++ attrs ++ "{/if} role=\"progressbar\" aria-label=\"{p.label}\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"{v}\" style=\"--n:{v}\">" ++
    "<svg viewBox=\"0 0 36 36\" aria-hidden=\"true\" focusable=\"false\"><circle class=\"zw-ring-track\" cx=\"18\" cy=\"18\" r=\"16\" pathLength=\"100\"/><circle class=\"zw-ring-bar\" cx=\"18\" cy=\"18\" r=\"16\" pathLength=\"100\"/></svg>" ++
    "{#if inner}<span class=\"zw-ring-v\">{v}%</span>{/if}</span>" ++ tail;

const spinner = "{#if inline_}<span class=\"zw-inline\"" ++ attrs ++ ">{/if}" ++
    "<span class=\"zw-spinner zw-spinner--{p.size} zw-tone-{p.tone}\"{#if !inline_}" ++ attrs ++ "{/if} role=\"status\" aria-label=\"{p.label}\"></span>" ++ tail;

const src = "{#if is_ring}" ++ ring ++ "{:else}{#if is_bar}" ++ bar ++ "{:else}" ++ spinner ++ "{/if}{/if}";

pub const Progress = zv.View(src, Data);

/// `progress(.{ .value = 42, .label = "Download", .text = "Downloading", .show_value = true })`
pub fn progress(p: Props) Progress {
    const known = p.value != null;
    const is_ring = p.ring and known;
    const is_bar = !is_ring and (known or p.bar);
    const pct = p.show_value and known;
    const side = is_ring and pct and p.size == .small;
    return .{ .data = .{
        .p = p,
        .v = @min(p.value orelse 0, 100),
        .is_ring = is_ring,
        .is_bar = is_bar,
        .busy = is_bar and !known,
        .zero = p.value == 0,
        .caption = is_bar and (p.text.len > 0 or pct),
        .pct = pct,
        .inner = is_ring and pct and !side,
        .side = side,
        .inline_ = !is_bar and (p.text.len > 0 or side),
    } };
}

fn expectHas(p: Props, needle: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try progress(p).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), needle) != null);
}

fn expectNot(p: Props, needle: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try progress(p).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), needle) == null);
}

test "bar, caption, ring and spinner" {
    try expectHas(.{ .value = 42, .label = "x" }, "aria-valuenow=\"42\"");
    try expectHas(.{ .value = 200, .label = "x" }, "aria-valuenow=\"100\"");
    try expectHas(.{ .value = 42, .label = "x", .text = "Copying", .show_value = true }, "<span class=\"zw-meter-pct\">42%</span>");
    try expectHas(.{ .value = 42, .label = "x", .tone = .@"error", .size = .large }, "zw-progress--large zw-tone-error");
    try expectHas(.{ .value = 0, .label = "x", .ring = true }, "zw-ring--zero");
    try expectHas(.{ .value = 10, .label = "x", .ring = true, .show_value = true }, "<span class=\"zw-ring-v\">10%</span>");
    try expectHas(.{ .value = null, .label = "x", .text = "Indexing" }, "zw-inline");
    try expectHas(.{ .value = null, .label = "x" }, "zw-spinner zw-spinner--regular zw-tone-accent");
}

test "id and oob go on the outermost element" {
    try expectHas(.{ .value = 5, .label = "x", .id = "p1", .oob = true }, "zw-tone-accent\" id=\"p1\" z-oob role=\"progressbar\"");
    try expectHas(.{ .value = 5, .label = "x", .text = "t", .id = "p1" }, "<span class=\"zw-meter\" id=\"p1\">");
    try expectHas(.{ .value = 5, .label = "x", .ring = true, .text = "t", .id = "p1" }, "<span class=\"zw-inline\" id=\"p1\">");
    try expectHas(.{ .value = null, .label = "x", .id = "p1", .oob = true }, "id=\"p1\" z-oob role=\"status\"");
    try expectNot(.{ .value = 5, .label = "x", .text = "t", .id = "p1" }, "zw-progress--regular zw-tone-accent\" id=");
    try expectNot(.{ .value = 5, .label = "x" }, " id=");
}

test "indeterminate bar and small ring percentage" {
    try expectHas(.{ .value = null, .label = "x", .bar = true }, "zw-progress--busy\" role=\"progressbar\"");
    try expectNot(.{ .value = null, .label = "x", .bar = true, .show_value = true }, "aria-valuenow");
    try expectNot(.{ .value = null, .label = "x", .bar = true, .show_value = true }, "%</span>");
    try expectHas(.{ .value = null, .label = "x", .bar = true, .text = "Preparing" }, "<span class=\"zw-meter-head\"><span>Preparing</span></span>");
    try expectHas(.{ .value = 64, .label = "x", .ring = true, .size = .small, .show_value = true }, "<span>64%</span></span>");
    try expectNot(.{ .value = 64, .label = "x", .ring = true, .size = .small, .show_value = true }, "zw-ring-v");
    try expectNot(.{ .value = 64, .label = "x", .ring = true, .show_value = true, .text = "t" }, "<span>64%</span>");
}
