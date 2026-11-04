//! Progress: a determinate bar (`value` 0-100) or, with `value = null`, an indeterminate spinner.
const zv = @import("../view.zig");

pub const css =
    \\.zw-progress{display:block;width:100%;height:6px;border-radius:3px;background:var(--fill-strong);box-shadow:inset 0 .5px 1px rgba(0,0,0,.1);overflow:hidden}
    \\.zw-progress>span{display:block;height:100%;width:var(--v);border-radius:3px;background:linear-gradient(color-mix(in srgb,var(--accent) 75%,#fff),var(--accent));
    \\box-shadow:inset 0 .5px 0 rgba(255,255,255,.45);transition:width var(--dur) var(--spring)}
    \\.zw-spinner{display:inline-block;width:16px;height:16px;border-radius:50%;vertical-align:middle;animation:zw-spin .9s linear infinite;
    \\background:conic-gradient(from 0deg,transparent 10%,var(--secondary));mask:radial-gradient(farthest-side,transparent calc(100% - 2.5px),#000 calc(100% - 2px))}
    \\@keyframes zw-spin{to{rotate:360deg}}
    \\
;

pub const Props = struct {
    /// Percent 0-100, or null for an indeterminate spinner.
    value: ?u8,
    label: []const u8,
};

const src = "{#if value}<span class=\"zw-progress\" role=\"progressbar\" aria-label=\"{label}\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"{value}\" style=\"--v:{value}%\"><span></span></span>" ++
    "{:else}<span class=\"zw-spinner\" role=\"status\" aria-label=\"{label}\"></span>{/if}";

pub const Progress = zv.View(src, Props);

pub fn progress(p: Props) Progress {
    return .{ .data = p };
}
