//! Count or status badge.
const zv = @import("../view.zig");

pub const css =
    \\.zw-badge{display:inline-block;min-width:20px;padding:1px 7px;border-radius:6px;font:var(--callout);font-weight:600;font-variant-numeric:tabular-nums;text-align:center;
    \\background:var(--fill);color:var(--secondary)}
    \\
;

pub const Props = struct {
    text: []const u8,
    id: []const u8 = "",
    /// Out-of-band: in a z.js response, replaces the element with the same `id`.
    oob: bool = false,
};

const src = "<span class=\"zw-badge\"{#if id} id=\"{id}\"{/if}{#if oob} z-oob{/if}>{text}</span>";

pub const Badge = zv.View(src, Props);

pub fn badge(p: Props) Badge {
    return .{ .data = p };
}
