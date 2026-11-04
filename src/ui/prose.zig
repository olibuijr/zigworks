//! Long-form text styles for `.zw-prose` (what `zw.markdown` renders). CSS only.
//! Only plain Markdown lists get list styles; component lists (`.zw-list`, the sidebar) keep theirs.
//! Put `zw-not-prose` on a wrapper to keep these styles out of components inside it (demos, cards):
//! `@scope ... to (.zw-not-prose)` stops at it. Rules nest under `:scope` so they keep a class worth
//! of specificity and still beat `.zw-prose>*+*` and component defaults.
//! Reading text is a step up from the 13px control font, and lines stay under ~75 characters.

pub const css =
    \\.zw-prose{font:15px/1.6 var(--font);letter-spacing:-.15px;color:var(--label);max-width:72ch;
    \\>*+*{margin-top:14px}
    \\:is(h2,h3,h4){scroll-margin-top:68px}
    \\.zw-table{font-size:13px}
    \\>:where(.zw-code,.zw-demo){margin-top:16px}}
    \\@scope (.zw-prose) to (.zw-not-prose){:scope{
    \\h1{font:700 30px/36px var(--font);letter-spacing:-.6px;margin-bottom:6px}
    \\h2{font:700 21px/28px var(--font);letter-spacing:-.4px;margin-top:36px;padding-top:4px}
    \\h3{font:600 16px/22px var(--font);letter-spacing:-.2px;margin-top:26px}
    \\h4{font:var(--headline);margin-top:20px}
    \\:is(h2,h3,h4)+*{margin-top:8px}
    \\:is(ul,ol):not([class]){padding-left:22px;
    \\>li+li{margin-top:4px}
    \\>li::marker{color:var(--tertiary)}}
    \\:not(pre)>code{font:.86em var(--mono);padding:1px 5px;border-radius:5px;background:var(--fill)}
    \\a{text-decoration:underline;text-decoration-color:color-mix(in srgb,var(--accent) 35%,transparent);text-underline-offset:2px;
    \\&:hover{text-decoration-color:var(--accent)}}
    \\hr{border:0;border-top:1px solid var(--separator);margin:28px 0}
    \\}}
    \\
;
