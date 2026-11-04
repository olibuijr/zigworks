//! Long-form text styles for `.zw-prose` (what `zw.markdown` renders). CSS only.
//! Only plain Markdown lists get list styles; component lists (`.zw-list`, the sidebar) keep theirs.
//! Reading text is a step up from the 13px control font, and lines stay under ~75 characters.

pub const css =
    \\.zw-prose{font:15px/1.6 var(--font);letter-spacing:-.15px;color:var(--label);max-width:72ch}
    \\.zw-prose>*+*{margin-top:14px}
    \\.zw-prose h1{font:700 30px/36px var(--font);letter-spacing:-.6px;margin-bottom:6px}
    \\.zw-prose h2{font:700 21px/28px var(--font);letter-spacing:-.4px;margin-top:36px;padding-top:4px}
    \\.zw-prose h3{font:600 16px/22px var(--font);letter-spacing:-.2px;margin-top:26px}
    \\.zw-prose h4{font:var(--headline);margin-top:20px}
    \\.zw-prose h2+*,.zw-prose h3+*,.zw-prose h4+*{margin-top:8px}
    \\.zw-prose :is(h2,h3,h4){scroll-margin-top:68px}
    \\.zw-prose :is(ul,ol):not([class]){padding-left:22px}
    \\.zw-prose :is(ul,ol):not([class])>li+li{margin-top:4px}
    \\.zw-prose :is(ul,ol):not([class])>li::marker{color:var(--tertiary)}
    \\.zw-prose :not(pre)>code{font:.86em var(--mono);padding:1px 5px;border-radius:5px;background:var(--fill)}
    \\.zw-prose a{text-decoration:underline;text-decoration-color:color-mix(in srgb,var(--accent) 35%,transparent);text-underline-offset:2px}
    \\.zw-prose a:hover{text-decoration-color:var(--accent)}
    \\.zw-prose hr{border:0;border-top:1px solid var(--separator);margin:28px 0}
    \\.zw-prose .zw-table{font-size:13px}
    \\.zw-prose>.zw-code,.zw-prose>.zw-demo{margin-top:16px}
    \\
;
