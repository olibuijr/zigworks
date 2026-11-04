//! Search field with live results: typing sends `GET action?q=...` (debounced) and swaps the
//! response into a results panel under the field. It sits inside the blurred title bar, where a
//! nested backdrop-filter blurs nothing, so the panel is opaque instead of glass. Without JS it is a normal GET form.
const zv = @import("../view.zig");

pub const css =
    \\.zw-search{position:relative;flex:0 1 240px;min-width:0}
    \\.zw-search input{appearance:none;width:100%;height:28px;padding:0 10px 0 28px;border:0;border-radius:var(--radius-control);font:var(--body);color:var(--label);
    \\background:var(--fill) no-repeat 9px 50%/12px url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='%23888' stroke-width='2'%3E%3Ccircle cx='7' cy='7' r='5'/%3E%3Cpath d='m11 11 4 4'/%3E%3C/svg%3E");outline:none}
    \\.zw-search input:focus{box-shadow:0 0 0 3.5px color-mix(in srgb,var(--accent) 45%,transparent)}
    \\.zw-search input::placeholder{color:var(--secondary)}
    \\.zw-search input::-webkit-search-cancel-button{appearance:none}
    \\.zw-results{position:absolute;top:calc(100% + 6px);right:0;width:min(360px,calc(100vw - 32px));max-height:60vh;overflow:auto;z-index:20;padding:5px;border-radius:var(--radius);
    \\background:var(--window);box-shadow:inset 0 0 0 .5px var(--glass-edge),0 0 0 .5px rgba(0,0,0,.15),0 10px 30px rgba(0,0,0,.18)}
    \\.zw-results:empty{display:none}
    \\.zw-search:not(:focus-within) .zw-results{display:none}
    \\.zw-results a{display:block;padding:6px 10px;border-radius:6px;color:var(--label);text-decoration:none}
    \\.zw-results a:hover,.zw-results a:focus-visible{background:var(--accent);color:var(--on-accent);outline:none}
    \\.zw-results a small{display:block;font:var(--callout);color:var(--secondary)}
    \\.zw-results a:hover small,.zw-results a:focus-visible small{color:inherit;opacity:.8}
    \\.zw-results p{padding:10px;color:var(--secondary);font:var(--callout)}
    \\
;

pub const Props = struct {
    /// GET endpoint returning result markup (links). Receives `q`.
    action: []const u8,
    label: []const u8 = "Search",
    placeholder: []const u8 = "Search",
    /// Must be a valid HTML id.
    id: []const u8 = "zw-results",
};

const src = "<form class=\"zw-search\" role=\"search\" action=\"{action}\" method=\"get\"><input type=\"search\" name=\"q\" aria-label=\"{label}\" placeholder=\"{placeholder}\" autocomplete=\"off\"" ++
    " z-get=\"{action}\" z-trigger=\"input\" z-target=\"#{id}\"><div class=\"zw-results\" id=\"{id}\" aria-live=\"polite\"></div></form>";

pub const Search = zv.View(src, Props);

pub fn search(p: Props) Search {
    return .{ .data = p };
}
