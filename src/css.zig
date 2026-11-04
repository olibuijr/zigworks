//! Design tokens -> CSS custom properties, built at comptime and served at /_zw/zw.css.
//! Defaults follow the macOS HIG: semantic system colors, the macOS text styles, and Liquid Glass on the
//! functional layer only (bars, sidebars, menus, sheets, controls); content stays opaque.
//! Every field becomes `--name` (underscores -> dashes). Palette fields switch with the OS appearance.
//! Component styles live next to each component (src/ui/*.zig) and are appended after the base.
const std = @import("std");

/// macOS semantic colors (names follow AppKit: windowBackgroundColor, labelColor, separatorColor...).
pub const Palette = struct {
    window: []const u8,
    content: []const u8,
    control: []const u8,
    /// Liquid Glass, regular variant: controls (buttons, fields, pills).
    glass: []const u8,
    /// Regular glass for text-heavy panels (menus, sheets, sidebars, dialogs): more opaque.
    glass_thick: []const u8,
    /// Clear variant: pressed knobs and lenses over rich content.
    glass_clear: []const u8,
    glass_edge: []const u8,
    /// Specular rim: inset highlights that give glass its edge.
    glass_rim: []const u8,
    /// Lift: the shadow under floating glass.
    glass_shadow: []const u8,
    /// Static sheen across the upper half of glass.
    glass_sheen: []const u8,
    /// Highlight that follows the pointer.
    glass_glow: []const u8,
    /// Switch and slider knobs at rest.
    knob: []const u8,
    label: []const u8,
    secondary: []const u8,
    tertiary: []const u8,
    separator: []const u8,
    /// Subtle fill for tracks, hovers, segmented background.
    fill: []const u8,
    fill_strong: []const u8,
    /// Selected segment / raised control surface.
    control_raised: []const u8,
    accent: []const u8,
    on_accent: []const u8,
    red: []const u8,
    green: []const u8,
    orange: []const u8,
    shadow: []const u8,
    /// Code blocks and syntax colors (Xcode default themes).
    code_bg: []const u8,
    tok_keyword: []const u8,
    tok_string: []const u8,
    tok_number: []const u8,
    tok_comment: []const u8,
    tok_type: []const u8,
    tok_fn: []const u8,
};

pub const light: Palette = .{
    .window = "#ececec",
    .content = "#ffffff",
    .control = "#ffffff",
    .glass = "rgba(255,255,255,.52)",
    .glass_thick = "rgba(248,248,250,.78)",
    .glass_clear = "rgba(255,255,255,.12)",
    .glass_edge = "rgba(255,255,255,.6)",
    .glass_rim = "inset 0 1px 0 rgba(255,255,255,.9), inset 0 -1px 0 rgba(255,255,255,.35), inset 0 0 0 .5px rgba(255,255,255,.6), inset 0 0 14px rgba(255,255,255,.25)",
    .glass_shadow = "0 0 0 .5px rgba(0,0,0,.09), 0 1px 2px rgba(0,0,0,.06), 0 6px 18px rgba(0,0,0,.08)",
    .glass_sheen = "linear-gradient(180deg, rgba(255,255,255,.45), rgba(255,255,255,.08) 48%, rgba(255,255,255,0) 52%)",
    .glass_glow = "rgba(255,255,255,.75)",
    .knob = "#ffffff",
    .label = "rgba(0,0,0,.85)",
    .secondary = "rgba(0,0,0,.5)",
    .tertiary = "rgba(0,0,0,.26)",
    .separator = "rgba(0,0,0,.1)",
    .fill = "rgba(0,0,0,.05)",
    .fill_strong = "rgba(0,0,0,.1)",
    .control_raised = "#ffffff",
    .accent = "#007aff",
    .on_accent = "#ffffff",
    .red = "#ff3b30",
    .green = "#28cd41",
    .orange = "#ff9500",
    .shadow = "0 0 0 .5px rgba(0,0,0,.08), 0 1px 3px rgba(0,0,0,.08)",
    .code_bg = "#f7f7f8",
    .tok_keyword = "#9b2393",
    .tok_string = "#c41a16",
    .tok_number = "#1c00cf",
    .tok_comment = "#5d6c79",
    .tok_type = "#0b4f79",
    .tok_fn = "#326d74",
};

pub const dark: Palette = .{
    .window = "#1e1e1e",
    .content = "#282828",
    .control = "rgba(255,255,255,.1)",
    .glass = "rgba(58,58,62,.5)",
    .glass_thick = "rgba(40,40,44,.78)",
    .glass_clear = "rgba(255,255,255,.06)",
    .glass_edge = "rgba(255,255,255,.1)",
    .glass_rim = "inset 0 1px 0 rgba(255,255,255,.24), inset 0 -1px 0 rgba(255,255,255,.07), inset 0 0 0 .5px rgba(255,255,255,.14), inset 0 0 14px rgba(255,255,255,.05)",
    .glass_shadow = "0 0 0 .5px rgba(0,0,0,.55), 0 1px 2px rgba(0,0,0,.3), 0 8px 24px rgba(0,0,0,.35)",
    .glass_sheen = "linear-gradient(180deg, rgba(255,255,255,.12), rgba(255,255,255,.02) 48%, rgba(255,255,255,0) 52%)",
    .glass_glow = "rgba(255,255,255,.22)",
    .knob = "#ffffff",
    .label = "rgba(255,255,255,.85)",
    .secondary = "rgba(255,255,255,.55)",
    .tertiary = "rgba(255,255,255,.25)",
    .separator = "rgba(255,255,255,.1)",
    .fill = "rgba(255,255,255,.08)",
    .fill_strong = "rgba(255,255,255,.16)",
    .control_raised = "#636366",
    .accent = "#0a84ff",
    .on_accent = "#ffffff",
    .red = "#ff453a",
    .green = "#32d74b",
    .orange = "#ff9f0a",
    .shadow = "0 0 0 .5px rgba(0,0,0,.6), 0 1px 3px rgba(0,0,0,.4)",
    .code_bg = "#1f1f22",
    .tok_keyword = "#fc5fa3",
    .tok_string = "#fc6a5d",
    .tok_number = "#d0bf69",
    .tok_comment = "#7f8c98",
    .tok_type = "#5dd8ff",
    .tok_fn = "#67b7a4",
};

pub const Tokens = struct {
    font: []const u8 = "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"Inter\", \"Segoe UI\", system-ui, sans-serif",
    mono: []const u8 = "ui-monospace, \"SF Mono\", Menlo, \"JetBrains Mono\", monospace",
    // macOS text styles: weight size/line-height (HIG Typography, macOS built-in text styles).
    large_title: []const u8 = "400 26px/32px var(--font)",
    title1: []const u8 = "400 22px/26px var(--font)",
    title2: []const u8 = "400 17px/22px var(--font)",
    title3: []const u8 = "400 15px/20px var(--font)",
    headline: []const u8 = "700 13px/16px var(--font)",
    body: []const u8 = "400 13px/16px var(--font)",
    callout: []const u8 = "400 12px/15px var(--font)",
    footnote: []const u8 = "400 10px/13px var(--font)",
    control_h: []const u8 = "28px",
    /// Concentric corners: content groups, controls, floating panels; capsules use 999px.
    radius: []const u8 = "14px",
    radius_control: []const u8 = "8px",
    radius_panel: []const u8 = "20px",
    space: []const u8 = "16px",
    /// backdrop-filter of regular and clear glass. Chromium adds a refraction lens in front (glass.js).
    glass_filter: []const u8 = "blur(14px) saturate(190%) brightness(1.03)",
    glass_filter_clear: []const u8 = "blur(1.5px) saturate(170%) brightness(1.08)",
    /// Color and opacity fades.
    speed: []const u8 = "160ms",
    // Springs as linear() curves (stiffness/damping, generated): `spring` settles with ~2% overshoot
    // (panels, menus), `spring_bouncy` overshoots ~20% (knobs, pills, pops: the water-drop feel),
    // `spring_snappy` follows input (~1.5%). Pair each with its duration.
    spring: []const u8 = "linear(0,0.019,0.068,0.137,0.218,0.305,0.394,0.48,0.562,0.638,0.706,0.766,0.818,0.863,0.901,0.932,0.957,0.977,0.992,1.004,1.012,1.018,1.021,1.023,1.023,1.023,1.022,1.02,1.018,1.016,1.014,1.012,1.01,1.008,1.007,1.005,1.004,1.003,1.002,1.002,1)",
    spring_bouncy: []const u8 = "linear(0,0.064,0.223,0.429,0.644,0.84,0.998,1.111,1.177,1.203,1.196,1.168,1.128,1.084,1.042,1.008,0.982,0.967,0.959,0.959,0.964,0.972,0.981,0.989,0.997,1.002,1.006,1.008,1.008,1.008,1.006,1.004,1.003,1.001,1,0.999,0.998,0.998,0.998,0.999,1)",
    spring_snappy: []const u8 = "linear(0,0.02,0.072,0.144,0.227,0.316,0.406,0.492,0.573,0.646,0.712,0.77,0.82,0.863,0.898,0.927,0.951,0.969,0.984,0.995,1.003,1.008,1.012,1.014,1.015,1.015,1.015,1.014,1.013,1.011,1.01,1.009,1.007,1.006,1.005,1.004,1.003,1.003,1.002,1.001,1)",
    dur: []const u8 = "520ms",
    dur_bouncy: []const u8 = "680ms",
    dur_snappy: []const u8 = "320ms",
    width: []const u8 = "680px",
    light: Palette = light,
    dark: Palette = dark,
};

/// The full stylesheet: tokens + base + client runtime + every component's CSS.
pub fn build(comptime t: Tokens) []const u8 {
    comptime {
        var root: []const u8 = "";
        const info = @typeInfo(Tokens).@"struct";
        for (info.field_names, info.field_types) |name, T| {
            if (T == Palette) continue;
            root = root ++ decl(name, @field(t, name));
        }
        return ":root{color-scheme:light dark;" ++ root ++ vars(t.light) ++ "}" ++
            "@media (prefers-color-scheme:dark){:root{" ++ vars(t.dark) ++ "}}" ++
            base ++ @import("client.zig").css ++ @import("ui.zig").css;
    }
}

fn vars(comptime p: Palette) []const u8 {
    var out: []const u8 = "";
    for (@typeInfo(Palette).@"struct".field_names) |name| out = out ++ decl(name, @field(p, name));
    return out;
}

fn decl(comptime name: []const u8, comptime value: []const u8) []const u8 {
    var n: [name.len]u8 = name[0..name.len].*;
    std.mem.replaceScalar(u8, &n, '_', '-');
    const final = n;
    return "--" ++ final ++ ":" ++ value ++ ";";
}

// Touch screens (pointer:coarse): text fields use at least 16px text, so iOS never zooms into
// them on focus (it zooms below 16px; turning page zoom off instead would hurt accessibility),
// and controls get taller for fingers.
const base =
    \\*,*::before,*::after{box-sizing:border-box;margin:0}
    \\html{-webkit-text-size-adjust:100%;scrollbar-width:thin;scrollbar-color:var(--tertiary) transparent}
    \\body{min-height:100vh;font:var(--body);letter-spacing:-.08px;color:var(--label);background:var(--window);-webkit-font-smoothing:antialiased}
    \\::-webkit-scrollbar{width:11px;height:11px}::-webkit-scrollbar-thumb{background:var(--tertiary);border-radius:11px;border:3px solid transparent;background-clip:content-box}
    \\::selection{background:color-mix(in srgb,var(--accent) 30%,transparent)}
    \\h1{font:var(--large-title);letter-spacing:.22px}h2{font:var(--title2);font-weight:700;letter-spacing:-.43px}h3{font:var(--title3);font-weight:600;letter-spacing:-.23px}
    \\a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}
    \\:focus-visible{outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent);outline-offset:1px}
    \\code{font-family:var(--mono);font-size:12px}
    \\.zw-stack{display:flex;flex-direction:column;gap:var(--space)}
    \\.zw-row{display:flex;align-items:center;gap:8px}
    \\.zw-grow{flex:1;min-width:0}
    \\.zw-secondary{color:var(--secondary)}
    \\.zw-callout{font:var(--callout)}
    \\@media (pointer:coarse){:root{--control-h:34px}input:not([type=checkbox],[type=radio],[type=range]),textarea,select{font-size:max(16px,1em)!important}}
    \\@property --zw-glow{syntax:"<number>";inherits:true;initial-value:0}
    \\@supports not (transition-timing-function:linear(0,1)){:root{--spring:cubic-bezier(.25,1.1,.4,1);--spring-bouncy:cubic-bezier(.3,1.5,.5,1);--spring-snappy:cubic-bezier(.2,1,.3,1)}}
    \\@media (prefers-reduced-motion:reduce){*,*::before,*::after{transition:none!important;animation:none!important}}
    \\@media (prefers-contrast:more){:root{--separator:var(--secondary);--glass:var(--content);--glass-thick:var(--content);--glass-rim:inset 0 0 0 1px var(--secondary)}}
    \\@media (prefers-reduced-transparency:reduce){:root{--glass:var(--content);--glass-thick:var(--content);--glass-clear:var(--content);--glass-filter:none;--glass-filter-clear:none;--glass-sheen:none}}
    \\
;

test "tokens become css variables" {
    const s = comptime build(.{ .radius = "4px" });
    try std.testing.expect(std.mem.find(u8, s, "--radius:4px;") != null);
    try std.testing.expect(std.mem.find(u8, s, "--on-accent:#ffffff;") != null);
    try std.testing.expect(std.mem.find(u8, s, "--radius-control:8px;") != null);
    try std.testing.expect(std.mem.find(u8, s, "--spring-bouncy:linear(") != null);
}

test "README token override compiles" {
    const t: Tokens = comptime .{ .radius = "12px", .light = blk: {
        var p = light;
        p.accent = "#5e5ce6";
        break :blk p;
    } };
    const s = comptime build(t);
    try std.testing.expect(std.mem.find(u8, s, "--accent:#5e5ce6;") != null);
}
