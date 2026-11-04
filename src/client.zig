//! The browser runtime (z.js) and the styles for the UI it creates. Served under /_zw/.
/// z.js (requests, swaps, islands) followed by glass.js (refraction, pointer light, inertia).
pub const js = @embedFile("client/z.js") ++ "\n" ++ @embedFile("client/glass.js");

pub const css =
    \\.zw-busy{opacity:.55;pointer-events:none;transition:opacity var(--speed)}
    \\.zw-enter{animation:zw-enter var(--dur-bouncy) var(--spring-bouncy) both}
    \\@keyframes zw-enter{from{opacity:0;translate:0 -10px;scale:.96}}
    \\@keyframes zw-pop{from{scale:.55}}
    \\.zw-js .zw-leave{opacity:0;scale:.96;overflow:clip;pointer-events:none;transition:height var(--dur) var(--spring),width var(--dur) var(--spring),margin var(--dur) var(--spring),padding var(--dur) var(--spring),opacity 200ms ease,scale 300ms ease,translate 300ms ease}
    \\.zw-swapped:not(.zw-check){animation:zw-swap 280ms ease}
    \\@keyframes zw-swap{from{opacity:.4}}
    \\.zw-flip{animation:zw-flip var(--dur-bouncy) var(--spring-bouncy)}
    \\@keyframes zw-flip{from{opacity:0;translate:0 5px;scale:.9}}
    \\.zw-dialog{margin:auto;border:0;border-radius:var(--radius-panel);padding:22px 20px 20px;width:280px;color:var(--label);text-align:center;--glass:var(--glass-thick);
    \\transition:opacity 180ms ease,scale var(--dur-bouncy) var(--spring-bouncy),display 250ms allow-discrete,overlay 250ms allow-discrete}
    \\@starting-style{.zw-dialog[open]{opacity:0;scale:.86}}
    \\.zw-dialog:not([open]){opacity:0;scale:.94;transition-duration:160ms;&::backdrop{background:transparent}}
    \\.zw-dialog::backdrop{background:rgba(0,0,0,.2);transition:background-color 250ms}
    \\@starting-style{.zw-dialog[open]::backdrop{background:transparent}}
    \\.zw-dialog p{font:var(--headline);margin-bottom:18px}
    \\.zw-dialog .zw-row{display:grid;grid-template-columns:1fr 1fr}
    \\
;
