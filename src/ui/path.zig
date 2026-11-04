//! Path bar: where you are, as links from the top level down (macOS path control, breadcrumbs).
//! The last item is the current page.
const zv = @import("../view.zig");

pub const css =
    \\.zw-path ol{display:flex;flex-wrap:wrap;align-items:center;gap:2px;list-style:none;margin:0;padding:0;font:var(--callout)}
    \\.zw-path li{display:inline-flex;align-items:center;gap:2px}
    \\.zw-path li+li::before{content:"";width:5px;height:5px;margin:0 6px 0 3px;border:solid var(--tertiary);border-width:1.5px 1.5px 0 0;rotate:45deg}
    \\.zw-path a{padding:2px 6px;border-radius:6px;color:var(--secondary);text-decoration:none;transition:background-color var(--speed),color var(--speed)}
    \\.zw-path a:hover{background:var(--fill);color:var(--label)}
    \\.zw-path [aria-current]{padding:2px 6px;color:var(--label);font-weight:600}
    \\
;

pub const Item = struct { label: []const u8, href: []const u8 = "" };

pub const Props = struct { items: []const Item, label: []const u8 = "Path" };

const src = "<nav class=\"zw-path\" aria-label=\"{p.label}\"><ol>{#each head as it}<li><a href=\"{it.href}\">{it.label}</a></li>{/each}" ++
    "{#each last as it}<li><span aria-current=\"page\">{it.label}</span></li>{/each}</ol></nav>";

const Data = struct { p: Props, head: []const Item, last: []const Item };

pub const Path = zv.View(src, Data);

/// `path(.{ .items = &.{ .{ .label = "Docs", .href = "/" }, .{ .label = "Button" } } })`
pub fn path(p: Props) Path {
    const n = p.items.len;
    return .{ .data = .{ .p = p, .head = p.items[0..n -| 1], .last = p.items[n -| 1..] } };
}
