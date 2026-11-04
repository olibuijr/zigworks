//! Round completion check (Reminders style). Server-driven: wire `z` to flip state.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-check{appearance:none;flex:none;width:20px;height:20px;border-radius:50%;border:1.5px solid var(--tertiary);background:transparent;cursor:default;
    \\display:grid;place-items:center;padding:0;transition:background var(--speed),border-color var(--speed),transform var(--speed)}
    \\.zw-check:hover{border-color:var(--secondary)}
    \\.zw-check:active{transform:scale(.88)}
    \\.zw-check[aria-checked=true]{background:var(--accent);border-color:var(--accent)}
    \\.zw-check[aria-checked=true]::after{content:"";width:5px;height:9px;border:solid var(--on-accent);border-width:0 1.75px 1.75px 0;transform:translateY(-1px) rotate(45deg)}
    \\
;

pub const Props = struct {
    on: bool,
    /// Accessible name, e.g. the item it completes.
    label: []const u8,
    z: Z = .{},
};

const src = "<button class=\"zw-check\" type=\"button\" role=\"checkbox\" aria-checked=\"{on}\" aria-label=\"{label}\"{z}></button>";

pub const Check = zv.View(src, Props);

pub fn check(p: Props) Check {
    return .{ .data = p };
}
