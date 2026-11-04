//! Round completion check (Reminders style). Server-driven: wire `z` to flip state.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-check{appearance:none;flex:none;width:22px;height:22px;border-radius:50%;border:1.5px solid var(--tertiary);background:transparent;cursor:default;padding:0;
    \\display:grid;place-items:center;-webkit-tap-highlight-color:transparent;
    \\transition:background-color var(--speed),border-color var(--speed),box-shadow var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-check:hover{border-color:var(--secondary)}
    \\.zw-check:active{scale:.8;transition-duration:var(--dur-snappy)}
    \\.zw-check[aria-checked=true]{border-color:transparent;background:radial-gradient(circle at 50% 20%,color-mix(in srgb,var(--accent) 70%,#fff),var(--accent) 70%);
    \\box-shadow:inset 0 1px 0 rgba(255,255,255,.4),inset 0 -1px 1px rgba(0,0,0,.12),0 2px 6px color-mix(in srgb,var(--accent) 35%,transparent)}
    \\.zw-check[aria-checked=true]::after{content:"";width:5px;height:10px;border:solid var(--on-accent);border-width:0 2px 2px 0;rotate:45deg;translate:0 -1px}
    \\.zw-swapped .zw-check[aria-checked=true],.zw-check.zw-swapped[aria-checked=true]{animation:zw-pop var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-swapped .zw-check[aria-checked=true]::after{animation:zw-tick var(--dur) var(--spring-bouncy)}
    \\@keyframes zw-pop{from{scale:.55}}
    \\@keyframes zw-tick{from{scale:.2;opacity:0}}
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
