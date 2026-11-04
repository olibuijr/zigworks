//! Text field. Native input, macOS look. The label is visually hidden but announced.
//! Optional help or error text sits under the box and is linked with `aria-describedby`;
//! `prefix` and `suffix` (a currency sign, a unit) sit inside the box.
//! `type = "search"` shows a styled clear button (WebKit and Blink); it is also used by search.zig.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-field{flex:1;min-width:0;display:block}
    \\.zw-sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
    \\.zw-field-box{display:flex;align-items:center;gap:6px;width:100%;height:var(--control-h);padding:0 11px;color:var(--label);background:var(--content);
    \\border-radius:var(--radius-control);box-shadow:var(--shadow);transition:box-shadow var(--dur) var(--spring)}
    \\.zw-field-box:focus-within{box-shadow:0 0 0 .5px var(--accent),0 0 0 4px color-mix(in srgb,var(--accent) 40%,transparent)}
    \\.zw-field input{appearance:none;flex:1;min-width:0;width:100%;height:100%;padding:0;border:0;outline:none;background:transparent;font:var(--body);letter-spacing:-.08px;color:inherit}
    \\.zw-field input::placeholder{color:var(--secondary);opacity:.75}
    \\.zw-field input[type=number]{appearance:textfield}
    \\.zw-field input::-webkit-inner-spin-button,.zw-field input::-webkit-outer-spin-button{appearance:none;margin:0}
    \\.zw-affix{color:var(--secondary);white-space:nowrap;user-select:none}
    \\.zw-field-box:has(input:disabled){opacity:.45}
    \\.zw-field-box:has(input[readonly]){background:var(--fill);box-shadow:none}
    \\.zw-field-box:has(input[aria-invalid=true]){box-shadow:0 0 0 1px var(--red)}
    \\.zw-field-box:has(input:user-invalid){box-shadow:0 0 0 1px var(--red)}
    \\.zw-field-box:has(input[aria-invalid=true]):focus-within{box-shadow:0 0 0 .5px var(--red),0 0 0 4px color-mix(in srgb,var(--red) 35%,transparent)}
    \\.zw-help{display:block;margin:4px 11px 0;font:var(--callout);color:var(--secondary)}
    \\.zw-help--error{color:var(--red)}
    \\.zw-field input::-webkit-search-cancel-button,.zw-search input::-webkit-search-cancel-button{appearance:none;display:block;box-sizing:content-box;width:16px;height:16px;margin:0;border-radius:50%;
    \\background:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='8' fill='%23888' fill-opacity='.7'/%3E%3Cpath d='m5.5 5.5 5 5m0-5-5 5' stroke='white' stroke-width='1.6' stroke-linecap='round'/%3E%3C/svg%3E") center/16px no-repeat}
    \\@media (pointer:coarse){.zw-field-box{height:44px}
    \\.zw-field input::-webkit-search-cancel-button,.zw-search input::-webkit-search-cancel-button{padding:14px;margin:0 -10px 0 0;background-origin:content-box}}
    \\@media (forced-colors:active){.zw-field-box{border:1px solid ButtonText}.zw-field-box:focus-within{outline:2px solid Highlight}}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    placeholder: []const u8 = "",
    value: []const u8 = "",
    /// `email`, `password`, `number`, `url`, `search`...
    type: []const u8 = "text",
    required: bool = false,
    autofocus: bool = false,
    /// Dimmed and not focusable; the value is not submitted.
    disabled: bool = false,
    /// Focusable and submitted, but not editable.
    readonly: bool = false,
    /// Help text under the field. Replaced by `invalid` while that is set.
    help: []const u8 = "",
    /// Error message under the field (red). Also sets `aria-invalid`.
    invalid: []const u8 = "",
    /// Text inside the box before the input (`$`) and after it (`kg`); read as part of the label.
    prefix: []const u8 = "",
    suffix: []const u8 = "",
    /// The `autocomplete` token: `email`, `current-password`, `one-time-code`... (`off` by default).
    autocomplete: []const u8 = "off",
    /// Virtual keyboard: `numeric`, `decimal`, `tel`, `email`, `url`, `search`. Empty leaves it to `type`.
    inputmode: []const u8 = "",
    /// Regular expression the value must match when the form is submitted.
    pattern: []const u8 = "",
    /// Maximum length in characters; 0 means no limit.
    maxlength: u16 = 0,
    z: Z = .{},
};

const src = "<div class=\"zw-field\"><label class=\"zw-field-box\"><span class=\"zw-sr\">{p.label}</span>" ++
    "{#if p.prefix}<span class=\"zw-affix\">{p.prefix}</span>{/if}" ++
    "<input name=\"{p.name}\" type=\"{p.type}\" value=\"{p.value}\" placeholder=\"{p.placeholder}\" autocomplete=\"{p.autocomplete}\"" ++
    "{#if p.inputmode} inputmode=\"{p.inputmode}\"{/if}{#if p.pattern} pattern=\"{p.pattern}\"{/if}{#if p.maxlength} maxlength=\"{p.maxlength}\"{/if}" ++
    "{#if p.required} required{/if}{#if p.autofocus} autofocus{/if}{#if p.disabled} disabled{/if}{#if p.readonly} readonly{/if}" ++
    "{#if msg} aria-describedby=\"zw-{p.name}-msg\"{/if}{#if p.invalid} aria-invalid=\"true\"{/if}{p.z}>" ++
    "{#if p.suffix}<span class=\"zw-affix\">{p.suffix}</span>{/if}</label>" ++
    "{#if msg}<small id=\"zw-{p.name}-msg\" class=\"zw-help{#if p.invalid} zw-help--error{/if}\"{#if p.invalid} role=\"alert\"{/if}>{msg}</small>{/if}</div>";

/// `msg` is the text under the field: the error if there is one, else the help.
const Data = struct { p: Props, msg: []const u8 };

pub const Field = zv.View(src, Data);

/// `field(.{ .name = "email", .label = "Email", .type = "email", .help = "We never share it" })`
pub fn field(p: Props) Field {
    return .{ .data = .{ .p = p, .msg = if (p.invalid.len > 0) p.invalid else p.help } };
}

fn renderToBuf(buf: []u8, f: Field) ![]const u8 {
    var w: std.Io.Writer = .fixed(buf);
    try f.render(&w);
    return w.buffered();
}

test "plain field keeps its old attributes and has no message" {
    var buf: [1024]u8 = undefined;
    const out = try renderToBuf(&buf, field(.{ .name = "a", .label = "A", .required = true }));
    try std.testing.expect(std.mem.find(u8, out, "<input name=\"a\" type=\"text\" value=\"\" placeholder=\"\" autocomplete=\"off\" required>") != null);
    try std.testing.expect(std.mem.find(u8, out, "<small") == null);
    try std.testing.expect(std.mem.find(u8, out, "aria-describedby") == null);
}

test "help, error, affixes and passthrough attributes" {
    var buf: [2048]u8 = undefined;
    const out = try renderToBuf(&buf, field(.{ .name = "w", .label = "Weight", .suffix = "kg", .prefix = "~", .help = "Help <me>", .maxlength = 5, .inputmode = "decimal", .disabled = true }));
    try std.testing.expect(std.mem.find(u8, out, "<span class=\"zw-affix\">kg</span>") != null);
    try std.testing.expect(std.mem.find(u8, out, "maxlength=\"5\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "inputmode=\"decimal\"") != null);
    try std.testing.expect(std.mem.find(u8, out, " disabled") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-describedby=\"zw-w-msg\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "Help &lt;me&gt;</small>") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-invalid") == null);

    const bad = try renderToBuf(&buf, field(.{ .name = "w", .label = "Weight", .help = "Help", .invalid = "Too heavy" }));
    try std.testing.expect(std.mem.find(u8, bad, "aria-invalid=\"true\"") != null);
    try std.testing.expect(std.mem.find(u8, bad, "zw-help zw-help--error\" role=\"alert\">Too heavy</small>") != null);
    try std.testing.expect(std.mem.find(u8, bad, ">Help<") == null);
}
