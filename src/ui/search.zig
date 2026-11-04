//! Search field with live results: typing sends `GET action?q=...` (debounced) and swaps the
//! response into a results panel under the field. It sits inside the blurred title bar, where a
//! nested backdrop-filter blurs nothing, so the panel is opaque instead of glass. Without JS it is a normal GET form.
//! The clear button is the browser's own `type=search` one, restyled (field.zig); Firefox has none.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-search{position:relative;flex:0 1 240px;min-width:0}
    \\.zw-search input{appearance:none;width:100%;height:30px;padding:0 12px 0 30px;border:0;border-radius:999px;font:var(--body);color:var(--label);outline:none;
    \\background:var(--glass) no-repeat 11px 50%/12px url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='%23888' stroke-width='2'%3E%3Ccircle cx='7' cy='7' r='5'/%3E%3Cpath d='m11 11 4 4'/%3E%3C/svg%3E");
    \\transition:box-shadow var(--speed)}
    \\.zw-search input:focus{box-shadow:var(--glass-rim),0 0 0 3.5px color-mix(in srgb,var(--accent) 45%,transparent)}
    \\.zw-search input::placeholder{color:var(--secondary)}
    \\.zw-search--small input{height:24px;font:var(--callout);padding-left:27px;background-position:9px 50%;background-size:10px}
    \\.zw-search--large input{height:36px;padding-left:34px;background-position:13px 50%;background-size:14px}
    \\.zw-search--noclear input::-webkit-search-cancel-button{display:none}
    \\.zw-search--hint input{padding-right:44px}
    \\.zw-search-hint{position:absolute;right:11px;top:50%;translate:0 -50%;font:var(--callout);color:var(--secondary);text-transform:uppercase;pointer-events:none;
    \\transition:opacity var(--speed)}
    \\.zw-search input:focus~.zw-search-hint,.zw-search input:not(:placeholder-shown)~.zw-search-hint{opacity:0}
    \\.zw-results{position:absolute;top:calc(100% + 8px);right:0;width:min(360px,calc(100vw - 32px));max-height:60vh;overflow:auto;z-index:20;padding:6px;border-radius:var(--radius);
    \\--glass:var(--glass-thick);transform-origin:top right;
    \\transition:opacity 180ms ease,scale var(--dur-bouncy) var(--spring-bouncy),translate var(--dur) var(--spring),display 250ms allow-discrete}
    \\@starting-style{.zw-results{opacity:0;scale:.9;translate:0 -8px}}
    \\.zw-results:empty,.zw-search:not(:focus-within) .zw-results{display:none;opacity:0}
    \\.zw-results a{display:block;padding:7px 10px;border-radius:8px;color:var(--label);text-decoration:none}
    \\.zw-results a:hover,.zw-results a:focus-visible{background:var(--accent);color:var(--on-accent);outline:none;text-decoration:none}
    \\.zw-results a small{display:block;font:var(--callout);color:var(--secondary)}
    \\.zw-results a:hover small,.zw-results a:focus-visible small{color:inherit;opacity:.8}
    \\.zw-results p{padding:10px;color:var(--secondary);font:var(--callout)}
    \\@media (pointer:coarse){.zw-search input,.zw-search--small input,.zw-search--large input{height:44px;padding-left:34px;background-position:13px 50%;background-size:14px}
    \\.zw-results a{min-height:44px;display:flex;flex-direction:column;justify-content:center}}
    \\@media (forced-colors:active){.zw-search input{border:1px solid ButtonText}.zw-search input:focus{outline:2px solid Highlight}}
    \\
;

pub const Size = enum { small, regular, large };

pub const Props = struct {
    /// GET endpoint returning result markup (links). Receives the query as `name`.
    action: []const u8,
    label: []const u8 = "Search",
    placeholder: []const u8 = "Search",
    /// Must be a valid HTML id.
    id: []const u8 = "zw-results",
    /// Query parameter name.
    name: []const u8 = "q",
    /// Initial query, for example on a results page.
    value: []const u8 = "",
    /// Height: small 24px, regular 30px, large 36px (44px on touch screens).
    size: Size = .regular,
    /// Show the clear button once there is text.
    clear: bool = true,
    /// Key that focuses the field, shown as a hint (`⌘K`) while the field is empty and unfocused.
    /// Announced through `aria-keyshortcuts`; z.js binds it (`data-shortcut`). Needs a non-empty `placeholder`.
    shortcut: []const u8 = "",
    /// Shortest query the form submits without JS (native `minlength`). 0 means no minimum.
    min_length: u8 = 0,
    autofocus: bool = false,
};

const src = "<form class=\"zw-search zw-search--{p.size}{#if !p.clear} zw-search--noclear{/if}{#if p.shortcut} zw-search--hint{/if}\" role=\"search\" action=\"{p.action}\" method=\"get\">" ++
    "<input class=\"zw-glass\" type=\"search\" name=\"{p.name}\" value=\"{p.value}\" aria-label=\"{p.label}\" placeholder=\"{p.placeholder}\" autocomplete=\"off\" enterkeyhint=\"search\" aria-controls=\"{p.id}\"" ++
    "{#if p.min_length} minlength=\"{p.min_length}\"{/if}{#if p.autofocus} autofocus{/if}" ++
    "{#if p.shortcut} aria-keyshortcuts=\"Meta+{p.shortcut} Control+{p.shortcut}\" data-shortcut=\"{p.shortcut}\"{/if}" ++
    " z-get=\"{p.action}\" z-trigger=\"input\" z-target=\"#{p.id}\">" ++
    "{#if p.shortcut}<kbd class=\"zw-search-hint\" aria-hidden=\"true\">&#8984;{p.shortcut}</kbd>{/if}" ++
    "<div class=\"zw-results zw-glass\" id=\"{p.id}\" aria-live=\"polite\"></div></form>";

const Data = struct { p: Props };

pub const Search = zv.View(src, Data);

pub fn search(p: Props) Search {
    return .{ .data = .{ .p = p } };
}

test "defaults render the original markup plus the new attributes" {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try search(.{ .action = "/s" }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "class=\"zw-search zw-search--regular\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "name=\"q\" value=\"\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "z-get=\"/s\" z-trigger=\"input\" z-target=\"#zw-results\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "zw-search-hint") == null);
    try std.testing.expect(std.mem.find(u8, out, "minlength") == null);
}

test "variants" {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try search(.{ .action = "/s", .size = .large, .clear = false, .shortcut = "k", .min_length = 2, .value = "a\"b" }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "zw-search--large zw-search--noclear zw-search--hint") != null);
    try std.testing.expect(std.mem.find(u8, out, "minlength=\"2\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-keyshortcuts=\"Meta+k Control+k\" data-shortcut=\"k\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "value=\"a&quot;b\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "<kbd class=\"zw-search-hint\" aria-hidden=\"true\">&#8984;k</kbd>") != null);
}
