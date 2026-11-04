//! Count or status badge.
const zv = @import("../view.zig");

pub const css =
    \\.zw-badge{display:inline-block;min-width:22px;padding:2px 8px;border-radius:999px;font:var(--callout);font-weight:600;font-variant-numeric:tabular-nums;text-align:center;
    \\background:var(--fill);color:var(--secondary);box-shadow:inset 0 0 0 .5px var(--separator)}
    \\.zw-badge[z-oob]{animation:zw-pop var(--dur-bouncy) var(--spring-bouncy)}
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
