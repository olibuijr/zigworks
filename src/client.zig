//! The browser runtime (z.js) and the styles for the UI it creates. Served under /_zw/.
pub const js = @embedFile("client/z.js");

pub const css =
    \\.zw-busy{opacity:.5;pointer-events:none;transition:opacity var(--speed)}
    \\.zw-enter{animation:zw-enter var(--speed) ease-out}
    \\@keyframes zw-enter{from{opacity:0;transform:translateY(-3px)}}
    \\.zw-dialog{margin:auto;border:1px solid var(--glass-edge);border-radius:16px;padding:20px;width:260px;color:var(--label);text-align:center;
    \\background:var(--glass);backdrop-filter:var(--material);-webkit-backdrop-filter:var(--material);box-shadow:0 0 0 .5px rgba(0,0,0,.2),0 20px 50px rgba(0,0,0,.3)}
    \\.zw-dialog::backdrop{background:rgba(0,0,0,.2)}
    \\.zw-dialog p{font:var(--headline);margin-bottom:16px}
    \\.zw-dialog .zw-row{display:grid;grid-template-columns:1fr 1fr}
    \\
;
