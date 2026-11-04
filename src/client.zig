//! The browser runtime (z.js) and the styles for the UI it creates. Served under /_zw/.
/// z.js (requests, swaps, islands) followed by glass.js (refraction, pointer light, inertia).
pub const js = @embedFile("client/z.js") ++ "\n" ++ @embedFile("client/glass.js");

pub const css =
    \\.zw-busy{opacity:.55;pointer-events:none;transition:opacity var(--speed)}
    \\.zw-enter{animation:zw-enter var(--dur-bouncy) var(--spring-bouncy) both}
    \\@keyframes zw-enter{from{opacity:0;translate:0 -10px;scale:.96}}
    \\.zw-leave{opacity:0;scale:.97;transition:height var(--dur) var(--spring),opacity 200ms ease,scale 300ms ease}
    \\.zw-dialog{margin:auto;border:0;border-radius:var(--radius-panel);padding:22px 20px 20px;width:280px;color:var(--label);text-align:center;--glass:var(--glass-thick);
    \\transition:opacity 180ms ease,scale var(--dur-bouncy) var(--spring-bouncy),display 250ms allow-discrete,overlay 250ms allow-discrete}
    \\@starting-style{.zw-dialog[open]{opacity:0;scale:.86}}
    \\.zw-dialog::backdrop{background:rgba(0,0,0,.2);transition:background-color 250ms}
    \\@starting-style{.zw-dialog[open]::backdrop{background:transparent}}
    \\.zw-dialog p{font:var(--headline);margin-bottom:18px}
    \\.zw-dialog .zw-row{display:grid;grid-template-columns:1fr 1fr}
    \\
;
