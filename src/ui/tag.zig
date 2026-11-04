//! Tag: a small capsule label (tokens, filters, categories). Give it `remove` to show a ×
//! button that sends that request and deletes the tag.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-tag{display:inline-flex;align-items:center;gap:2px;height:24px;padding:0 10px;border-radius:999px;font:var(--callout);font-weight:500;white-space:nowrap;
    \\color:color-mix(in srgb,var(--accent) 85%,var(--label));background:color-mix(in srgb,var(--accent) 13%,transparent);box-shadow:inset 0 0 0 .5px color-mix(in srgb,var(--accent) 25%,transparent)}
    \\.zw-tag:has(button){padding-right:3px}
    \\.zw-tag button{appearance:none;display:grid;place-items:center;width:18px;height:18px;border:0;border-radius:50%;background:transparent;color:inherit;font:600 13px/1 var(--font);cursor:default;
    \\transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-tag button:hover{background:color-mix(in srgb,var(--accent) 20%,transparent)}
    \\.zw-tag button:active{scale:.85}
    \\.zw-tags{display:flex;flex-wrap:wrap;gap:6px}
    \\
;

pub const Props = struct {
    text: []const u8,
    /// Request sent by the × button; the tag is removed after it succeeds.
    remove: ?Z = null,
};

const src = "<span class=\"zw-tag\">{p.text}{#if p.remove}<button type=\"button\" aria-label=\"Remove {p.text}\" z-target=\"closest .zw-tag\" z-swap=\"delete\"{z}>×</button>{/if}</span>";

const Data = struct { p: Props, z: Z };

pub const Tag = zv.View(src, Data);

/// `tag(.{ .text = "zig" })`, `tag(.{ .text = "zig", .remove = .{ .delete = "/tags/zig" } })`.
/// Wrap several in `<div class="zw-tags">`.
pub fn tag(p: Props) Tag {
    var z = p.remove orelse Z{};
    z.target = null; // the markup targets the tag itself
    z.swap = null;
    return .{ .data = .{ .p = p, .z = z } };
}
