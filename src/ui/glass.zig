//! Liquid Glass: the shared material for the functional layer (HIG Materials). Components opt in
//! with classes in their markup:
//!   `zw-glass`        regular glass: tint, blur, specular rim, sheen, pointer light, lift.
//!                     glass.js gives each one a refraction lens shaped like its corners (Chromium).
//!   `zw-glass--clear` clear variant for glass over rich content.
//!   `zw-press`        inertia: grows on press, stretches toward the pointer, springs back.
//! Content (cards, lists, tables, prose) never uses glass. Reduce Transparency makes it opaque,
//! Increase Contrast gives it a solid edge, Reduce Motion removes the springs (see css.zig).
//! CSS only; it comes first in ui.css so components can refine it.

pub const css =
    \\.zw-glass{position:relative;isolation:isolate;background:var(--glass);-webkit-backdrop-filter:var(--glass-filter);backdrop-filter:var(--glass-filter);
    \\box-shadow:var(--glass-rim),var(--glass-shadow);transition:--zw-glow var(--speed)}
    \\.zw-refract .zw-glass{backdrop-filter:var(--zw-lens,) var(--glass-filter)}
    \\.zw-glass--clear{background:var(--glass-clear);--glass-filter:var(--glass-filter-clear)}
    \\.zw-glass::before{content:"";position:absolute;inset:0;z-index:-1;border-radius:inherit;pointer-events:none;
    \\background:radial-gradient(circle at var(--mx,50%) var(--my,-30%),color-mix(in srgb,var(--glass-glow) calc(var(--zw-glow) * 100%),transparent),transparent 70%),var(--glass-sheen)}
    \\.zw-press{transition:translate var(--dur-bouncy) var(--spring-bouncy),scale var(--dur-bouncy) var(--spring-bouncy),
    \\background-color var(--speed),box-shadow var(--speed),color var(--speed),--zw-glow var(--speed)}
    \\.zw-press:active,.zw-press[data-press]{translate:var(--dx,0) var(--dy,0);scale:calc(1.05 + var(--sx,0)) calc(1.05 + var(--sy,0));--zw-glow:1;
    \\transition-duration:var(--dur-snappy);transition-timing-function:var(--spring-snappy)}
    \\
;
