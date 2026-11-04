//! Progress: a determinate bar (`value` 0-100) or, with `value = null`, an indeterminate spinner.
const zv = @import("../view.zig");

pub const css =
    \\.zw-progress{display:block;width:100%;height:6px;border-radius:3px;background:var(--fill-strong);overflow:hidden}
    \\.zw-progress>span{display:block;height:100%;width:var(--v);border-radius:3px;background:var(--accent);transition:width var(--speed)}
    \\.zw-spinner{display:inline-block;width:16px;height:16px;border-radius:50%;border:2px solid var(--fill-strong);border-top-color:var(--secondary);animation:zw-spin .8s linear infinite;vertical-align:middle}
    \\@keyframes zw-spin{to{transform:rotate(360deg)}}
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
