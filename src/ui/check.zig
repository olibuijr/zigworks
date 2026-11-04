//! Round completion check (Reminders style). Server-driven: wire `z` to flip state.
//! `tint` recolours it (Reminders list colours, flags), `size` scales it, `disabled` locks it.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-check{--zw-d:22px;--zw-tint:var(--accent);appearance:none;position:relative;flex:none;display:grid;place-items:center;width:var(--zw-d);height:var(--zw-d);padding:0;
    \\border:1.5px solid var(--tertiary);border-radius:50%;background:transparent;cursor:default;-webkit-tap-highlight-color:transparent;
    \\transition:background-color var(--speed),border-color var(--speed),box-shadow var(--speed),scale var(--dur-bouncy) var(--spring-bouncy);
    \\&:disabled{opacity:.4;pointer-events:none}
    \\&:not(:disabled){
    \\&:hover{border-color:var(--secondary)}
    \\&:active{scale:.8;transition-duration:var(--dur-snappy)}
    \\&:not([aria-checked=true]):hover{border-color:var(--zw-tint)}}
    \\&[aria-checked=true]{border-color:transparent;background:radial-gradient(circle at 50% 20%,color-mix(in srgb,var(--zw-tint) 70%,#fff),var(--zw-tint) 70%);
    \\box-shadow:inset 0 1px 0 rgba(255,255,255,.4),inset 0 -1px 1px rgba(0,0,0,.12),0 2px 6px color-mix(in srgb,var(--zw-tint) 35%,transparent);
    \\&::after{content:"";width:calc(var(--zw-d)*.23);height:calc(var(--zw-d)*.45);border:solid var(--on-accent);border-width:0 calc(var(--zw-d)*.09) calc(var(--zw-d)*.09) 0;rotate:45deg;translate:0 -1px}
    \\&.zw-swapped,.zw-swapped &{animation:zw-pop var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-swapped &::after{animation:zw-tick var(--dur) var(--spring-bouncy)}}}
    \\.zw-check--small{--zw-d:18px}
    \\.zw-check--large{--zw-d:28px}
    \\.zw-check--red{--zw-tint:var(--red)}
    \\.zw-check--orange{--zw-tint:var(--orange)}
    \\.zw-check--green{--zw-tint:var(--green)}
    \\@media (pointer:coarse){.zw-check::before{content:"";position:absolute;inset:calc((var(--zw-d) - 44px)/2)}}
    \\@keyframes zw-tick{from{scale:.2;opacity:0}}
    \\
;

pub const Size = enum { small, regular, large };
/// Fill colour when checked: the accent, or a system colour (Reminders list colours and flags).
pub const Tint = enum { accent, red, orange, green };

pub const Props = struct {
    on: bool,
    /// Accessible name, e.g. the item it completes.
    label: []const u8,
    /// 18px, 22px or 28px.
    size: Size = .regular,
    tint: Tint = .accent,
    /// Dimmed and not interactive.
    disabled: bool = false,
    z: Z = .{},
};

const src = "<button class=\"zw-check zw-check--{size} zw-check--{tint}\" type=\"button\" role=\"checkbox\" aria-checked=\"{on}\" aria-label=\"{label}\"{#if disabled} disabled{/if}{z}></button>";

pub const Check = zv.View(src, Props);

/// `check(.{ .on = todo.done, .label = todo.title, .tint = .orange, .size = .large })`
pub fn check(p: Props) Check {
    return .{ .data = p };
}

test "check renders tint, size and disabled" {
    var buf: [512]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try check(.{ .on = true, .label = "x", .tint = .red, .size = .small, .disabled = true }).render(&w);
    const s = w.buffered();
    try std.testing.expect(std.mem.find(u8, s, "zw-check--small zw-check--red") != null);
    try std.testing.expect(std.mem.find(u8, s, "aria-checked=\"true\"") != null);
    try std.testing.expect(std.mem.find(u8, s, " disabled") != null);
}
