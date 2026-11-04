//! Text field. Native input, macOS look. The label is visually hidden but announced.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-field{flex:1;min-width:0;display:block}
    \\.zw-sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
    \\.zw-field input{appearance:none;width:100%;height:var(--control-h);font:var(--body);letter-spacing:-.08px;color:var(--label);background:var(--content);border:0;
    \\border-radius:var(--radius-control);padding:0 10px;outline:none;box-shadow:var(--shadow);transition:box-shadow var(--speed)}
    \\.zw-field input::placeholder{color:var(--tertiary)}
    \\.zw-field input:focus{box-shadow:0 0 0 .5px var(--accent),0 0 0 3.5px color-mix(in srgb,var(--accent) 45%,transparent)}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    placeholder: []const u8 = "",
    value: []const u8 = "",
    type: []const u8 = "text",
    required: bool = false,
    autofocus: bool = false,
    z: Z = .{},
};

const src = "<label class=\"zw-field\"><span class=\"zw-sr\">{label}</span><input name=\"{name}\" type=\"{type}\" value=\"{value}\" placeholder=\"{placeholder}\" autocomplete=\"off\"" ++
    "{#if required} required{/if}{#if autofocus} autofocus{/if}{z}></label>";

pub const Field = zv.View(src, Props);

pub fn field(p: Props) Field {
    return .{ .data = p };
}
