//! Multi-line text field. Grows with its content (`field-sizing`) between `rows` and 12 lines.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-textarea{display:block;min-width:0}
    \\.zw-textarea textarea{display:block;width:100%;min-height:calc(var(--rows) * 18px + 16px);max-height:calc(12 * 18px + 16px);field-sizing:content;resize:none;
    \\font:13px/18px var(--font);letter-spacing:-.08px;color:var(--label);background:var(--content);border:0;border-radius:var(--radius-control);padding:8px 11px;outline:none;
    \\box-shadow:var(--shadow);transition:box-shadow var(--dur) var(--spring)}
    \\.zw-textarea textarea::placeholder{color:var(--tertiary)}
    \\.zw-textarea textarea:focus{box-shadow:0 0 0 .5px var(--accent),0 0 0 4px color-mix(in srgb,var(--accent) 40%,transparent)}
    \\
;

pub const Props = struct {
    name: []const u8,
    /// Accessible name (not shown; use a placeholder or a setting row for visible text).
    label: []const u8,
    placeholder: []const u8 = "",
    value: []const u8 = "",
    /// Initial height in lines.
    rows: u8 = 3,
    required: bool = false,
    z: Z = .{},
};

const src = "<label class=\"zw-textarea\"><span class=\"zw-sr\">{label}</span><textarea name=\"{name}\" placeholder=\"{placeholder}\" rows=\"{rows}\" style=\"--rows:{rows}\"" ++
    "{#if required} required{/if}{z}>{value}</textarea></label>";

pub const Textarea = zv.View(src, Props);

/// `textarea(.{ .name = "notes", .label = "Notes", .placeholder = "Add a note" })`
pub fn textarea(p: Props) Textarea {
    return .{ .data = p };
}
