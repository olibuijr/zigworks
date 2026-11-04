//! Client island: z.js imports the ES module at `src` and calls `export default function (el, props)`.
//! For three.js, charts, editors: anything that needs real JS. The module may return a cleanup function.
const zv = @import("../view.zig");

pub const css =
    \\.zw-island{position:relative;display:block;width:100%;border-radius:var(--radius);overflow:hidden;background:var(--content);box-shadow:var(--shadow)}
    \\.zw-island>canvas{display:block;width:100%;height:100%}
    \\.zw-card .zw-island{box-shadow:none;border-radius:calc(var(--radius) - 6px)}
    \\
;

pub const Props = struct {
    /// URL of the ES module, e.g. "/scene.js".
    src: []const u8,
    /// JSON passed to the module as `props`.
    props: []const u8 = "{}",
    /// CSS height, e.g. "360px" or "60vh".
    height: []const u8 = "360px",
    label: []const u8 = "Interactive content",
};

const src = "<div class=\"zw-island\" role=\"img\" aria-label=\"{label}\" style=\"height:{height}\" z-island=\"{src}\" data-props=\"{props}\"></div>";

pub const Island = zv.View(src, Props);

pub fn island(p: Props) Island {
    return .{ .data = p };
}
