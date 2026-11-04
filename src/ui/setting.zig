//! Settings row: label on the leading side, any control on the trailing side (macOS System Settings).
//! Consecutive rows (and switches, which share the style) get hairline separators.
const zv = @import("../view.zig");

pub const css =
    \\.zw-setting{display:flex;align-items:center;justify-content:space-between;gap:16px;min-height:36px}
    \\.zw-setting+.zw-setting{border-top:1px solid var(--separator);margin-top:6px;padding-top:6px}
    \\.zw-setting .zw-slider{flex:0 1 240px}
    \\
;

const src = "<div class=\"zw-setting\"><span>{label}</span>{control}</div>";

pub fn Props(comptime Control: type) type {
    return struct { label: []const u8, control: Control };
}

pub fn Setting(comptime Control: type) type {
    return zv.View(src, Props(Control));
}

/// `setting(.{ .label = "Theme", .control = ui.segmented(...) })`
pub fn setting(p: anytype) Setting(@FieldType(@TypeOf(p), "control")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "control")), p) };
}
