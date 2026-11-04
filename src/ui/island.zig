//! Client island: z.js imports the ES module at `src` and calls `export default function (el, props)`.
//! For three.js, charts, editors: anything that needs real JS. The module may return a cleanup function.
//! Until the module draws something the island shows a shimmering placeholder; without JavaScript it
//! shows `fallback` text instead. If the module fails to load, z.js sets `data-error` on the island and
//! the `error` message replaces the placeholder.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-island{position:relative;display:block;width:100%;max-width:100%;border-radius:var(--radius);overflow:hidden;background:var(--content);box-shadow:var(--shadow);
    \\& > canvas{display:block;width:100%;height:100%}
    \\.zw-card &{box-shadow:none;border-radius:calc(var(--radius) - 6px)}}
    \\.zw-island-ph{display:none;position:absolute;inset:0;background:linear-gradient(90deg,var(--fill) 30%,var(--fill-strong) 50%,var(--fill) 70%) 0 0/300% 100%;animation:zw-shimmer 1.6s ease-in-out infinite}
    \\.zw-js .zw-island-ph{display:block}
    \\.zw-island:has(>:not(.zw-island-ph,.zw-island-err,noscript))>.zw-island-ph,.zw-island[data-error]>.zw-island-ph{display:none}
    \\.zw-island-err{display:none;position:absolute;inset:0;align-items:center;justify-content:center;padding:var(--space);text-align:center;color:var(--secondary);font:var(--body)}
    \\.zw-island[data-error]>.zw-island-err{display:flex}
    \\.zw-island-fallback{display:flex;align-items:center;justify-content:center;height:100%;padding:var(--space);text-align:center;color:var(--secondary);font:var(--body)}
    \\@media (forced-colors:active){.zw-island{box-shadow:none;border:1px solid CanvasText}.zw-island-ph{display:none!important}}
    \\
;

pub const Props = struct {
    /// URL of the ES module, e.g. "/scene.js".
    src: []const u8,
    /// JSON passed to the module as `props`.
    props: []const u8 = "{}",
    /// CSS height, e.g. "360px" or "60vh". Ignored when `aspect` is set.
    height: []const u8 = "360px",
    label: []const u8 = "Interactive content",
    /// CSS aspect ratio such as "16/9" or "4/3": the island scales with its width instead of
    /// having a fixed height, which suits phones.
    aspect: []const u8 = "",
    /// Show a shimmering placeholder until the module has drawn something.
    loading: bool = true,
    /// Text shown when JavaScript is off.
    fallback: []const u8 = "",
    /// Message shown in place of the placeholder when the module fails to load or throws.
    failed: []const u8 = "This content could not be loaded.",
};

const src = "<div class=\"zw-island\" role=\"group\" aria-label=\"{label}\" style=\"{#if aspect}aspect-ratio:{aspect}{:else}height:{height}{/if}\" z-island=\"{src}\" data-props=\"{props}\">" ++
    "{#if loading}<span class=\"zw-island-ph\" aria-hidden=\"true\"></span>{/if}" ++
    "<span class=\"zw-island-err\" role=\"alert\">{failed}</span>" ++
    "{#if fallback}<noscript><div class=\"zw-island-fallback\">{fallback}</div></noscript>{/if}</div>";

pub const Island = zv.View(src, Props);

pub fn island(p: Props) Island {
    return .{ .data = p };
}

test "aspect, placeholder and no-JS fallback" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try island(.{ .src = "/a.js", .aspect = "16/9", .fallback = "Needs JS", .loading = false }).render(&w);
    try std.testing.expectEqualStrings(
        "<div class=\"zw-island\" role=\"group\" aria-label=\"Interactive content\" style=\"aspect-ratio:16/9\" z-island=\"/a.js\" data-props=\"{}\">" ++
            "<span class=\"zw-island-err\" role=\"alert\">This content could not be loaded.</span>" ++
            "<noscript><div class=\"zw-island-fallback\">Needs JS</div></noscript></div>",
        w.buffered(),
    );
}

test "error message is always rendered, shown only once z.js marks the island" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try island(.{ .src = "/a.js", .failed = "Chart unavailable." }).render(&w);
    try std.testing.expect(std.mem.indexOf(u8, w.buffered(), "<span class=\"zw-island-ph\" aria-hidden=\"true\"></span><span class=\"zw-island-err\" role=\"alert\">Chart unavailable.</span>") != null);
    try std.testing.expect(std.mem.indexOf(u8, css, ".zw-island[data-error]>.zw-island-err{display:flex}") != null);
}
