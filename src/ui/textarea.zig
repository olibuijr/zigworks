//! Multi-line text field. Grows with its content (`field-sizing`) between `rows` and `max_rows` lines.
//! Optional help or error text and a character counter sit under the box (`.zw-help` comes from field.zig).
//! The counter is rendered with the initial length; z.js may keep it live through `data-count`.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-textarea{min-width:0;
    \\& label{display:block}
    \\& textarea{display:block;width:100%;min-height:calc(var(--rows) * 1lh + 16px);max-height:calc(var(--max-rows) * 1lh + 16px);field-sizing:content;resize:none;font:13px/18px var(--font);padding:8px 11px;
    \\&:disabled{opacity:.45}
    \\&[readonly]{background:var(--fill);box-shadow:none}
    \\&:is([aria-invalid=true],:user-invalid){box-shadow:0 0 0 1px var(--red)}
    \\&[aria-invalid=true]:focus{box-shadow:0 0 0 .5px var(--red),0 0 0 4px color-mix(in srgb,var(--red) 35%,transparent)}}}
    \\.zw-textarea--fixed textarea{field-sizing:fixed;height:calc(var(--rows) * 1lh + 16px)}
    \\.zw-textarea--vertical textarea{resize:vertical}
    \\.zw-textarea-foot{display:flex;align-items:baseline;justify-content:space-between;gap:12px;margin:4px 11px 0;
    \\& .zw-help{margin:0}}
    \\.zw-count{margin-left:auto;font:var(--callout);color:var(--secondary);font-variant-numeric:tabular-nums;white-space:nowrap}
    \\.zw-count--full{color:var(--red)}
    \\@media (pointer:coarse){.zw-textarea textarea{line-height:22px}}
    \\@media (forced-colors:active){.zw-textarea textarea{border:1px solid ButtonText;&:focus{outline:2px solid Highlight}}}
    \\
;

pub const Resize = enum { none, vertical };

pub const Props = struct {
    name: []const u8,
    /// Accessible name (not shown; use a placeholder or a setting row for visible text).
    label: []const u8,
    placeholder: []const u8 = "",
    value: []const u8 = "",
    /// Initial height in lines.
    rows: u8 = 3,
    /// With `grow`, the height at which it stops growing and scrolls.
    max_rows: u8 = 12,
    /// Grow with the content. Off keeps a fixed height of `rows` lines.
    grow: bool = true,
    /// Drag handle for the height: `.vertical`. Best with `grow = false`.
    resize: Resize = .none,
    required: bool = false,
    /// Dimmed and not focusable; the value is not submitted.
    disabled: bool = false,
    /// Focusable and submitted, but not editable.
    readonly: bool = false,
    /// Maximum length in characters (enforced by the browser); shows a "n / max" counter. 0 means no limit.
    maxlength: u16 = 0,
    /// Help text under the field. Replaced by `invalid` while that is set.
    help: []const u8 = "",
    /// Error message under the field (red). Also sets `aria-invalid`.
    invalid: []const u8 = "",
    z: Z = .{},
};

const src = "<div class=\"zw-textarea zw-textarea--{p.resize}{#if !p.grow} zw-textarea--fixed{/if}\"><label><span class=\"zw-sr\">{p.label}</span>" ++
    "<textarea class=\"zw-input\" name=\"{p.name}\" placeholder=\"{p.placeholder}\" rows=\"{p.rows}\" style=\"--rows:{p.rows};--max-rows:{p.max_rows}\"" ++
    "{#if p.maxlength} maxlength=\"{p.maxlength}\"{/if}{#if p.required} required{/if}{#if p.disabled} disabled{/if}{#if p.readonly} readonly{/if}" ++
    "{#if described} aria-describedby=\"{#if msg}zw-{p.name}-msg{/if}{#if both} {/if}{#if p.maxlength}zw-{p.name}-count{/if}\"{/if}" ++
    "{#if p.invalid} aria-invalid=\"true\"{/if}{p.z}>{p.value}</textarea></label>" ++
    "{#if described}<div class=\"zw-textarea-foot\">" ++
    "{#if msg}<small id=\"zw-{p.name}-msg\" class=\"zw-help{#if p.invalid} zw-help--error{/if}\"{#if p.invalid} role=\"alert\"{/if}>{msg}</small>{/if}" ++
    "{#if p.maxlength}<small id=\"zw-{p.name}-count\" class=\"zw-count{#if full} zw-count--full{/if}\" data-count=\"{p.maxlength}\">{count} / {p.maxlength}</small>{/if}" ++
    "</div>{/if}</div>";

/// Derived from the props: `msg` is the error if there is one, else the help; `count` is the
/// number of characters in `value`.
const Data = struct { p: Props, msg: []const u8, described: bool, both: bool, count: usize, full: bool };

pub const Textarea = zv.View(src, Data);

/// `textarea(.{ .name = "notes", .label = "Notes", .placeholder = "Add a note" })`
pub fn textarea(p: Props) Textarea {
    const msg = if (p.invalid.len > 0) p.invalid else p.help;
    var count: usize = 0;
    for (p.value) |c| {
        if (c & 0xC0 != 0x80) count += 1; // skip UTF-8 continuation bytes
    }
    return .{ .data = .{
        .p = p,
        .msg = msg,
        .described = msg.len > 0 or p.maxlength > 0,
        .both = msg.len > 0 and p.maxlength > 0,
        .count = count,
        .full = p.maxlength > 0 and count >= p.maxlength,
    } };
}

fn renderToBuf(buf: []u8, t: Textarea) ![]const u8 {
    var w: std.Io.Writer = .fixed(buf);
    try t.render(&w);
    return w.buffered();
}

test "plain textarea has no footer" {
    var buf: [1024]u8 = undefined;
    const out = try renderToBuf(&buf, textarea(.{ .name = "n", .label = "N", .value = "a<b" }));
    try std.testing.expect(std.mem.find(u8, out, "zw-textarea zw-textarea--none\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "--rows:3;--max-rows:12") != null);
    try std.testing.expect(std.mem.find(u8, out, ">a&lt;b</textarea>") != null);
    try std.testing.expect(std.mem.find(u8, out, "zw-textarea-foot") == null);
}

test "counter, help and error" {
    var buf: [2048]u8 = undefined;
    const out = try renderToBuf(&buf, textarea(.{ .name = "n", .label = "N", .value = "héé", .maxlength = 10, .help = "Be kind", .grow = false, .resize = .vertical }));
    try std.testing.expect(std.mem.find(u8, out, "zw-textarea--vertical zw-textarea--fixed") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-describedby=\"zw-n-msg zw-n-count\"") != null);
    try std.testing.expect(std.mem.find(u8, out, ">3 / 10</small>") != null);
    try std.testing.expect(std.mem.find(u8, out, "zw-count--full") == null);

    const full = try renderToBuf(&buf, textarea(.{ .name = "n", .label = "N", .value = "abc", .maxlength = 3, .invalid = "Too long" }));
    try std.testing.expect(std.mem.find(u8, full, "zw-count zw-count--full") != null);
    try std.testing.expect(std.mem.find(u8, full, "aria-invalid=\"true\"") != null);
    try std.testing.expect(std.mem.find(u8, full, "role=\"alert\">Too long</small>") != null);
}
